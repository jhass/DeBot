# encoding: utf-8
require 'cinch'
require 'cinch/configuration/storage'
require 'cinch/storage/yaml'

require './lib/settings'
require './lib/plugin_manager'

bot = Cinch::Bot.new do
  @plugins = PluginManager.new(self)

  configure do |c|
    c.nick = settings.nick
    c.realname = settings.nick
    c.user = settings.nick.downcase
    c.server = settings.server
    c.port = settings.port
    c.channels = settings.channels

    c.storage = Cinch::Configuration::Storage.new
    c.storage.backend = Cinch::Storage::YAML
    c.storage.basedir = "./yaml/"
    c.storage.autosave = true
  end

  on :message, /^DeBot\s?[:,].+/ do |msg|
    sleep 2
    msg.reply "#{msg.user.nick}"
    sleep 2
    msg.reply "You're talking to a bot."
  end
end



if settings.identify.enabled
  bot.plugins.load_plugin :identify, :require => 'cinch/plugins/identify', :class => 'Cinch::Plugins::Identify',
    :username => settings.nick,
    :password => settings.identify.password,
    :type => settings.identify.type
end

if settings.admins && settings.admins.any?
  bot.plugins.load_plugin :bot_utils,
    :admins => settings.admins,
    :superadmin => settings.superadmin
end

bot.plugins.load_plugin :down_for_everyone,
  :require => 'cinch/plugins/downforeveryone',
  :class => 'Cinch::Plugins::DownForEveryone',
  :patch => './plugins/down_for_everyone.rb'
bot.plugins.load_plugin :title,
  :require => 'cinch/plugins/title',
  :class => 'Cinch::Plugins::Title',
  :patch => './plugins/title.rb'
bot.plugins.load_plugin :fortune,
  :require => 'cinch/plugins/fortune',
  :class => 'Cinch::Plugins::Fortune'

bot.plugins.load_plugin :feeds, (settings.feeds || {})

bot.plugins.load_plugins([
  :google,
  :memo,
  :key_value_store,
  :translation_status,
  :update_diaspora,
  :pod_updated,
  :what_the_commit,
  :russian_roulette,
  :meme,
  :password,
  :wiki,
  :issues
])


#bot.loggers.level = :info

bot.start
