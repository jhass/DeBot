require "framework/plugin"

class HelloWorld
  include Framework::Plugin

  match /!hello_world/
  def execute(msg, match)
    msg.reply "Hi #{msg.sender.nick}!"
  end
end
