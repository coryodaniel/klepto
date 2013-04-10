# require this file to load the tasks
require 'rake'

# noop 
=begin
This is here as a start point for adding rake tasks that can be 'required' by another project
Just add: require 'klepto/tasks' to your Rakefile
=end

namespace :klepto do
  desc "Example task"
  task :example do
    puts "I'm a task"
  end
end