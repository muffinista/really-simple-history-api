#!/usr/bin/env ruby
# encoding: UTF-8

require "rubygems"
require "bundler/setup"

require 'rest_client'
require 'media_wiki'
require 'json'

mw = MediaWiki::Gateway.new('http://en.wikipedia.org/w/api.php')

# takes the argument from command line
required_year = ARGV[0]

cat = ""
month = ""
previous_day = ""
previous_month = ""
data = {}

wikitext = mw.get(required_year)
# File.open("data/#{required_year}.wiki", 'w') {|f| f.write(wikitext) }
cats_to_ignore = ["", "Holidays and observances", "External links", "References", "See also", "In fiction", "Templeton Prize", "Fields Medal", "Right Livelihood Award"]

wikitext.each_line { |line|
  begin
    line.chomp!
    line = line.gsub(/<ref ?[\s\S]*>[\s\S]*<\/ref>/, '').gsub(/<ref ?[\s\S]*\/>/, '')
    month_check = line.match /\=\=\=([^\=]+)\=\=\=/
    if month_check == nil
      tmp = line.match /\=\=([^\=]+)\=\=/
    end

    if tmp != nil
      cat = tmp[1].rstrip.lstrip
      data[cat] = {} unless cats_to_ignore.include?(cat)
      month = ""
    end

    if month_check != nil
      month = month_check[1].rstrip.lstrip.gsub(/\&ndash;/,' - ')
      data[cat][month] = []
    elsif line[0,1] == "*" and !cats_to_ignore.include?(cat)
      tmp = line[1..-1].gsub(/\[\[([^\|\]]+)\|([^\]]+)\]\]/) { |link|
        $2
      }.
          gsub(/''/, "'").
          gsub(/\]\]/, "").
          gsub(/\[\[/, "").
          gsub(/\&ndash;|\u2013|\u2014/, "-").
          gsub(/ +/, ' ').
          gsub(/<ref ?[\s\S]*>[\s\S]*<\/ref>/, '').
          gsub(/<ref ?[\s\S]*\/>/, '').
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
                         else
                           stuff[0,2].join(" ")
                         end
                     end

          if result.nil?
            stuff.join(" ")
          else
            result
          end
        }

        if line[0,2] != "**"
          day, event_data = tmp.split(" - ")
          if event_data == nil
            event_data = ""
          end
          previous_day = day
          output = {day => event_data }
          if month == ""
            month = day.split(" ").first
            previous_month = month
            if data[cat][month] == nil
              data[cat][month] = []
            end
            data[cat][month] << output
            month = ""
            next
          end
          data[cat][month] << output
        else
          day = previous_day
          if month == ""
            month = previous_month
          end
          if data[cat][month][-1][day] == ""
            data[cat][month][-1][day] += tmp
		  else
            data[cat][month][-1][day] += "\n"+tmp
          end
        end
      end
    rescue
      next
    end
  }

results = {
    :year => required_year,
    :data => data
}
File.open("#{required_year}.json", 'w') {|f| f.write(results.to_json) }