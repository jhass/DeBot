require "spec"
require "../src/irc/message"

private def parses(raw, prefix, type, parameters)
  it "parses #{raw.inspect}" do
    message = IRC::Message.from raw
    message.should_not be_nil
    if message
      message.prefix.should eq prefix
      message.type.should eq type
      message.parameters.should eq parameters
    end
  end
end

describe IRC::Message do
  describe ".from" do
    parses "PRIVMSG ##cebot :foo bar",
            nil, IRC::Message::PRIVMSG, ["##cebot", "foo bar"]
    parses ":wilhelm.freenode.net 005 cebot CASEMAPPING=rfc1459 CHARSET=ascii NICKLEN=16 CHANNELLEN=50 TOPICLEN=390 ETRACE CPRIVMSG CNOTICE DEAF=D MONITOR=100 FNC TARGMAX=NAMES:1,LIST:1,KICK:1,WHOIS:1,PRIVMSG:4,NOTICE:4,ACCEPT:,MONITOR: :are supported by this server\r\n",
           "wilhelm.freenode.net", IRC::Message::ISUPPORT, ["cebot", "CASEMAPPING=rfc1459", "CHARSET=ascii", "NICKLEN=16", "CHANNELLEN=50", "TOPICLEN=390", "ETRACE", "CPRIVMSG", "CNOTICE", "DEAF=D", "MONITOR=100", "FNC", "TARGMAX=NAMES:1,LIST:1,KICK:1,WHOIS:1,PRIVMSG:4,NOTICE:4,ACCEPT:,MONITOR:", "are supported by this server"]
    parses "000 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 with spaces\r\n",
            nil, "000", ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15 with spaces"]
    parses "000 1 2 3 4 5 6 7 8 9 10 11 12 13 14 :15 with: spaces\n",
           nil, "000", ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15 with: spaces"]
    parses ":jhass!~jhass@jhass.eu MODE ##cebot +r",
           "jhass!~jhass@jhass.eu", IRC::Message::MODE, ["##cebot", "+r"]
    # Not RFC valid but Freenode sends it with a trailing space
    parses ":jhass!~jhass@jhass.eu MODE ##cebot +r ",
           "jhass!~jhass@jhass.eu", IRC::Message::MODE, ["##cebot", "+r"]
    parses ":jhass!jhass@000:0::1 PRIVMSG ##cebot :!roul",
           "jhass!jhass@000:0::1", IRC::Message::PRIVMSG, ["##cebot", "!roul"]
  end
end
