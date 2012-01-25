require 'rubygems'
require 'sinatra'
# require 'open-uri'
# require 'json'
# require "sinatra/reloader" if development?

get '/' do
  haml :index
end