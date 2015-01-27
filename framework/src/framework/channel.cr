require "./repository"
require "./message"
require "./bot"

module Framework
  class Channel
    getter name

    @@channels = Repository(String, Channel).new

    def self.from_name name : String, context
      @@channels.fetch(name) { new(name, context) }
    end

    private def initialize(@name : String, @context : Bot)
    end

    def send text : String
      Message.new(@context, @name, text).send
    end
  end
end
