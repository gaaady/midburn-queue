# resque-me

### What is this?
This is a resque (https://github.com/resque/resque) string enquing and worker test, deployed freely on Heroku.
Based on Sinatra, this webapp will receive a URL of (potentially) a text file, downloaded it and enqueue each word as a resque job for a 2nd worker to process on. In time, the worker will wake up to process the background job.

Sinatra web controller code:

### GET /test route
Some html to show on the /test route.
```ruby
  get '/test' do
    ...
  end
```

### POST /test route
Will download the given url text body and call split text and enqueue that html body chunk.
```ruby
  post '/test' do
    url = params["url"]    
    uri = URI(url)
    Net::HTTP.start(uri.host, uri.port, :use_ssl => (uri.scheme == 'https')) do |http|
      request = Net::HTTP::Get.new uri.request_uri
      http.request request do |response|
        response.read_body do |chunk|
          split_text_and_enqueue chunk
        end
      end
    end

    # returned html body.
    "<h1>done! check out: /resque</h1>"
  end
```

### GET /resque
The resque-web web interface to monitor progress of tasks.
- /resque/queues/worker - The `worker` queue
- /resque/working - Current worker processes (chewing on the `worker` queue)

### split_text_and_enqueue method
Split text to words and enqueue a new job

```ruby
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
```

## Known Issues
- The application is currently deployed to heroku on: https://resque-me.herokuapp.com which has it's limits.
- Since only one Ruby process is running, while queuing big chunk of text, the application may return 404. Be patient, the application runs on a free service :)
- Sometimes the queue may get stuck since Heroku decided to stop the worker, this should recover with couple of refreshes

## LICENSE
The MIT License (MIT)

See: LICENSE file.