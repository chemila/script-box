#!/usr/bin/env ruby

require 'nokogiri'
require 'open-uri'

fp = File.open('github.com.cookie', 'r')
cookie = fp.readline

url_base = "https://github.com/stars?direction=desc&sort=created&page="
i = 1

while true do
    begin
        url = url_base + i.to_s
        html = open(url, "Cookie" => cookie)
        page = Nokogiri::HTML(html)
        result = page.css("a.js-navigation-open")

        if result.length > 0 then
            result.each{|x|
                star_url = x['href'].insert(0, 'http://github.com/stars')
                star_name = x.text
                print star_url, ' ------ ', star_name, "\n"
            }

            i += 1
            puts url
            puts '=============================================='
        else
            break
        end
    rescue OpenURI::HTTPError => ex
        puts "404"
    end
end

puts "Finished!"

# end of this file