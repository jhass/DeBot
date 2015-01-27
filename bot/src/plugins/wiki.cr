require "core_ext/string"
require "framework/plugin"

class Wiki
  include Framework::Plugin

  def initialize @wikis : Hash(String, String)
  end

  match /^!wiki\s+(.+)/

  def execute msg, match
    return unless msg.channel?
    return unless @wikis.has_key? msg.channel.name
    title = match[1].squeeze(" ").strip.tr(" ", "_").capitalize
    msg.reply "#{@wikis[msg.channel.name]}#{title}"
  end
end
