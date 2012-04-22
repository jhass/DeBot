require 'active_support'
require 'feedzirra'

class Feeds
  include Cinch::Plugin

  def initialize(*args)
    super
    @@feeds = {}
    config.each do |feed, options|
     if options['interval'] && options['channels']
       @@feeds[feed] = Feedzirra::Feed.fetch_and_parse feed
       Timer(options['interval']) { check_feed(feed, options['channels']) }
     end
    end
  end

  def check_feed(feed, channels)
   channels = channels.map { |channel|
     Channel(channel) if bot.channels.include?(channel)
   }.compact

   return if channels.empty?

   synchronize(:feeds) do
     updated = Feedzirra::Feed.update @@feeds[feed]
     @@feeds[feed].update_from_feed updated
     new_entries = @@feeds[feed].new_entries
     updated.new_entries = []
     @@feeds[feed] = updated
     
     new_entries.each do |entry|
       channels.each do |channel|
         author = "<#{entry.author}>" unless entry.author.strip.empty?
         channel.send "[feed] #{author} #{entry.title} - #{entry.url}".gsub("\n", "")
       end
     end
   end
 end
end


     
