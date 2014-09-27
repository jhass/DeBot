require 'json'
require 'open-uri'

class DiasporaStats
  include Cinch::Plugin

  set(plugin_name: "diaspora_stats",
      help: "!dstats - print diaspora usage statistics")

  match /dstats/
  def execute(m)
    statistics = JSON.parse open("http://pods.jasonrobinson.me/stats/global", &:read)
    statistics = {
      "Active users 1 month" => :last_month,
      "Active users 6 months" => :six_months,
      "Total posts" => :posts,
      "Total users" => :users
    }.map {|name, key|
      [key, statistics.find {|graph| graph['name'] == name }["data"].last["y"]]
    }.to_h
    m.reply "diaspora* approximately had #{statistics[:last_month]} active users in the last 30 days and #{statistics[:six_months]} active users in the last 180 days."
  rescue
    m.reply "Sorry, couldn't obtain statistics."
  end
end
