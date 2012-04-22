require 'open-uri'
require 'nokogiri'
require 'cgi'

class Google
  include Cinch::Plugin

  GOOGLEFIGHT_VERBS = [
      [ 1000.0, "completely DEMOLISHES" ],
      [ 100.0, "utterly destroys" ],
      [ 10.0, "destroys" ],
      [ 5.0, "demolishes" ],
      [ 3.0, "crushes" ],
      [ 2.0, "shames" ],
      [ 1.2, "beats" ],
      [ 1.0, "barely beats" ],
  ]

  set(:plugin_name => "google",
      :help => "Usage: !google serach terms, !gf search terms vs search terms")
 
  def search(query)
    answer = ""
    html = self.class.search(query)
    counter = 0
    html.scan /<a href="?\/url\?q=([^"&]+).*?".*?>(.+?)<\/a>/m do |match|
      url, title = match
      title.gsub!( /<.+?>/, "" )
      ua = query.gsub( /-?site:\S+/, '' ).strip
      answer = "[#{ua}]: #{url} - #{title}"
    end
    answer
  #rescue
  #  "No results found"
  end

  def self.search(query)
    f = open( "https://www.google.com/search?q=#{ CGI.escape( query ) }&safe=active" )
    html = f.read
    f.close
    html
  end

  def result_count(query, html=nil)
    html ||= self.class.search(query)
    doc = Nokogiri::HTML html
    doc.css("#subform_ctrl > div:last").text.gsub(",", "").gsub(".", "").scan(/\d+/).first.to_i
  end

  def fight(a, b)
    count1 = self.result_count(a)
    count2 = self.result_count(b)
    ratio1 = ( count2 != 0 ) ? count1.to_f / count2 : 99
    ratio2 = ( count1 != 0 ) ? count2.to_f / count1 : 99
    ratio = [ ratio1, ratio2 ].max
    verb = GOOGLEFIGHT_VERBS.find { |x| ratio > x[ 0 ] }[ 1 ]
    c1 = number_with_delimiter count1 
    c2 = number_with_delimiter count2 

    if count1 > count2
      msg = "#{a} #{verb} #{b}! (#{c1} to #{c2})"
    else
      msg = "#{b} #{verb} #{a}! (#{c2} to #{c1})"
    end
    msg
  rescue
    "#{a} and #{b} are too difficult even for Google!"
  end

  def number_with_delimiter( number, delimiter = ',' )
      number.to_s.gsub( /(\d)(?=(\d\d\d)+(?!\d))/, "\\1#{delimiter}" )
  end

  match /google (.+)/, method: :google
  def google(m, query)
    m.reply search(query)
  end

  match /g(?:oogle)?f(?:ight)? ([^,]+) (?:vs\.?|,) ([^,]+)/, method: :google_fight
  match /g(?:oogle)?f(?:ight)? ([^ ]+) ([^ ]+)/, method: :google_fight
  def google_fight(m, a, b)
    return if b.start_with?("vs") || b == ","
    m.reply self.fight(a ,b)
  end
end
