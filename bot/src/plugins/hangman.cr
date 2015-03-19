require "framework/plugin"

class Hangman
  include Framework::Plugin

  class Game
    def self.word_list_for name
       File.read_lines(File.join(__DIR__, "..", "..", "res", name)).map(&.chomp.downcase)
    end

    WORDLISTS = {
      "nouns" => word_list_for("wordlist"),
      "gems"  => word_list_for("gem_names")
    }

    DEFAULT_LIST = "nouns"

    def initialize list=DEFAULT_LIST
      @word = pick_word list
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

    private def pick_word list
      WORDLISTS[list].sample.chars
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
    when /^!hangman\s+\w+$/
      _c, list = command.split
      start_game msg, list
    when /^!hangman$/
      start_game msg, Game::DEFAULT_LIST
    when /^[a-zA-Z]$/
      guess msg, command.downcase.char_at(0)
    end
  end

  def start_game msg, list
    unless @@games.has_key? msg.channel.name
      @@games[msg.channel.name] = Game.new list
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
