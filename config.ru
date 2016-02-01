require 'logger'
$LOAD_PATH.unshift File.dirname(__FILE__) + '/../../lib'
$LOAD_PATH.unshift File.dirname(__FILE__) unless $LOAD_PATH.include?(File.dirname(__FILE__))
require 'resque/server'
require './midburn_queue.rb'

use Rack::ShowExceptions

run Rack::URLMap.new \
  "/"       => MidburnQueue.new