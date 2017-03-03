require "http/client"

require "framework/plugin"

class CrystalEval
  include Framework::Plugin

  class Request
    JSON.mapping({
      run: Run
    })
  end

  class Run
    JSON.mapping({
      stdout:     String,
      stderr:     String,
      exit_code:  Int32,
      html_url:   String
    })
  end

  TEMPLATE_PLACEHOLDER = "%body"
  TEMPLATE = <<-END
macro __wrap_last_expression(exprs)
  {% for expression in exprs.expressions[0..-2] %}
    {{expression}}
  {% end %}
  {% if %w[Def FunDef Macro ClassDef LibDef].includes? exprs.expressions.last.class_name %}
    {{exprs.expressions.last}}
    puts "#=> nil"
  {% else %}
    %expr = begin
      {{exprs.expressions.last}}
    end
    puts "\\n# => \#{ %expr.inspect}"
  {% end %}
end

__wrap_last_expression begin; nil
  #{TEMPLATE_PLACEHOLDER}
end
END

  match /^>>\s*(.+)/

  def execute(msg, match)
    source = TEMPLATE.sub(TEMPLATE_PLACEHOLDER, match[1])

    run = Request.from_json((JSON.parse(
      HTTP::Client.post(
        "https://carc.in/run_requests",
        HTTP::Headers {"Content-Type" => "application/json; charset=utf8"},
        {
          run_request: {
            language: "crystal",
            code: source
          }
        }.to_json
      ).body
    ))["run_request"].to_json).run

    output = run.stdout
    stderr = run.stderr
    success = run.exit_code == 0

    if stderr && !stderr.strip.empty?
      playpen, crystal = separate_playpen stderr
      reply = crystal.last?

      # Exception?
      reply = crystal.first if reply && reply.match(/^\[\d+\]/)

      reply = "Sorry, that took too long." if playpen.includes?("playpen: timeout triggered!")
    end

    if reply.nil? && output && !output.strip.empty?
      reply = success ? output.lines.find {|line| !line.strip.empty? } :
                        filter_wrapper_macro(find_error_message(output))
    elsif success
      reply ||= output # Return the empty string
    end

    reply ||= "Failed to run your code, sorry!"

    reply = strip_ansi_codes reply
    reply = prettify_error reply
    reply = limit_size reply

    msg.reply "#{msg.sender.nick}: #{reply.chomp} - #{"more at " if success && output.lines.size > 2}#{run.html_url}"
  end

  def separate_playpen(stderr)
    stderr.lines.reject(&.strip.empty?).partition &.starts_with?("playpen:")
  end

  def find_error_message(output)
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

    # Overload listing? Error is before that
    if index = lines.index {|line| line.starts_with? "Overloads are:" }
      return lines[index-1]
    end

    # Rip out any type traces
    if separator = lines.find {|line| line =~ /^=+$/ }
      if index = lines.index(separator)
        lines = lines[0...index]
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

  def filter_wrapper_macro(error)
    error && error.lines.reject {|e|
      e.includes?("in macro '__wrap_last_expression'")
    }.join(" ")
  end

  def strip_ansi_codes(text)
    text.gsub(/\e\[(?:\d\d;)?[01]m/, "")
  end

  def prettify_error(text)
    if text.includes?("Bad system call") || text.includes?(": 31")
      "Sorry, I can't let you do that."
    else
      text
    end
  end

  def limit_size(text, limit=350)
    text.size > limit ? "#{text[0, limit]} ..." : text
  end
end
