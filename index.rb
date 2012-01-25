require 'rubygems'
require 'sinatra'
require 'open-uri'
require 'uri'
require 'json'
require 'rest-client'
require "sinatra/reloader" if development?
require "#{File.dirname(__FILE__)}/models/user"

enable :sessions, :static
set :protection, :except => [:remote_token, :frame_options] 

DB = "#{ENV['CLOUDANT_URL']}/cinemachievement"
MOVIE_DB = "#{ENV['CLOUDANT_URL']}/cinemachievement_movies"

post '/signin' do
  authenticate(params[:token])
  redirect '/'
end

get '/signout' do
  session[:user] = nil
  redirect "/"
end

get '/' do
  # get our movies
  movies = nil
  RestClient.get("#{MOVIE_DB}/oscars"){|db_response, db_request, db_result|  
    case db_response.code
    when 200
      movies = db_response[:data].to_str
    else
      movies = '{
        "movies" : [ 
          {"title": "Test Film #1", "oscars": 7, "seen": false},
          {"title": "Test Film #2, Electric Boogaloo", "oscars": 7, "seen": false},
          {"title": "Test Film #3", "oscars": 6, "seen": true},
          {"title": "Test Film #4", "oscars": 3, "seen": false},
        ]
      };'
    end
  }
  haml :index, :locals => { :movies => movies }
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
    id = response["profile"]["identifier"]
    id = URI.escape(id, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
    
    @user = nil
    RestClient.get("#{DB}/#{id}"){|db_response, db_request, db_result|  
      case db_response.code
      when 200
        # Kernel.puts(db_response.to_str)
        @user = JSON.parse(db_response.to_str)
      else
        @user = User.new(id, response["profile"]["preferredUsername"], response["profile"]["displayName"], response["profile"]["email"])
        # Kernel.puts(@user.to_json)
        # Kernel.puts("#{DB}/#{id}")
        RestClient.put("#{DB}/#{id}", @user.to_json, :content_type => 'application/json')
      end
    }
    session[:user] = @user
    
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
