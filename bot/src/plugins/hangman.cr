require "framework/plugin"
require "framework/limiter"

class Hangman
  include Framework::Plugin

  class Game
    def self.word_list_for name
       File.read_lines(File.join(__DIR__, "..", "..", "res", name)).map(&.chomp)
    end

    WORDLISTS = {
      "brainfuck"  => word_list_for("brainfuck"),
      "c"          => word_list_for("glibc_functions"),
      "codepoints" => word_list_for("unicode_codepoint_names"),
      "crystal"    => word_list_for("crystal"),
      "distros"    => word_list_for("distros"),
      "french"     => word_list_for("wordlist_fr"),
      "gems"       => word_list_for("gem_names"),
      "german"     => word_list_for("wordlist_de"),
      "haskell"    => word_list_for("haskell"),
      "java"       => word_list_for("java_classes"),
      "nouns"      => word_list_for("wordlist"),
      "perl"       => word_list_for("perl"),
      "php"        => word_list_for("php"),
      "ruby"       => word_list_for("ruby")
    }

    DEFAULT_LIST = "nouns"
    PLACEHOLDER  = '␣'

    def initialize list=DEFAULT_LIST
      @word = pick_word list
      @guesses = [] of Char|String
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
        @guesses.includes?(char.downcase) ? char : PLACEHOLDER
      }.join
    end

    def wrong_guesses
      @guesses-@word.map(&.downcase)
    end

    def guess guesses : Array(Char)
      guesses.each do |guess|
        guess guess
      end
    end

    def guess guess : Char
      return if over?
      @guesses << guess.downcase unless guessed? guess
    end

    def guessed? guess
      @guesses.includes? guess.downcase
    end

    def lost?
      wrong_guesses.size >= 12
    end

    def won?
      !lost? && !known_chars.includes?(PLACEHOLDER)
    end

    def over?
      lost? || won?
    end

    private def pick_word list
      WORDLISTS[list].sample.chars
    end
  end

  GAMES  = {} of String => Game
  LIMITS = Framework::LimiterCollection(Framework::User).new 3, 60

  listen :message

  def react_to event
    msg = event.message
    return unless msg.channel?
    message = msg.message
    return unless message.starts_with? bot.nick

    return unless LIMITS.pass? msg.sender
    LIMITS.hit msg.sender

    command = message.gsub(/^#{bot.nick}[:,]?\s*/, "")
    case command
    when /^!hangman\s+\w+$/
      _c, list = command.split
      start_game msg, list
    when /^!hangman$/
      start_game msg, Game::DEFAULT_LIST
    when /^space$/
      guess msg, ' '
    when /^[a-zA-Z0-9!"#\$%&'\*\+,\-\.\/:;<=>\?@\[\]\\^_`|~ ]+$/
      guess msg, command.downcase.chars
    end
  end

  def start_game msg, list
    unless GAMES.has_key? msg.channel.name
      GAMES[msg.channel.name] = Game.new list
    end

    msg.reply GAMES[msg.channel.name].status
  end

  def guess msg, guess
    return unless GAMES.has_key? msg.channel.name

    game = GAMES[msg.channel.name]
    game.guess guess
    msg.reply game.status
    GAMES.delete(msg.channel.name) if game.over?
  end
end
