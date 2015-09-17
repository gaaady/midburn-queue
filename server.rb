require 'sinatra'
require 'resque'
require 'json'
require 'dotenv'; Dotenv.load
require 'pry'

get '/' do
  "Hello liveLike!"
end