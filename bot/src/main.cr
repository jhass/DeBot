require "framework/bot"
require "./plugins/hello_world"
require "./plugins/key_value_store"
require "./plugins/diaspora_version"
require "./plugins/crystal_eval"
require "./plugins/admin"
require "./plugins/google"
require "./plugins/diaspora_stats"
require "./plugins/down_for_everyone"
require "./plugins/github_issues"
require "./plugins/password"
require "./plugins/what_the_commit"

bot = Framework::Bot.create do |config|
  config.server   = "chat.freenode.net"
  config.port     = 6667
  config.user     = "cebot"
  config.nick     = "CeBot"
  config.channels = {"#cebot"}

  config.add_plugin Google.new
  config.add_plugin DownForEveryone.new
  config.add_plugin HelloWorld.new,      ["#cebot"]
  config.add_plugin DiasporaVersion.new, ["#cebot", "#diaspora-de", "#diaspora", "#diaspora-dev"]
  config.add_plugin DiasporaStats.new,   ["#cebot", "#diaspora-de", "#diaspora", "#diaspora-dev"]
  config.add_plugin CrystalEval.new,     ["#cebot", "#diaspora-de", "#crystal-lang"]
  config.add_plugin Password.new,        ["#cebot", "#diaspora-de", "#diaspora", "#diaspora-dev"]
  config.add_plugin WhatTheCommit.new,   ["#cebot", "#diaspora-de", "#diaspora", "#diaspora-dev"]
  config.add_plugin Admin.new({"jhass"})
  config.add_plugin KeyValueStore.new("data/key_value_store.json")
  config.add_plugin GithubIssues.new({
    "#diaspora"     => "diaspora/diaspora",
    "#diaspora-dev" => "diaspora/diaspora",
    "#diaspora-de"  => "diaspora/diaspora",
    "#diaspora-fr"  => "diaspora/diaspora",
    "#cebot"        => "jhass/CeBot"
  })
end

bot.start
