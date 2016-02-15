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

    load_params
  end 

  def load_params
    return @params if @request_body_read
    begin
      @params = JSON.parse(request.body.read)
      @request_body_read = true
    rescue Exception => e
      @params = {}
    end
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
    halt(403) if not queue_is_open?
    { register_page: ENV["REGISTER_FORM_URL"] }.to_json
  end

  post '/register' do
    halt(400) if params["username"].empty?

    puts "[access log] POST: #{params}" # put a little access log
    order_json = %{{"ip":"#{request.ip}","timestamp":"#{Time.now.to_i}","email":"#{params["username"]}"}}

    if queue_is_open?
      Resque.enqueue(TicketsQueue, order_json)
    else
      Resque.enqueue(BannedOrder, order_json)
      halt(403)
    end
  end
end
