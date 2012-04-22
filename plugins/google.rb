require 'open-uri'
require 'nokogiri'
require 'cgi'

class Google
  include Cinch::Plugin
  match /google (.+)/

  def search(query)
    answer = ""
    open( "https://www.google.com/search?q=#{ CGI.escape( query ) }&safe=active" ) do |html|
      counter = 0
      html.read.scan /<a href="?\/url\?q=([^"&]+).*?".*?>(.+?)<\/a>/m do |match|
        url, title = match
        title.gsub!( /<.+?>/, "" )
        ua = query.gsub( /-?site:\S+/, '' ).strip
        answer = "[#{ua}]: #{url} - #{title}"
      end
    end
    answer
  rescue
    "No results found"
  end

  def execute(m, query)
    m.reply(search(query))
  end
end
