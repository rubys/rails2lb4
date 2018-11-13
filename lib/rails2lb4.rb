require 'erubis'
require 'ansi'
require 'yaml'
require 'json'

require 'active_support/core_ext/string'
require 'active_support/inflector'

def rails2lb4(source, target)
  # import custom pluralization
  if File.exist? "#{source}/config/initializers/inflections.rb"
    require "#{source}/config/initializers/inflections.rb"
  end

  # define a write operation that colorizes output and determines if the
  # output represent new content or a change.
  def target.write path, contents
    dest = File.join(self, path)
    if File.size?(dest) and IO.read(dest) == contents
      puts ANSI.blue { 'skipping ' } + path
    else
      if File.size?(dest)
	puts ANSI.bold { ANSI.magenta { 'updating ' } } + path
      else
	puts ANSI.bold { ANSI.green { 'creating ' } } + path
      end
      IO.write dest, contents
    end
  end

  # determine the database type from the configuration
  environment = ENV['RAILS_ENV'] || 'development'
  database = YAML.load_file("#{source}/config/database.yml")
  @adapter = database[environment]['adapter']

  # common configuration
  config = {
    name: @adapter,
    connector: "loopback-connector-#{@adapter}"
  }

  # database specific configuration
  if @adapter == 'sqlite3'
    config[:file] = File.expand_path(database[environment]['database'], source)

    Dir.chdir target do
      unless IO.read('package.json').include? 'loopback-connector-sqlite3'
	system 'npm install loopback-connector-sqlite3 --save'
      end
    end

  elsif @adapter == 'mysql' or @adapter == 'postgresql'
    environment = database[environment]
    %w(database host password.port username).each do |property|
      config[property] = environment[property] if environment[property]
    end

    if @adapter == 'mysql'
      config[:socketPath] = environtment[:socket] if environment[:socket]
      config[:connectionLimit] = environtment[:pool] if environment[:pool]
    end
  end

  # produce datasource.ts
  template = File.read(File.join(__dir__, '../templates/datasource.erb'))
  datasource = Erubis::Eruby.new(template).result(binding)
  path = File.join('src', 'datasources', "#{@adapter}.datasource.ts")
  target.write path, datasource

  # produce datasource.json
  path = File.join('src', 'datasources', "#{@adapter}.datasource.json")
  target.write path, JSON.pretty_generate(config)

  # produce datasource/index.ts
  index = Dir["#{target}/src/datasources/*.datasource.ts"].sort.
    map {|file| "export * from './#{File.basename(file, '.ts')}';"}.
    join("\n") + "\n"
  target.write 'src/datasources/index.ts', index

  # parse schema.rb from the source
  schema = IO.read("#{source}/db/schema.rb")
  table = /^\s+create_table "([^"]+)",.*?\n(.*?)\n\s+end/m

  data_types = {
    "integer" => "number",
    "float" => "number",
    "text" => "string",
    "boolean" => "boolean",
    "date" => "Date",
    "datetime" => "Date",
  }

  tables = {}
  schema.scan(table).each do |name, ddl|
    cols = ddl.scan(/^\s+t\.(\w+)\s+"(\w+)/).
      map {|names| [names.last, data_types[names.first] || names.first]}.to_h
    tables[name] = cols
  end

  # produce model.ts and repository.ts for each model
  Dir["#{source}/app/models/*.rb"].sort.each do |file|
    model = File.read(file)
    basename = File.basename(file, '.rb')
    @table = tables[basename.pluralize] || {}
    @class_name = model[/class (\w+)/, 1]
    @table_name = @class_name.downcase.pluralize

    @belongs_to = model.scan(/^\s+belongs_to\s*:(\w+)/).
      map {|(name)| [name, name.camelcase]}.to_h
    @has_many = model.scan(/^\s+has_many\s*:(\w+)/).
      map {|(name)| [name.singularize, name.singularize.camelcase]}.to_h

    template = File.read(File.join(__dir__, '../templates/model.erb'))
    model = Erubis::Eruby.new(template).result(binding)

    path = File.join('src', 'models', basename+'.model.ts')
    target.write path, model

    template = File.read(File.join(__dir__, '../templates/repository.erb'))
    repository = Erubis::Eruby.new(template).result(binding)

    path = File.join('src', 'repositories', basename+'.repository.ts')
    target.write path, repository
  end

  # produce model.index.ts
  index = Dir["#{target}/src/models/*.model.ts"].sort.
    map {|file| "export * from './#{File.basename(file, '.ts')}';"}.
    join("\n") + "\n"
  target.write 'src/models/index.ts', index

  # produce repositories.index.ts
  index = Dir["#{target}/src/repositories/*.repository.ts"].sort.
    map {|file| "export * from './#{File.basename(file, '.ts')}';"}.
    join("\n") + "\n"
  target.write 'src/repositories/index.ts', index
end
