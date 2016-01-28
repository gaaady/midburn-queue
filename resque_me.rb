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

TIER_SIZE = ENV["QUEUE_TIER_SIZE"].to_i

class ResqueMe < Sinatra::Base

  configure do
    enable :cross_origin
  end  

  def get_params
    JSON.parse(request.body.read)
  end

  def validate_admin_token!
    unauthorized unless get_params["admin_secret_token"] == ENV["ADMIN_SECRET_TOKEN"]
  end

  def unauthorized
    puts "============= UNAUTHORIZED! =============="
    puts "unauthorized request from #{request.ip}"
    puts "=========================================="
    halt 403
  end

  def count_ip_appearance(data, ip)
    data.count { |e| e[1] == ip }
  end

  def duplicate_email?(data, email)
    data.each do |args|
      return true if (args[3] == email)
    end
    return false
  end

  def queue_is_open?
    ENV["QUEUE_IS_OPEN"] == "true"
  end

  get '/' do
    redirect "http://midburn.org"
  end

  post '/status' do
    response.headers["Access-Control-Allow-Headers"] = "X-Requested-With, X-HTTP-Method-Override, Content-Type, Cache-Control, Accept"
    response.headers["Access-Control-Allow-Origin"] = ENV["ACCESS_CONTROL_ALLOW_ORIGIN"]
 
    status = queue_is_open? ? 200 : 403
    halt(status)
  end

  post '/list' do
    validate_admin_token!
    
    data = []
    Resque.queues.each do |queue|
      Resque.peek(queue, 0, TIER_SIZE).find_all do |job| 
        args = JSON.parse(job["args"][0])

        ip, timestamp, email = args["ip"], args["timestamp"], args["email"]
        ip_appearance = count_ip_appearance(data, ip)
        data << [ queue, ip, timestamp, email, ip_appearance ] unless duplicate_email? data, email
      end
    end

    CSV.generate do |csv|
      data.each do |row|
        csv << row
      end
    end
  end

  post '/big-reset' do
    validate_admin_token!

    puts "========== PERFORMING BIG RESET =========="
    puts "Performing big reset. Removing all tasks from all queues!"
    queues = Resque.queues
    queues.each do |queue_name|
      puts "Clearing #{queue_name}..."
      Resque.remove_queue "#{queue_name}"
      Resque.redis.del "queue:#{queue_name}"
    end
    
    puts "Clearing delayed..." # in case of scheduler - doesn't break if no scheduler module is installed
    Resque.redis.keys("delayed:*").each do |key|
      Resque.redis.del "#{key}"
    end
    Resque.redis.del "delayed_queue_schedule"
    
    puts "Clearing stats..."
    Resque.redis.set "stat:failed", 0 
    Resque.redis.set "stat:processed", 0
    puts "Done."
    puts "=========================================="
  end

  post '/enqueue' do
    response.headers["Access-Control-Allow-Headers"] = "X-Requested-With, X-HTTP-Method-Override, Content-Type, Cache-Control, Accept"
    response.headers["Access-Control-Allow-Origin"] = ENV["ACCESS_CONTROL_ALLOW_ORIGIN"]

    payload = get_params
    order_json = %{{"ip":"#{request.ip}","timestamp":"#{Time.now.to_i}","email":"#{payload["email"]}"}}

    if queue_is_open?
      tier_number = (Resque.info[:pending] + Resque.info[:processed]).div TIER_SIZE
      Resque.enqueue(eval("OrderTier_#{tier_number}"), order_json)
    else
      Resque.enqueue(BannedOrder, order_json)
      halt(403)
    end
  end

  options "*" do
    response.headers["Allow"] = "HEAD,POST,OPTIONS"
    response.headers["Access-Control-Allow-Headers"] = "X-Requested-With, X-HTTP-Method-Override, Content-Type, Cache-Control, Accept"
    response.headers["Access-Control-Allow-Origin"] = ENV["ACCESS_CONTROL_ALLOW_ORIGIN"]
    200
  end
end