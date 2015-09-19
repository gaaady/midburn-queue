#!/usr/bin/env ruby
require 'logger'
$LOAD_PATH.unshift File.dirname(__FILE__) + '/../../lib'
$LOAD_PATH.unshift File.dirname(__FILE__) unless $LOAD_PATH.include?(File.dirname(__FILE__))
require 'resque/server'
require './resque_me.rb'

use Rack::ShowExceptions

$redis = Redis.new(url: ENV["REDIS_URL"])
Resque.redis = $redis

run Rack::URLMap.new \
  "/"       => ResqueMe.new,
  "/resque" => Resque::Server.new