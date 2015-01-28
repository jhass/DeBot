require "framework/plugin"
require "framework/json_store"

# nickname   =  ( letter / special ) *8( letter / digit / special / "-" )
# letter = [a-zA-Z]
# special = [\[\]\\`_^{}|]
# digit = \d
# [\w\[\]\\`^{}|][\w\[\]\\`^{}|\d\-]{0,8}

class KeyValueStore
  include Framework::Plugin

  def initialize path : String
    @store = Framework::JsonStore(String, Hash(String, String)).new path
  end

  match /^!(keys)\s+(#[^ ]+)?/
  match /^\?((?:[^\s=]+))\s*([\w\[\]\\`\^\{\}\|][\w\[\]\\`\^\{\}|\d\-]{0,8})?\s*$/
  match /^\?((?:[^\s=]+)=)(.+)/

  def execute msg, match
    if match[1] == "keys"
      channel = match[2] unless match[2].empty?
      channel ||= msg.channel.name if msg.channel?
      return unless channel

      msg.reply "I know the following keys: #{known_keys(channel).join(", ")}"
    else
      return unless msg.channel?

      if match[1].ends_with? '='
        key = match[1][0..-2]
        set_key msg.channel.name, key, match[2]
        msg.reply "#{msg.sender.nick}: Set #{key}."
      else
        content = get_key msg.channel.name, match[1]
        if content
          prefix = "#{match[2]}: " unless match[2].empty?
          msg.reply "#{prefix}#{content}"
        else
          msg.reply "#{msg.sender.nick}: Nothing known about #{match[1]}."
        end
      end
    end
  end

  def known_keys channel
    @store.fetch(channel) do |data|
      data ? data.keys : Tuple.new
    end
  end

  def set_key channel, key, value
    @store.modify(channel) do |data|
      data ||= Hash(String, String).new
      data[key] = value
      data
    end
  end

  def get_key channel, key
    @store.fetch(channel) do |data|
      data && data[key]?
    end
  end
end
