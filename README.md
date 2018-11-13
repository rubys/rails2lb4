**Warning**: this application is only demo quality at the moment.  Do not use on
an existing loopback4 appication is not under version control where all of the
changes have already been committed as this application may overwrite files.

This tool will create a loopback4 model, respository, and datasource based on
an existing Rails application.

Step 0
------

Install `rails` and/or `loopback4` if they are not already installed:

    gem install rails
    npm install -g loopback-cli
    
Note: in order to install these tools, you need to have previously installed `ruby`, `node`, `npm` and other tools.  Check the installation instructions for
[rails](https://guides.rubyonrails.org/getting_started.html#installing-rails) and
[loopback4](https://loopback.io/doc/en/lb4/Getting-started.html) for details.

Step 1
------

Install this tool:

    gem install rails2lb4

Step 2
------

Locate a Rails application.  If you don't already have one, you can follow the [Creating the Blog Application](https://guides.rubyonrails.org/getting_started.html#creating-the-blog-application) in the Rails guide, or
clone it from [https://github.com/rubys/railsguide_blog](https://github.com/rubys/railsguide_blog.git).

Step 3
------

Locate or create a new loopback application.  To create a new application:

    lb4 app blog
    
Step 4
------

Run the tool, specifying the path to the source rails and destination loopback applications:

     rails2lb4 /path/to/rails/blog /path/to/loopback4/blog
     
Note: by default, this tool will set up the loopback application to access the Rails `development` database.  If you would like to access another database, set the `RAILS_ENV` environment variable before running this step.
 

Step 5 (optional)
-----------------

Create REST controllers for the new models:

    lb4 controller article
    lb4 controller comment
    
Note: specify `number` as the type of `id` for these controllers.
    
Step 6 (optional)
-----------------

Start the loopback4 server:

    npm start
    
Note: by default, both Rails and Loopback4 default to listen to port 3000.  Be sure to stop your Rails server before starting your loopback4 server.

