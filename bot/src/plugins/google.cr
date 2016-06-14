require "http/client"

require "framework/plugin"

class Google
  include Framework::Plugin

  GOOGLEFIGHT_VERBS = [
      {1000.0, "completely DEMOLISHES"},
      {100.0, "utterly destroys"},
      {10.0, "destroys"},
      {5.0, "demolishes"},
      {3.0, "crushes"},
      {2.0, "shames"},
      {1.2, "beats"},
      {1.0, "barely beats"},
  ]

  match /^!(g)(?:oogle)?\s+(.+)/
  match /^!(gf)\s+([^,]+)\s+(?:vs\.?|,)\s+([^,]+)/
  match /^!(gf)\s+([^ ]+)\s+([^ ]+)/

  def execute(msg, match)
    if match[1] == "g"
      msg.reply search(match[2])
    elsif match[1] == "gf"
      msg.reply fight(match[2], match[3])
    end
  end

  def search(query)
    html = query query
    ua = query.gsub(/-?site:\S+/, "").strip
    if match = html.match /<a href="?\/url\?q=([^"&]+).*?".*?>(.+?)<\/a>/m
      url, title = match[1], match[2]
      title = title.delete(/<.+?>/)
      "[#{ua}]: #{url} - #{title}"
    else
      "[#{ua}]: No results found."
    end
  rescue e
    "[#{ua}]: No results found!"
  end

  def query(query)
    fetch "https://www.google.com/search?q=#{URI.escape(query)}&safe=none&ie=utf-8&oe=utf-8&hl=en"
  end

  def fetch(url, redirect_limit=10)
    resp = HTTP::Client.get(
      url,
      HTTP::Headers {
        "User-Agent" => "Lynx/2.8.7rel.2 libwww-FM/2.14 SSL-MM/1.4.1 OpenSSL/1.0.0a",
        "Accept-Language" => "en"
      }
    )

    if (300 <= resp.status_code < 400) && resp.headers["Location"]?
      return "" if redirect_limit == 1
      return fetch(resp.headers["Location"], redirect_limit-1)
    else
      resp.body
    end
  end

  def fight(a, b)
    count1 = result_count a
    count2 = result_count b
    ratio1 = count2 != 0 ? count1.fdiv(count2) : 99
    ratio2 = count1 != 0 ? count2.fdiv(count1) : 99
    ratio = [ratio1, ratio2].max
    verb = GOOGLEFIGHT_VERBS.find {|x| ratio > x[0] }.not_nil![1]
    c1 = number_with_delimiter count1
    c2 = number_with_delimiter count2

    if count1 > count2
      msg = "#{a} #{verb} #{b}! (#{c1} to #{c2})"
    else
      msg = "#{b} #{verb} #{a}! (#{c2} to #{c1})"
    end
    msg
  rescue
    "#{a} and #{b} are too difficult even for Google!"
  end

  def result_count(query)
    html = query query
    html[/About ([\d\.,]+) results/, 1].delete(/[,\.]/).to_u64
  end

  def number_with_delimiter(number, delimiter=',')
    number.to_s.gsub(/(\d)(?=(\d\d\d)+(?!\d))/) {|_s, match| "#{match[1]}#{delimiter}" }
  end
end
