#!/usr/bin/env ruby

require "rubygems"
require "bundler/setup"

require 'rest_client'
require 'media_wiki'
require 'json'

mw = MediaWiki::Gateway.new('http://en.wikipedia.org/w/api.php')

span = Date.new(2000, 1, 1)..Date.new(2000, 12, 31)
span.each { |x| 

  actual_date = x.strftime("%m-%d")
  wiki_date = x.strftime("%B %e").gsub(/ +/, ' ')

  puts wiki_date

  cat = ""
  data = {}

  wikitext = mw.get(wiki_date)
  File.open("data/#{actual_date}.wiki", 'w') {|f| f.write(wikitext) }

  cats_to_ignore = ["", "Holidays and observances", "External links", "References"]

  wikitext.each_line { |line|
    line.chomp!
    tmp = line.match /\=\=([^\=]+)\=\=/


    if tmp != nil
      cat = tmp[1].rstrip.lstrip
      data[cat] = [] unless cats_to_ignore.include?(cat)
    elsif line[0,1] == "*" and !cats_to_ignore.include?(cat)
      url = nil

      url_match = line[1..-1].match /\[\[([^\|\]]+)\|([^\]]+)\]\]/
      url = "http://wikipedia.org/wiki/#{$2.gsub(/ /, '_')}" unless url_match.nil? or ! url.nil?

      tmp = line[1..-1].gsub(/\[\[([^\|\]]+)\|([^\]]+)\]\]/) { |link|
        $2
      }.
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

      #    tmp = line[1..-1].gsub(/\&ndash;/, "-").gsub(/ +/, ' ').lstrip.rstrip
      #puts tmp

      output = {:text => tmp }
      # skipping URL output for now
      #      output[:url] = url unless url.nil?
      data[cat] << output
    else
#      puts "!! #{cat} #{line}"
    end
  }


  results = {
    :date => wiki_date,
    :url => "http://wikipedia.org/wiki/#{wiki_date.gsub(/ /, '_')}",
    :data => data
  }
  File.open("data/#{actual_date}.json", 'w') {|f| f.write(results.to_json) }
} # span.each
