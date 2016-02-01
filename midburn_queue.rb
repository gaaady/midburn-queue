# environment space
require "sinatra"
require 'sinatra/cross_origin'
require "dotenv"; Dotenv.load

# application space
require "pry"
require "redis"
require "resque"
require "csv"
require "./worker.rb"

class MidburnQueue < Sinatra::Base
  configure do
    enable :cross_origin
  end  

  set(:method) do |method|
    method = method.to_s.upcase
    condition { request.request_method == method }
  end

  before :method => :post do
    # http://stackoverflow.com/questions/15671006/before-filter-for-all-post-requests-in-sinatra
    response.headers["Access-Control-Allow-Headers"] = "X-Requested-With, X-HTTP-Method-Override, Content-Type, Cache-Control, Accept"
    response.headers["Access-Control-Allow-Origin"] = ENV["ACCESS_CONTROL_ALLOW_ORIGIN"]
  end 

  def get_params
    JSON.parse(request.body.read)
  end

  def queue_is_open?
    Resque.redis.get("queue_is_open") == "true"
  end

  options "*" do
    response.headers["Allow"] = "HEAD,POST,OPTIONS"
    response.headers["Access-Control-Allow-Headers"] = "X-Requested-With, X-HTTP-Method-Override, Content-Type, Cache-Control, Accept"
    response.headers["Access-Control-Allow-Origin"] = ENV["ACCESS_CONTROL_ALLOW_ORIGIN"]
    200
  end

  post '/status' do 
    status = queue_is_open? ? 200 : 403
    halt(status)
  end

  post '/enqueue' do
    payload = get_params
    order_json = %{{"ip":"#{request.ip}","timestamp":"#{Time.now.to_i}","email":"#{payload["email"]}"}}

    if queue_is_open?
      Resque.enqueue(TicketsQueue, order_json)
    else
      Resque.enqueue(BannedOrder, order_json)
      halt(403)
    end
  end
end