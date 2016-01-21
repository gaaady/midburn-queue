# Midburn Tickets Queue

### What is this?


### Application Routes

Sinatra web controller code:

### GET '/'
This service have no root route, requests will be redirected to midburn.org

```ruby
get '/' do
  redirect "http://midburn.org"
end
```

### GET /resque
The resque-web web interface to monitor progress of tasks.
- /resque/queues/worker - The `worker` queue
- /resque/working - Current worker processes (chewing on the `worker` queue)

Notice: In order to access the monitor you will need to set env values `RESQUE_WEB_HTTP_BASIC_AUTH_USER` and `RESQUE_WEB_HTTP_BASIC_AUTH_PASSWORD`. If those will not be provided the interface will be open to everyone.

### POST '/big-reset'

Big reset will reset all the queues and 'tasks' (process orders). This should be perform before each sell.

```ruby
post '/big-reset' do
  # assuming ENV['ADMIN_SECRET_TOKEN'] is correct, reset all queues
end
```

###### Params
`admin_secret_token` - the environment's admin secret key


### POST '/enqueue'

Enqueue new order to process.

```ruby
post '/enqueue' do
  # calculate tier number using ENV["QUEUE_TIER_SIZE"], the amount of tasks on queues and completed tasks.
  # Add a new task to order on the relevant queue.
end
```

### Known Issues
- Orders in the system are limited to 500 * QUEUE_TIER_SIZE (say, 50,000 in case each tier size is 100).

### Worker code
```ruby

def process_order(json = {"firstname":"elad","lastname":"gariany","email":"elad@gariany.com"})
  # process order
  # - validate with profile system, to confirm user have a profile
  # - generate the email to be send to a client
  # - send the email for purchase
end

class OrderTier_1
  @queue = :tier_001
  def self.perform(json)
    process_order(JSON.parse(json))
  end
end
```

## LICENSE
The MIT License (MIT)

See: LICENSE file.
