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

desc "pry console into the system"
task :pry_admin do
  require "pry"
  binding.pry
end

desc "Stress test an endpoint with enqueues"
task "test:stress_test" do

  host_url = "https://midburn-queue.herokuapp.com/enqueue"
  tester_name = ('a'..'z').to_a.shuffle[0,8].join

  threads = []
  10.times do |thread_index|
    threads << Thread.new(thread_index) do
      100.times do |index|
        time = Time.now
        email = "#{tester_name}_thread_#{thread_index}_index_#{index}@gariany.com"
        RestClient.post host_url, { "email" => email }.to_json, :content_type => :json, :accept => :json do |response, request, result, &block|
          puts "thread #{thread_index}: finished #{email}. Took: #{Time.now - time}"
        end
      end
    end
  end

  threads.each { |aThread|  aThread.join }
end
