require "json"

require "framework/plugin"
require "framework/json_store"

class Memo
  class Memo
    json_mapping({
      content: {type: String},
      sender: {type: String},
      context: {type: String, nilable: true, emit_null: true},
      timestamp: {type: Time, converter: TimeFormat.new("%F %T")}
    })

    def initialize @content, @sender : String, @context : String?, @timestamp : Time
    end

    def to_s io
      io << @timestamp.to_s("%D %R") << ' ' << @sender
      io << " (" << context << ")" if context = @context
      io << ": " << @content
    end
  end

  include Framework::Plugin

  config({
    store: {type: String}
  })

  def self.config_loaded config
    @@memos = Framework::JsonStore(String, Array(Memo)).new config.store
  end

  def memos
    @@memos.not_nil!
  end

  listen :join
  listen :nick
  listen :message

  def react_to event
    deliver_memos event.sender
  end

  match /^!memo\s+([^ ]+?)\s+(.+)/

  def execute msg, match
    nick = match[1]

    if nick == msg.sender.nick
      msg.reply "#{msg.sender.nick}: You can't leave memos for yourself.."
    elsif nick == bot.nick
      msg.reply "#{msg.sender.nick}: You can't leave memos for me.."
    else
      store_memo match[2], msg.sender.nick, nick, msg.channel?.try(&.name)
      msg.reply "#{msg.sender.nick}: Added memo for #{nick}."
    end
  end

  def deliver_memos user
    chosen_keys = Set(String).new

    memos.keys.select {|key|
      key == user.nick || (key.starts_with?('/') && key.ends_with?('/'))
    }.each do |key|
      regex = key.starts_with?('/') ? key[1..-2] : Regex.escape(key)
      regex = Regex.new regex rescue nil

      if regex && user.nick.match(regex)
        memos.fetch(key) do |memos|
          next unless memos
          memos.each do |memo|
            chosen_keys << key
            user.send memo.to_s
          end
        end
      end
    end

    chosen_keys.each do |key|
      memos.modify(key) do |memos|
        memos ||= [] of Memo
        memos.clear
        memos
      end
    end
  end

  def store_memo content, from, to, at=nil
    memos.modify(to) do |memos|
      memos ||= [] of Memo
      memos << Memo.new(content, from, at, Time.now)
    end
  end
end
