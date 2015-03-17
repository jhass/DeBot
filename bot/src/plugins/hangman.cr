require "framework/plugin"

class Hangman
  include Framework::Plugin

  class Game
    WORDLIST = File.read_lines(File.join(__DIR__, "..", "..", "res", "wordlist")).map(&.chomp.upcase)

    def initialize
      @word = pick_word
      @guesses = [] of Char
    end

    def status
      String.build do |io|
        io << current_word
        io << " [#{wrong_guesses.join}]"
        io << " #{wrong_guesses.size}/12"
        io << " You won!" if won?
        io << " You lost!" if lost?
      end
    end

    def current_word
      return @word.join if lost?
      known_chars
    end

    def known_chars
      @word.map {|char|
        @guesses.includes?(char) ? char : '_'
      }.join
    end

    def wrong_guesses
      @guesses-@word
    end

    def guess guess
      @guesses << guess unless @guesses.includes? guess
    end

    def lost?
      wrong_guesses.size >= 12
    end

    def won?
      !known_chars.includes?('_')
    end

    def over?
      lost? || won?
    end

    private def pick_word
      WORDLIST.sample.chars
    end
  end

  @@games = {} of String => Game

  listen :message

  def react_to event
    msg = event.message
    return unless msg.channel?
    message = msg.message
    return unless message.starts_with? bot.nick
    command = message.gsub(/^#{bot.nick}[:,\s]*/, "")

    case command
    when "!hangman"
      start_game msg
    when /^[a-zA-Z]$/
      guess msg, command.upcase.char_at(0)
    end
  end

  def start_game msg
    unless @@games.has_key? msg.channel.name
      @@games[msg.channel.name] = Game.new
    end

    msg.reply @@games[msg.channel.name].status
  end

  def guess msg, guess
    return unless @@games.has_key? msg.channel.name

    game = @@games[msg.channel.name]
    game.guess guess
    msg.reply game.status
    @@games.delete(msg.channel.name) if game.over?
  end
end
