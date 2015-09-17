require 'sinatra'
require 'resque'
require 'json'
require 'dotenv'; Dotenv.load
require 'pry'

class ResqueMe < Sinatra::Base

	get '/' do
	  "HELP!! Resque MEEE!"
	end
end