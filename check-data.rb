#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require "rubygems"
require "bundler/setup"

require 'json'
require 'date'

expected_base = ["date", "url", "data"]
expected_data = ["Events", "Births", "Deaths"]

MIN_YEAR = 40
MIN_EVENTS = 20
MIN_TOTAL_EVENTS = 17900

DEST = ENV['DEST'] || 'data'

total = 0

span = Date.new(2000, 1, 1)..Date.new(2000, 12, 31)
span.each { |x| 
  actual_date = x.strftime("%m-%d")
  source = "#{DEST}/#{actual_date}.json"
  
  data = JSON.parse(File.read(source))
  puts actual_date

  missing = expected_base - data.keys
  raise StandardError.new("#{actual_date} missing base data! -- #{missing.inspect}") unless missing.empty?
  
  missing = expected_data - data['data'].keys 
  raise StandardError.new("#{actual_date} missing data! -- #{missing.inspect}") unless missing.empty?

  years = data['data']['Events'].collect { |entry| entry['year'].to_i }
  raise StandardError.new("#{actual_date} nothing in last #{MIN_YEAR} years!") unless years.max >= Date.today.year - MIN_YEAR

  count = data['data']['Events'].count
  raise StandardError.new("#{actual_date} only #{count} events?") unless count > MIN_EVENTS

  total += count
}


raise StandardError.new("total events only #{total}") unless total >= MIN_TOTAL_EVENTS
