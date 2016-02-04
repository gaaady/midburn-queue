# Midburn Tickets Queue

### What is this?

This is Midburn's tickets processing queue. Each batch of order requests submitters (say 100 orders) will be enqueue into an ordered queue (say: tier_001) which will be processed later by a worder.

Navigate to `/resque` to follow processing order (or clearing past tasks).

Submit a new order by `POST /enqueue` with a JSON file and `Content-Type: application/json`. The following curl command will work:

```
curl -X POST http://midburn-tickets-queue.herokuapp.com/enqueue -d '{"firstname": "elad", "lastname": "gariany", "email":"email@gmail.com"}' --header "Content-Type: application/json"
```

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

The following `curl` command will queue a new order to process:
```
curl -X POST http://midburn-tickets-queue.herokuapp.com/enqueue -d '{"firstname": "elad", "lastname": "gariany", "email":"email@gmail.com"}' --header "Content-Type: application/json"       
```

##### Params
- `firstname` - Submitter's first name.
- `lastname` - Submitter's last name.
- `email` - Submitter's email address (profile on profile.midburn.org)

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

## Configuration (Heroku)
1. Close the queue:
`heroku run bundle exec rake midburn:close_queue --app midburn-queue`

2. Open the queue:
`heroku run bundle exec rake midburn:open_queue  --app midburn-queue`

3. Getting the list of emails in the queue
`heroku run bundle exec rake midburn:list --app midburn-queue`

4. Reset queue:
`heroku run bundle exec rake midburn:reset --app midburn-queue`

5. Checking the heroku logs:
`heroku logs -t --app midburn-queue`

## LICENSE
The MIT License (MIT)

See: LICENSE file.
