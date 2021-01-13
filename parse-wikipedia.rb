#!/usr/bin/env ruby
# coding: utf-8

require "rubygems"
require "bundler/setup"

require 'mediawiki_api'
require 'json'
require 'sanitize'


CATS_TO_IGNORE = ["", "Holidays and observances", "External links", "References", "Other"]


SANITIZE_CONFIG = Sanitize::Config.merge(
  Sanitize::Config::RELAXED,
  elements: Sanitize::Config::RELAXED[:elements].reject { |el| el == 'ref' },
  allow_comments: false,
  remove_contents: true
)

#
# grab data for a given date
#
def grab_date(x)
  mw = MediawikiApi::Client.new('https://en.wikipedia.org/w/api.php')

  actual_date = x.strftime("%m-%d")
  wiki_date = x.strftime("%B %e").gsub(/ +/, ' ')

  puts wiki_date
  wikitext = mw.get_wikitext(wiki_date).body.force_encoding("UTF-8")
  File.open("data/#{actual_date}.wiki", 'w') {|f| f.write(wikitext) }
  
  results = {
    date: wiki_date,
    url: "http://wikipedia.org/wiki/#{wiki_date.gsub(/ /, '_')}",
    data: process_data(wikitext)
  }
  File.open("data/#{actual_date}.json", 'w') {|f| f.write(results.to_json) }
end

def cleanup_entry(line)
  line[1..-1].gsub(/\[\[([^\|\]]+)\|([^\]]+)\]\]/) { |link|
    $2
  }.
    gsub(/''/, "'").
    gsub(/\]\]/, "").
    gsub(/\[\[/, "").
    gsub(/\&ndash;/, "-").
    gsub(/ +/, ' ').
    lstrip.rstrip.gsub(/\{\{([^\}]+)\}\}/) { |special|
    stuff = $1.split("|")
    type = stuff.first
    result = case 
             when type == "by"
               stuff.last
             when ["cite", "cite news"].include?(type)
               ""
             when type == "city-state"
               stuff.join(", ")
             when type.downcase == "convert"
               "#{stuff[1]} #{stuff[2]}"
             when type == "frac"
               "#{stuff[1]}/#{stuff[2]}"
             when type == "lang-de"
               stuff.last
             when type == "mdash"
               "--"
             when type == "NYT"
             when type == "okina"
               "okina"
             when type == "RailGauge"
               "4ft 8.5in"
             when type == "Sclass"
               "#{stuff[1]}-class #{stuff[2]}"
             when type.downcase == "ship"
               stuff[1,2].join(" ").rstrip.lstrip
             when type == "SMU"
               stuff[1]
             when type == "US$"
               stuff.join(" ")
             when ["HMAS", "HMS", "MS", "MV", "USS", "USCGC", "SS", "MS", "RMS"].include?(type)
               stuff = stuff.reject { |i| i == "" }
               if stuff.size <= 2
                 stuff.join(" ")
               #                   elsif stuff.size == 3
               #                     "#{stuff[0, 2].join(" ")}" # (#{stuff[2]})"
               else
                 stuff[0,2].join(" ")
               end
             end
    
    if result.nil?
      #puts "#{wiki_date} |#{cat}| #{type} #{special}"
      stuff.join(" ")
    else
      #puts "!! #{wiki_date} #{type} -> #{result}"
      result
    end
  }
end

#
# process wiki text, return a hash of results
#
def process_data(wikitext)
  cat = ""
  data = {}


  # remove any comments
  wikitext = wikitext.sub('<ref name="auto"/>', '')
  #comments = Regexp.new(/<!--(.*?)-->/, Regexp::MULTILINE)
  wikitext = wikitext.gsub(/<!--(.*?)-->/m, '')
  #wikitext = Sanitize.fragment(wikitext, SANITIZE_CONFIG)
  #puts wikitext

  last_year = nil
  
  wikitext.each_line { |line|
    line.chomp!

    # check for a ==Header==
    tmp = line.match /^\=\=([^\=]+)\=\=$/

    if tmp != nil
      last_year = nil
      cat = tmp[1].rstrip.lstrip
      data[cat] = [] unless CATS_TO_IGNORE.include?(cat)
    elsif line[0,1] == "*" and !CATS_TO_IGNORE.include?(cat)
      url = nil

      url_match = line[1..-1].match /\[\[([^\|\]]+)\|([^\]]+)\]\]/
      url = "http://wikipedia.org/wiki/#{$2.gsub(/ /, '_')}" unless url_match.nil? or ! url.nil?

      tmp = cleanup_entry(line)

      tmp = Sanitize.fragment(tmp, SANITIZE_CONFIG)

      # match some birth lines like "Mary Smith (b. 2001)"
      if cat != 'Deaths' && tmp.match?(/\(b. ([^)]+)\)$/)
        year = tmp.match(/\(b. ([^)]+)\)$/)[1]
        tmp = "#{year} - #{tmp.gsub(/^*-/, '').gsub(/\(b. ([^)]+)\)$/, '').rstrip}"
      end
      
      event_year, event_data = tmp.split(/[-|–] /)
      puts "!!!! #{tmp}" if event_year.nil?
      next if event_year.nil?
      
      if event_year.match?(/^*/) && event_data.nil? && !last_year.nil?
        event_data = cleanup_entry(event_year)
        event_year = last_year       
      end

      output = {:year => event_year&.strip, :text => event_data&.strip }

      
      if event_year.nil? || event_data.nil?
        puts "#{cat} -- #{line}"
        puts output.inspect
      end

      last_year = event_year unless event_year.nil?
      
      # skipping URL output for now
      #      output[:url] = url unless url.nil?
      data[cat] << output
    else
      #puts "!! #{cat} - #{line}" unless CATS_TO_IGNORE.include?(cat)
    end
  }

  data
end

span = Date.new(2000, 1, 1)..Date.new(2000, 12, 31)
#span = Date.new(2000, 1, 1)..Date.new(2000, 1, 1)
span.each { |x|
  grab_date(x)
}
