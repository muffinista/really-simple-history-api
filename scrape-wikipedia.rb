#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require "rubygems"
require "bundler/setup"

require 'json'
require 'open-uri'
require 'nokogiri'

DIVIDERS = ['–', '-', '–'].uniq
SECTIONS = ["Events", "Births", "Deaths"]

if !File.directory?('data')
	Dir.mkdir 'data'
end

def closest_header(el)
  prev = el.previous_element
  return nil if prev.nil?

  return prev if prev.name == 'h2'

  prev = prev.previous_element
  return prev if prev.nil? || prev.name == 'h2'

  prev = prev.previous_element
  return prev if prev.nil? || prev.name == 'h2'

  return nil
end

def process_list(list)
  data = []

  list.css("li").each do |item|
    # get the flat text of the entry
    text = item.text
    #      puts text
    
    # 153 BC – Roman consuls begin their year in office.
    
    # figure out the year of the event
    year, result = text.split(/ [#{DIVIDERS.join('|')}] /, 2)

    result = result&.gsub(/\[\d+\]/, '')
    
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
      year = year.gsub(/AD /, '')
    end
    
    #puts "**** #{text} || #{year} --- #{result}"
    raise StandardError.new(text) if result == ''
    
    year = year.strip
    html = item.inner_html
             .squeeze(' ')
             .gsub(/^#{year.to_i}[ ]?[#{DIVIDERS.join('|')}] /, "")
             .gsub(/^ – /, "")
             .gsub(/^ - /, "")
    
    data << {
      year: year,
      text: result,
      html: "#{year} - #{html}",
      no_year_html: html,
      links: links       
    }
  end

  data
end


span = Date.new(2000, 1, 1)..Date.new(2000, 12, 31)
span.each { |x| 
  actual_date = x.strftime("%m-%d")
  wiki_date = x.strftime("%B %e").gsub(/ +/, ' ')

  puts wiki_date

  cat = ""
  data = {
  }

  url = "https://en.wikipedia.org/wiki/#{x.strftime('%B')}_#{x.strftime('%e').strip}"
  puts url
  wikitext = open(url) do |f|
    f.read
  end
  File.open("data/#{actual_date}.html", 'w') {|f| f.write(wikitext) }


  # switch to regular dashes
  wikitext.gsub!(/–/, "-")
  
  doc = Nokogiri::HTML(wikitext)
  lists = doc.css('ul').each do |ul|
    header = closest_header(ul)
    next if header.nil?

    # grab the section title from a span with this class
    section = header.css('.mw-headline')&.text

    next unless SECTIONS.include?(section)

    data[section] ||= []
    data[section] = [data[section], process_list(ul)].flatten
  end

  results = {
    :date => wiki_date,
    :url => "https://wikipedia.org/wiki/#{wiki_date.gsub(/ /, '_')}",
    :data => data
  }

  File.open("data/#{actual_date}.json", 'w') {|f| f.write(JSON.pretty_generate(results)) }
} # span.each
