#!/usr/bin/env ruby
require 'sinatra'
get('/') { send_file File.expand_path('index.html', settings.public_folder)  }
get('/date/:month/:day') {
  content_type :json, 'charset' => 'utf-8'
  filename = "#{'%02d' % params['month'].to_i}-#{'%02d' % params['day'].to_i}.json"
  path = File.expand_path(File.join('data', filename), settings.public_folder)
  if params['callback']
    data = File.read(path)
    "#{params['callback']}(#{data})"
  else
    send_file path
  end
}
