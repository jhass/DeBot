require "http/client"

require "framework/plugin"
require "core_ext/process"

class CrystalEval
  include Framework::Plugin

  class Request
    json_mapping({
      run: Run
    })
  end

  class Run
    json_mapping({
      stdout:     String,
      stderr:     String,
      exit_code:  Int32,
      html_url:   String
    })
  end

  TEMPLATE = <<-END
begin;
__expr__ = begin

%s

end
puts "\n# => #{__expr__.inspect}"
rescue e
  puts "#{e.class}: #{e.message}"
  puts e.backtrace.join("\n")
end
END

  match /^>>\s*(.+)/

  def execute msg, match
    source = TEMPLATE % [match[1]]

    run = Request.from_json((JSON.parse(
      HTTP::Client.post(
        "http://carc.in/run_requests",
        HTTP::Headers {"Content-Type" => "application/json; charset=utf8"},
        {
          run_request: {
            language: "crystal",
            code: source
          }
        }.to_json
      ).body
    ) as Hash(String, JSON::Type))["run_request"].to_json).run

    output = run.stdout
    stderr = run.stderr
    success = run.exit_code == 0

    if stderr && !stderr.strip.empty?
      playpen, crystal = separate_playpen stderr
      reply = crystal.last?
      reply = "Sorry, that took too long." if playpen.includes?("playpen: timeout triggered!")
    end

    if reply.nil? && output && !output.strip.empty?
      reply = success ? output.lines.find {|line| !line.strip.empty? } : find_error_message(output)
    elsif success
      reply ||= output # Return the empty string
    end

    reply ||= "Failed to run your code, sorry!"

    reply = strip_ansi_codes reply
    reply = prettify_error reply
    reply = limit_size reply

    msg.reply "#{msg.sender.nick}: #{reply} - #{"more at " if success && output.lines.size > 2}#{run.html_url}"
  end

  def separate_playpen stderr
    stderr.lines.reject(&.strip.empty?).partition &.starts_with?("playpen:")
  end

  def find_error_message output
    lines = output.lines.reject(&.strip.empty?)

    # Compiler bug
    bug = lines.find {|line| line.starts_with?("Bug:") }
    return bug if bug

    # Find syntax error in macro expansion
    if separator = lines.find {|line| line =~ /^-+$/ }
      if index = lines.rindex(separator)
        return lines[index+1]
      end
    end

    # Rip out any type traces
    if separator = lines.find {|line| line =~ /^[=]+$/ }
      if index = lines.index(separator)
        lines = lines[0..index]
      end
    end

    # Syntax error
    syntax = lines.find {|line| line.includes?("Syntax error") }
    return syntax if syntax

    # Check if we got a traceback
    traces = lines.select {|line|
      line =~ /\/[\.\w]+:\d+:\s/ ||
      line =~ /in line \d+:/ ||
      line =~ /in macro/
    }

    unless traces.empty?
      line = traces.last
      if line.includes?("in macro")
        return "#{line} #{lines.last}"
      else
        return line
      end
    end

    # No traceback, first line that starts with "Error" then
    lines.find &.starts_with?("Error")
  end

  def strip_ansi_codes text
    text.gsub(/\e\[(?:\d\d;)?[01]m/, "")
  end

  def prettify_error text
    if text.includes?("Bad system call") || text.includes?(": 31")
      "Sorry, I can't let you do that."
    else
      text
    end
  end

  def limit_size text, limit=350
    text.size > limit ? "#{text[0, limit]} ..." : text
  end
end
