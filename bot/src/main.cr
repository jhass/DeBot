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
require "./plugins/wiki"
require "./plugins/russian_roulette"
require "./plugins/memo"

bot = Framework::Bot.create do
  config.server   = "chat.freenode.net"
  config.user     = "cebot"
  config.nick     = "CeBot"
  config.channels = {"#cebot"}

  add_plugin Google
  add_plugin DownForEveryone
  add_plugin HelloWorld,      whitelist: ["#cebot"]
  add_plugin DiasporaVersion, whitelist: ["#cebot", "#diaspora-de", "#diaspora", "#diaspora-dev"]
  add_plugin DiasporaStats,   whitelist: ["#cebot", "#diaspora-de", "#diaspora", "#diaspora-dev"]
  add_plugin CrystalEval,     whitelist: ["#cebot", "#diaspora-de", "#crystal-lang"]
  add_plugin Password,        whitelist: ["#cebot", "#diaspora-de", "#diaspora", "#diaspora-dev"]
  add_plugin WhatTheCommit,   whitelist: ["#cebot", "#diaspora-de", "#diaspora", "#diaspora-dev"]
  add_plugin RussianRoulette,   whitelist: ["#cebot", "#diaspora-de", "#diaspora", "#diaspora-dev"]
  add_plugin Admin, arguments: [{"jhass"}]
  add_plugin KeyValueStore, arguments: ["data/key_value_store.json"]
  add_plugin Memo, arguments: ["data/memo.json"]
  add_plugin(GithubIssues, arguments: [{
      "#diaspora"     => "diaspora/diaspora",
      "#diaspora-dev" => "diaspora/diaspora",
      "#diaspora-de"  => "diaspora/diaspora",
      "#diaspora-fr"  => "diaspora/diaspora",
      "#cebot"        => "jhass/CeBot"
  }])
  add_plugin(Wiki, arguments: [{
      "#diaspora"     => "https://wiki.diasporafoundation.org/",
      "#diaspora-de"  => "https://wiki.diasporafoundation.org/",
      "#diaspora-dev" => "https://wiki.diasporafoundation.org/"
  }])
end

bot.start
