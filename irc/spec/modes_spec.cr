require "spec"
require "../src/irc/modes"

def parse(modes)
  parsed = Array({Char, Char, String?}).new
  IRC::Modes::Parser.parse(modes) do |modifier, flag, parameter|
    parsed << {modifier, flag, parameter.as String?}
  end
  parsed
end

describe IRC::Modes::Parser do
  it "correctly parses mode lines" do
    parse("+t").should eq([{'+', 't', nil}])
    parse("-t").should eq([{'-', 't', nil}])
    parse("+v foo").should eq([{'+', 'v', "foo"}])
    parse("-v foo").should eq([{'-', 'v', "foo"}])
    parse("+t-v foo").should eq([{'+', 't', nil}, {'-', 'v', "foo"}])
    parse("+vo foo bar").should eq([{'+', 'v', "foo"}, {'+', 'o', "bar"}])
    parse("-vo foo bar").should eq([{'-', 'v', "foo"}, {'-', 'o', "bar"}])
    parse("-tvo foo bar").should eq([{'-', 't', nil}, {'-', 'v', "foo"}, {'-', 'o', "bar"}])
    parse("+vo-b foo bar baz").should eq([{'+', 'v', "foo"}, {'+', 'o', "bar"}, {'-', 'b', "baz"}])
  end
end
