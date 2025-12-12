#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require "rubygems"
require "bundler/setup"

require 'json'
require 'open-uri'
require 'nokogiri'

DIVIDERS = ['–', '-', '–'].uniq
SECTIONS = ["Events", "Births", "Deaths"]

DEST = ENV['DEST'] || 'data'

EXPECTED_BASE = ["date", "url", "data"]
EXPECTED_DATA = ["Events", "Births", "Deaths"]

MIN_YEAR = 40
MIN_EVENTS = 20

if !File.directory?(DEST)
  Dir.mkdir DEST
end

USER_AGENT = ENV.fetch('USER_AGENT', "TodayInHistory/0.0 https://muffinlabs.com/ Ruby/#{RUBY_VERSION}")
SLEEP_RATE = ENV.fetch('SLEEP_RATE', 5).to_i

#
# <div class="mw-heading mw-heading2">
#  <h2 id="Events">Events</h2>
# </div>
#                                           
def closest_header(el)
  prev = el.previous_element
  until prev.nil?
    return prev if prev.attributes['class']&.value&.include?('mw-heading2')
    prev = prev.previous_element
  end

  return nil
end

def process_list(list)
  data = []

  list.css("li").each do |item|
    # get the flat text of the entry
    text = item.text
    #puts text
    
    # 153 BC – Roman consuls begin their year in office.
    
    # figure out the year of the event
    year, result = text.split(/ [#{DIVIDERS.join('|')}] /, 2)

    result = result&.gsub(/\[\d+\]/, '')
    #puts result

    #puts item.inspect
    
    # remove the first link if it happens to be the year
    maybe_year = item.css("a").first
    if maybe_year && maybe_year.content == year
      maybe_year.replace maybe_year.inner_html
    end
    
    superscripts = item.css("sup")
    superscripts.each { |ss|
      ss.remove
    }
    
    item.css("a").each { |link|
      link["href"] = "https://wikipedia.org#{link['href']}"
    }
    
    links = item.css("a").collect { |link|
      if link.attributes['title']
        {
          title: link.attributes['title'].value,
          link: link['href']
        }
      else
        nil
      end
    }.compact
    
    next if text.nil? || text == ""
    
    if year.nil?
      puts "**** #{text} || #{year} --- #{item.inner_html}"
    else
      year = year.gsub(/AD /, '').gsub(/BC /, '')
    end
    
    #puts "**** #{text} || !!#{year}!! --- #{result}"
    raise StandardError.new(text) if result == ''
    
    year = year.strip
    html = item.inner_html
             .squeeze(' ')
             .gsub(/^#{year.to_i}[ ]?[#{DIVIDERS.join('|')}] /, "")
             .gsub(/^ – /, "")
             .gsub(/^ - /, "")

    
    data << {
      'year' => year,
      'text' => result,
      'html' => "#{year} - #{html}",
      'no_year_html' => html,
      'links' => links       
    }
  end

  data
end


def validate_year(data)
  missing = EXPECTED_BASE - data.keys
  raise StandardError.new("missing base data! -- #{missing.inspect}") unless missing.empty?
  
  missing = EXPECTED_DATA - data['data'].keys 
  raise StandardError.new("missing data! -- #{missing.inspect}") unless missing.empty?

  years = data['data']['Events'].collect { |entry| entry['year'].to_i }

  raise StandardError.new("nothing in last #{MIN_YEAR} years!") unless years.max >= Date.today.year - MIN_YEAR

  count = data['data']['Events'].count
  raise StandardError.new("only #{count} events?") unless count > MIN_EVENTS
end


span = Date.new(2000, 1, 1)..Date.new(2000, 12, 31)
span.each { |x| 
  actual_date = x.strftime("%m-%d")
  wiki_date = x.strftime("%B %e").gsub(/ +/, ' ')

  puts wiki_date

  cat = ""
  data = {
  }

  cached_file = "#{DEST}/#{actual_date}.html"

  if File.exist?(cached_file)
    wikitext = File.read(cached_file)
  else
    puts "Sleeping a bit to be kind and avoid rate limiting"
    sleep SLEEP_RATE
    url = "https://en.wikipedia.org/wiki/#{x.strftime('%B')}_#{x.strftime('%e').strip}"
    puts url
    wikitext = URI.open(url, "User-Agent" => USER_AGENT) do |f|
      f.read
    end

    File.write(cached_file, wikitext) if ENV["CACHE_HTML"].to_i == 1
  end

  # switch to regular dashes
  wikitext = wikitext.gsub(/–/, "-").gsub('&#8211;', '-')
  
  doc = Nokogiri::HTML(wikitext)

  # clean out some junky h3 elements
  doc.css('ul + h3').each(&:remove)
  doc.css('div.thumb').each(&:remove)
  doc.css('.mw-editsection').each(&:remove)
  
  lists = doc.css('ul').each do |ul|
    header = closest_header(ul)
    next if header.nil?

    # grab the section title from a span with this class
    section = header.text    

    next unless SECTIONS.include?(section)

    data[section] ||= []
    data[section] = [data[section], process_list(ul)].flatten
  end

  results = {
    'date' => wiki_date,
    'url' => "https://wikipedia.org/wiki/#{wiki_date.gsub(/ /, '_')}",
    'data' => data
  }

  validate_year(results)

  
  dest = "#{DEST}/#{actual_date}.json"
  File.open(dest, 'w') {|f| f.write(JSON.pretty_generate(results)) }
} # span.each
