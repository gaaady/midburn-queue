class WordProcessorWorker
  @queue = :worker
  def self.perform(word)
    puts ">> Processing: #{word}"
    sleep(0.1)
  end
end