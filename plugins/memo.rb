class Memo
  class MemoStruct < Struct.new(:user, :channel, :text, :time)
    def to_s
      "[#{time.asctime}] <#{channel}/#{user}> #{text}"
    end
  end

  include Cinch::Plugin
  attr_reader :storage

  def initialize(*args)
    super
    @storage  = bot.config.storage.backend.new(@bot.config.storage, self)
    storage[:memos] ||= {}
  end

  set(plugin_name: "memo",
      help: "Usage: !memo nick message")

  listen_to :message
  listen_to :join
  listen_to :nick
  match /memo\s+([^ ]+?)\s+(.+)/

  def listen(m)
    storage[:memos].each do |key, memo|
      rexp = Regexp.new $1 if key =~ %r{^/(.+)/$}
      next unless key == m.user.nick || (rexp && m.user.nick =~ rexp)
      storage[:memos][key].each do |memo|
        m.user.send memo.to_s
      end
      storage[:memos].delete(key)
      storage.save
    end
  end

  def execute(m, nick, message)
    if nick == m.user.nick
      m.reply "#{m.user.nick}: You can't leave memos for yourself.."
    elsif nick == bot.nick
      m.reply "#{m.user.nick}: You can't leave memos for me.."
    else
      storage[:memos][nick] ||=  []
      storage[:memos][nick] << MemoStruct.new(m.user.name, m.channel.name, message, Time.now)
      storage.save
      m.reply "#{m.user.nick}: Added memo for #{nick}"
    end
  end
end
