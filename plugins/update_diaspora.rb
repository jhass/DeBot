require 'open-uri'
require 'nokogiri'

class UpdateDiaspora
  include Cinch::Plugin

  set(:plugin_name => "oktoupdate",
      :help => "Usage: !oktoupdate - Pulls the info of http://isitoktoupdatemydiaspora.tk right into the channel")
  
  match /(?:isit)?(?:safe|ok|okay)to(?:update|pull)(?:my)?(?:diaspora)?/

  def execute(m)
    open 'http://isitoktoupdatemydiaspora.tk/' do |io|
      n = Nokogiri::HTML(io)
      mesg = n.css('#content > h1:first').text.strip
      exp = n.css('#explanation').text.gsub('Explanation:', '').strip
      date = n.css('#updated').text.strip
      unless exp.empty?
        m.reply "#{mesg} - #{exp} - #{date}"
      else
        m.reply "#{mesg} - #{date}"
      end
    end
  rescue
    m.reply  "Sorry, couldn't parse or read http://isitoktoupdatemydiaspora.tk/"
  end
end
