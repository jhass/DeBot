require 'open-uri'
require 'nokogiri'
require 'uri'

class PodUpdated
  include Cinch::Plugin

  set(plugin_name: "rev",
      help: "Usage: !rev diaspora.example.org - Try to guess which version the specified Diaspora pod runs on")

  match /rev (.+)/

  def execute(m, url)
    url = "http://#{url}" unless url.start_with?("http")
    uri = URI.parse url
    open "http://podversion.tk/?domain=#{uri.host}&plain" do |io|
      n = Nokogiri::HTML(io)
      m.reply n.css('p').text.strip
    end
  rescue
    m.reply "Sorry, an error occured while processing #{url}"
  end
end
