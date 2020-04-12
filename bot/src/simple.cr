require "framework/bot"
require "framework/plugin"

class HelloWorld
  include Framework::Plugin

  match /!hello_world/

  def execute(msg, match)
    msg.reply "Hi #{msg.sender.nick}!"
  end
end

bot = Framework::Bot.create do
  config.server = "chat.freenode.net"
  config.nick = "CrystalBot"
  config.channels = ["##cebot"]

  add_plugin HelloWorld
end

bot.start
