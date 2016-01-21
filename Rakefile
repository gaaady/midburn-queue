require "bundler/setup"
Bundler.require(:default)
require './resque_me'
require './worker'
require 'resque/tasks'

task "resque:setup" do
  ENV['QUEUE'] = '*'
end

desc "Alias for resque:work (To run workers on Heroku)"
task "jobs:work" => "resque:work"

desc "assets:precompile"
task "assets:precompile" do
  # nothing to precompile
end