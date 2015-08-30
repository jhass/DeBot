require "http/client"

require "framework/plugin"

class ProgrammingExcuses
  include Framework::Plugin

  match /^!excuse/
  def execute m, _match
    html = HTTP::Client.get("http://programmingexcuses.com/").body
    excuse = html[/<center[^>]+><a[^>]+>([^<]+)</, 1]
    m.reply excuse
  end
end
