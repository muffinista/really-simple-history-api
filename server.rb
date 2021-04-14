#!/usr/bin/env ruby
require 'sinatra'
require 'date'

before { response.headers['Access-Control-Allow-Origin'] = '*' }

options "*" do
  response.headers["Allow"] = "HEAD,GET,PUT,POST,DELETE,OPTIONS"
  response.headers["Access-Control-Allow-Headers"] = "X-Requested-With, X-HTTP-Method-Override, Content-Type, Cache-Control, Accept"
 
  200
end

get('/') { send_file File.expand_path('index.html', settings.public_folder)  }

get('/date') {
  content_type :json, 'charset' => 'utf-8'

  today = Date.today
  render_data(today.month, today.day)
}

get('/date/:month/:day') {
  content_type :json, 'charset' => 'utf-8'
  render_data(params[:month], params[:day])
}


def render_data(month, day)
  filename = "#{'%02d' % month.to_i}-#{'%02d' % day.to_i}.json"
  path = File.expand_path(File.join('data', filename), settings.public_folder)
  if params['callback']
    data = File.read(path)
    "#{params['callback']}(#{data})"
  else
    send_file path
  end
end
