require "http/client"

require "framework/plugin"

class WhatTheCommit
  include Framework::Plugin

  match /^!commit/
  def execute(msg, match)
    msg.reply HTTP::Client.get("http://whatthecommit.com/index.txt").body
  rescue
    msg.reply "I broke this"
  end
end
