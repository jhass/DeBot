require "http/client"

require "framework/plugin"

class WhatTheCommit
  include Framework::Plugin

  match /^!commit/
  def execute msg, match
    html = HTTP::Client.get("http://whatthecommit.com/").body
    msg.reply html[/<p>([^<\n]+)/, 1]
  rescue
    msg.reply "I broke this"
  end
end
