require "core_ext/string"
require "framework/plugin"

class Wiki
  include Framework::Plugin

  config({
    wikis: {type: Hash(String, String), default: {} of String => String}
  })

  match /^!wiki\s+(.+)/

  def execute(msg, match)
    return unless msg.channel?
    return unless config.wikis.has_key? msg.channel.name
    title = match[1].squeeze(" ").strip.tr(" ", "_").capitalize
    msg.reply "#{config.wikis[msg.channel.name]}#{title}"
  end
end
