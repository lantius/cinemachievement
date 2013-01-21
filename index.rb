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

# For debugging: make sure CouchBase server is running.  Default port is 5984.
# Then export CLOUDANT_URL='http://localhost:5984'
if !("#{ENV['CLOUDANT_URL']}".match('^https://'))
  Kernel.puts('Environment variable "CLOUDANT_URL" must be set in development mode (probably http://localhost:5984).')
  exit()
end

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

post '/seenfilms' do
  if session[:user]
    # Kernel.puts(params['films'])
    if (!session[:user].seenfilms.kind_of? Hash)
      session[:user].seenfilms = Hash.new()
    end
    
    session[:user].seenfilms[params['database']] = params['films']
    
    #session[:user].seenfilms = params['films']
    # Kernel.puts(session[:user].to_json)
    put_response = RestClient.put("#{DB}/#{session[:user].identifier}", session[:user].to_json, :content_type => 'application/json')
    session[:user].rev = JSON.parse(put_response)['rev']
    # Kernel.puts(session[:user].rev)
  end
end

get '/?:database?' do
  # get our movies
  movies = nil
  
  database = params[:database] ? params[:database] : "2013oscars"
  RestClient.get("#{MOVIE_DB}/#{database}"){|db_response, db_request, db_result|  
    case db_response.code
    when 200
      movie_object = JSON.parse(db_response)
      movies = movie_object['data']
    else
      movies = '{
        "movies" : [ 
          {"title": "Test Film #1", "oscars": 7},
          {"title": "Test Film #2, Electric Boogaloo", "oscars": 7},
          {"title": "Test Film #3", "oscars": 6},
          {"title": "Test Film #4", "oscars": 3},
        ]
      };'
    end
  }
  seen_films = []
  if session[:user] and session[:user].seenfilms.kind_of? Hash
    seen_films = session[:user].seenfilms[database]
  end
  
  haml :index, :locals => { :movies => movies, :database_id => database, :seen_films => seen_films.to_json }
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
        @user = User.new(id, nil, response["profile"]["preferredUsername"], response["profile"]["displayName"], response["profile"]["email"], nil)
        # Kernel.puts(@user.to_json)
        # Kernel.puts("#{DB}/#{id}")
        put_response = RestClient.put("#{DB}/#{id}", @user.to_json, :content_type => 'application/json')
        @user.rev = JSON.parse(put_response)['rev']
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
