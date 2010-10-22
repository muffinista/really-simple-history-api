require 'rubygems'
require 'sinatra'
require 'json'
require 'date'

$KCODE = 'u' if RUBY_VERSION < '1.9'

get '/' do
  erb :index
end
get '/ticker' do
  erb :ticker
end

get '/date/?' do
  results Date.today
end

get '/date/?:month/?:day?' do
  if params[:month].nil? or params[:day].nil?
    x = Date.today
  else
    x = Date.new(2000, params[:month].to_i, params[:day].to_i)
  end
  results x
end

def results(day)
  source = "data/#{day.strftime("%m-%d")}.json"

  content_type :json, 'charset' => 'utf-8'

  # to output pretty JSON
  #  tmp = IO.read(source)
  #  JSON.pretty_generate JSON.parse tmp

  # to output scrunched JSON
  IO.read(source)
end
