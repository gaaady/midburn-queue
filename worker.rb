lambda { 
  x = -1
  Kernel.send(:define_method, :get_tier_number) {
    x += 1
    x.to_s.rjust(3, '0')
  }
}.call

500.times do |tier_number|
  Object.const_set("OrderTier_#{tier_number}", Class.new do
      @queue = :"tier_#{get_tier_number}"
      def self.perform(json) 
        process_order(JSON.parse(json)) 
      end 
    end
  )
end

def process_order(order)
  # process order
  puts "got: #{order}"
end