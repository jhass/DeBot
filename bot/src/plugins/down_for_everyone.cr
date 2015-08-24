require "http/client"

require "core_ext/string"
require "framework/plugin"

class DownForEveryone
  include Framework::Plugin

  match /^!(?:down|up)\s+(?:(https?):\/\/?)?(\S+)/

  def execute msg, match
    scheme = match[1]? || "http"
    uri = URI.parse "#{scheme}://#{match[2]}"
    url = "#{uri.scheme}://#{uri.host}"
    body = HTTP::Client.get("http://downforeveryoneorjustme.com/#{uri.host}").body
    if body.includes?("It's just you")
      msg.reply "It's just you. #{url} is up"
    else
      msg.reply "#{url} looks down from here too!"
    end
  end
end
