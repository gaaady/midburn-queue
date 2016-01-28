def duplicate_email?(data, email)    
  data.each { |e| return true if e[3] == email }
  false
end

def reset_queue!
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

def collect_orders
  data = []
  Resque.queues.each do |queue|
    Resque.peek(queue, 0, MidburnQueue::TIER_SIZE).find_all do |job| 
      args = JSON.parse(job["args"][0])
      ip, timestamp, email = args["ip"], args["timestamp"], args["email"]
      ip_appearance = data.count { |e| e[1] == ip }
      data << [ queue, ip, timestamp, email, ip_appearance ] unless duplicate_email? data, email
    end
  end
  data  
end

def generate_csv(data)
  require "csv"
  CSV.generate do |csv|
    data.each { |r| csv << r }
  end
end