Gem::Specification.new do |s|
  s.name        = "rails2lb4"
  s.version     = "0.0.1"
  s.licenses    = ['MIT']
  s.authors     = ["Sam Ruby"]
  s.email       = ["rubys@intertwingly.net"]
  s.homepage    = "http://github.com/rubys/rails2lb4"
  s.summary     = "Convert Rails model to loopback4"
  s.description = "Builds a loopback4 datasource, model, and repository " +
    "from Rails schema.rb, database.yml, and model sources"
  s.add_runtime_dependency 'ansi'
  s.add_runtime_dependency 'erubis'
  s.files        = Dir.glob("{bin,lib,templates}/**/*") + %w(LICENSE README.md)
  s.executables  = ['rails2lb4']
end
