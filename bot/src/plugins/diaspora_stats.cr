require "http/client"
require "json"

require "core_ext/array"

require "framework/plugin"


class DiasporaStats
  class Graph
    class Datapoint
      json_mapping({
        x: {type: Int32},
        y: {type: Int32}
      })
    end

    json_mapping({
      name: {type: String},
      color: {type: String},
      renderer: {type: String},
      data: {type: Array(Datapoint)}
    })
  end

  include Framework::Plugin

  match /^!dstats/

  def execute msg, _match
    json = HTTP::Client.get("http://pods.jasonrobinson.me/stats/global").body
    statistics = Array(Graph).from_json json
    statistics = {
      "Active users 1 month" => :last_month,
      "Active users 6 months" => :six_months,
      "Total posts" => :posts,
      "Total users" => :users
    }.map {|name, key|
      {key, statistics.find {|graph| graph.name == name }.not_nil!.data.last.y}
    }.to_h
    msg.reply "diaspora* approximately had #{statistics[:last_month]} active users in the last 30 days and #{statistics[:six_months]} active users in the last 180 days."
  rescue
    msg.reply "Sorry, couldn't obtain statistics."
  end
end
