ENV['RACK_ENV'] ||= 'development'

require 'sinatra/base'
require 'sinatra/flash'
require 'securerandom'
require_relative 'datamapper_setup'
require_relative 'helpers'

class Bnb < Sinatra::Base

  helpers Helpers

  enable :sessions
  set :session_secret, ENV.fetch('SESSION_SECRET') { SecureRandom.hex(64) }
  register Sinatra::Flash
  use Rack::MethodOverride

  # start the server if ruby file executed directly
  run! if app_file == $0

  get '/' do
    redirect '/users/new'
  end

  # users routes

  get '/users/new' do
    erb :signup
  end

  post '/users' do
    @user = User.new(username: params[:name],
                        email: params[:email],
                        password: params[:password],
                        password_confirmation: params[:password_confirmation])
    if @user.save
      session[:user_id] = @user.id
      redirect '/users'
    else
      redirect '/users/new'
    end
  end

  get '/users' do
    erb(:welcome)
  end

  # spaces routes

  get '/spaces/new' do
    erb(:list_space)
  end

  post '/spaces' do
    @space = Space.create(title: params[:title],
                          description: params[:description],
                          price: params[:price],
                          availability_start: params[:availability_start],
                          availability_end: params[:availability_end],
                          user_id: current_user.id)
    redirect '/spaces'
  end

  get '/spaces' do
    @spaces = Space.all
    erb(:spaces)
  end

  # requests routes

  get 'requests/new' do
    # placeholder for page to create hire request (currently created straight from /spaces)
  end

  post '/requests' do

    if(Request.first(space_id: params[:space_id]))
      test = Request.all.select{ |request| p request.space_id == params[:space_id].to_i}.any?{ |space|
        p "space date:"
        p space.date.xmlschema
        p "params:date"
        p params[:date]
        p "same?"
        p space.date.xmlschema == params[:date]
      }

      p "TEST:"
      p test

      if test
        flash[:warning] == "Already booked"
      else
        Request.create(date: params[:date], user_id: session[:user_id], space_id: params[:space_id])
        flash.next[:notice] = "Request approved"
      end
    else
      Request.create(date: params[:date], user_id: session[:user_id], space_id: params[:space_id])
      redirect '/spaces'
    end



  end

  get '/requests' do
    @requests = current_user.spaces.map { |space| space.requests }.flatten
    @new_requests = @requests.select{ |request| request.approved == nil }
    @approved_requests = @requests.select{ |request| request.approved == true }
    erb(:requests)
  end

  patch '/requests' do
    @hire_request = Request.get(params[:request_id])

    if params[:action] == 'approve'
      @hire_request.update(approved: true)
      flash.next[:notice] = "Request approved"
    end
    if params[:action] == 'deny'
      @hire_request.update(approved: false)
      flash.next[:notice] = "Request denied"
    end
    redirect '/requests'
  end

  # sessions routes

  get '/sessions/new' do
    erb(:login)
  end

  post '/sessions' do
    @user = User.first(username: params[:name])
    if @user.nil? || @user.password != params[:password]
      flash.now[:error] = 'Username or password is incorrect'
      erb(:login)
    else
      session[:user_id] = @user.id
      redirect '/users'
    end
  end

  delete '/sessions' do
    session[:user_id] = nil
    redirect '/users'
  end

end
