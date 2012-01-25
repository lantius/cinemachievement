require 'rubygems'
require 'sinatra'
require 'open-uri'
require 'json'
require 'rest-client'
require "sinatra/reloader" if development?
require "#{File.dirname(__FILE__)}/models/user"

enable :sessions
set :protection, :except => [:remote_token, :frame_options] 

post '/signin' do
  authenticate(params[:token])
  redirect '/'
end

get '/signout' do
  session[:user] = nil
  redirect "/"
end

get '/' do
  haml :index
end

def authenticate(token)
  response = JSON.parse(
    RestClient.post("https://rpxnow.com/api/v2/auth_info",
      :token => token,
      :apiKey => "5f548b85d1663622cf73cd7bcab7fad47cf69e0e",
      :format => "json",
      :extended => "true"
    )
  )

  if response["stat"] == "ok"

    # {
    #   "profile": {
    #     "name": {
    #       "formatted": "Lee Williams"
    #     },
    #     "displayName": "Lee Williams",
    #     "preferredUsername": "Lee",
    #     "url": "http://lantius.org/openid/",
    #     "providerName": "Other",
    #     "identifier": "http://lantius.org/openid/",
    #     "email": "lant@lantius.org"
    #   },
    #   "stat": "ok"
    # }
    session[:user] = User.new(response["profile"]["identifier"], response["profile"]["preferredUsername"], response["profile"]["displayName"], response["profile"]["email"])
    return true
  end

  return false
end

helpers do
  def logged_in?
    !!current_user
  end

  def current_user
    return session[:user]
  end
end
