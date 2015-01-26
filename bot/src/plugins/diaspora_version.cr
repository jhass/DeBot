require "http/client"

require "framework/plugin"

class DiasporaVersion
  include Framework::Plugin

  API_ENDPOINT = "http://version.diaspora.social/%s/text"

  match /^!rev\s+([a-zA-Z0-9]+[a-zA-Z0-9\-]*\.[a-zA-Z\.]+)/

  def execute msg, match
    resp = HTTP::Client.exec "GET", API_ENDPOINT % [match[1]]
    msg.reply resp.body
  end
end
