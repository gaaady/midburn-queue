# environment space
require 'sinatra'
require 'dotenv'; Dotenv.load
require "redis"
require "resque"

# application space
require 'open-uri'
require 'net/http'
require "./worker.rb"

class ResqueMe < Sinatra::Base

  def split_chunk_and_enqueue(chunk)
    begin
      words = chunk.split(" ")
      puts ">> Enqueue: will enqueue #{words.count} processing tasks."
      words.each { |w| Resque.enqueue(WordProcessorWorker, w) }
      puts ">> Enqueue: done!"
    # ignore exceptions
    rescue Exception => e
    end
  end

	get '/' do
	  "Resque MEEE!"
	end

  get '/test' do
    <<-html
      <div>
        <form id="form" action="test" method="POST">
          <div>
            <input type="text" name="url" id="url" placeholder="http://enter.some.url/some-plain-text-will-be-good.txt" 
                   value="http://www.gutenberg.org/cache/epub/1232/pg1232.txt" style="width: 80%; padding: 10px; margin: 10px;">
          </div>
          <div style="margin: 10px;">
            <input class="button radius right success" type="submit" value="Submit">
          </div>
        </form>
        <div>
          <ul>
            <li>https://gist.github.com/eladg/65034b89fb694d46aca4, click on the raw button and paste whatever generated URL, small</l1>
            <li>http://www.gutenberg.org/cache/epub/1232/pg1232.txt, The Prince by Niccolò Machiavelli, 299 kB</li>
            <li>http://www.ccel.org/ccel/bible/kjv.txt, The Bible, 4.5MB</li>
          </ul>
        </div>
      </div>
    html
  end

  post '/test' do
    url = params["url"]    
    uri = URI(url)
    Net::HTTP.start(uri.host, uri.port, :use_ssl => (uri.scheme == 'https')) do |http|
      request = Net::HTTP::Get.new uri.request_uri
      http.request request do |response|
        puts ">> HTTP: will read a chunk of the HTTP document"
        response.read_body do |chunk|
          split_chunk_and_enqueue chunk
        end
        puts ">> HTTP: done."
      end
    end
    "done! check out: /resque"
  end

end