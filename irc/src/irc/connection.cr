require "socket"
require "signal"

require "core_ext/openssl"
require "thread/queue"

require "./channel"
require "./message"
require "./workers"

module IRC
  class Connection
    class Config
      property! server
      property  port
      property  nick
      property  user
      property! password
      property  realname
      property! ssl
      property! try_sasl
      property  processors

      private def initialize
        @port       = 6667
        @nick       = "Crystal"
        @user       = "crystal"
        @password   = nil
        @realname   = "Crystal"
        @ssl        = false
        @try_sasl   = false
        @processors = 2
      end

      def self.new server : String
        build.tap do |config|
          config.server = server
        end
      end

      def self.build
        new.tap do |config|
          yield config

          raise ArgumentError.new "server must be provided" unless config.server?

          if config.try_sasl? && !config.password?
            raise ArgumentError.new "must set password when enabling SASL"
          end

          config.port = config.ssl ? 6697 : 6667
        end
      end
    end

    property! userhost
    property? connected
    getter config

    def self.build &block : Config ->
      new Config.build(&block)
    end

    def self.new server : String
      new Config.new(server)
    end

    def initialize @config : Config
      @send_queue = Queue(String|Symbol).new
      @channels = {} of String => Channel
      @processor = ProcessorPool.new(config.processors)
      @connected = false
    end

    def await type
      condition = ConditionVariable.new
      handler = @processor.on(type) do
        condition.signal
      end

      Mutex.new.synchronize do |mutex|
        condition.wait mutex
      end

      @processor.handlers.delete(handler)
    end

    def quit message="Crystal"
      send Message::QUIT, message
    end

    def send message : Message
      @send_queue << message.to_s
    end

    def send type : String, parameters : Array(String)
      send message_for(type, parameters)
    end

    def send type : String, *parameters
      # Compiler bug: get rid of NoReturn the manual way
      converted_parameters = [] of String
      parameters.each do |parameter|
        converted_parameters << parameter.to_s
      end
      send message_for(type, converted_parameters)
    end

    private def message_for type, parameters
      if parameters.empty?
        message = Message.from(type)
        unless message
          raise Message::Malformed.new "#{type} does not parse as an IRC message"
        end
      else
        message = Message.new(type, parameters)
      end

      message
    end

    def nick= nick : String
      oldnick = config.nick
      config.nick = nick
      send Message::NICK, nick unless connected? && nick == oldnick
    end

    def join channel_name
      Channel.new(self, channel_name).tap do |channel|
        channel.join
        @channels[channel_name] = channel
      end
    end

    def part channel_name
      @channels[channel_name]?.tap do |channel|
        if channel
          channel.part
          @channels.delete channel_name
        end
      end
    end

    def on *args, &handler : Message ->
      @processor.on *args, &handler
    end

    def on_query(&handler : Message ->)
      on(Message::PRIVMSG, Message::NOTICE) do |message|
        target = message.parameters.first
        handler.call(message) if target == config.nick
      end
    end

    def connect
      socket = TCPSocket.new config.server, config.port
      socket = OpenSSL::SSL::Socket.new socket if config.ssl?

      if config.try_sasl?
        send Message::CAP, "LS"

        on Message::CAP do |cap|
          case cap.parameters[1]
          when "LS"
            cap.parameters.last.split(' ').includes? "sasl"
            send Message::CAP, "REQ", "sasl"
          when "ACK"
            if cap.parameters.last == "sasl"
              send Message::AUTHENTICATE, "PLAIN"
            else
              send Message::CAP, "END"
            end
          else
            send Message::CAP, "END"
          end
        end

        on Message::AUTHENTICATE do
          send Message::AUTHENTICATE, Base64.strict_encode64("#{config.nick}\0#{config.nick}\0#{config.password}")
        end

        on Message::RPL_SASL_SUCCESS, Message::RPL_SASL_FAILED, Message::RPL_SASL_ABORTED do
          send Message::CAP, "END"
        end
      elsif config.password?
        send Message::PASS, config.password
      end

      self.nick = config.nick
      send Message::USER, config.user, "0", "*", config.realname

      Signal.trap(Signal::INT) do
        quit
      end

      Signal.trap(Signal::TERM) do
        quit
      end

      on Message::ERROR do |error|
        if error.message.starts_with? "Closing Link"
          stop_threads
          exit
        end
      end

      on Message::PING do
        send Message::PONG, self.userhost? || config.user
      end

      on Message::ERR_NICKCOLLISION, Message::ERR_NICKNAMEINUSE do |error|
        self.nick = "#{config.nick}_"
      end

      on Message::RPL_WELCOME do |message|
        self.connected = true
        self.nick = message.parameters.first
      end

      on Message::JOIN do |message|
        if prefix = message.prefix
          nick, rest = prefix.split('!')
          user, _rest = rest.split('@')
          if nick == config.nick
            self.userhost = prefix
            self.config.user = user
          end
        end
      end

      processor = @processor.not_nil!
      reader = Reader.new socket, processor.queue
      sender = Sender.new socket, @send_queue

      await(Message::RPL_WELCOME)

      @threads = {processor, reader, sender}
    end

    def block
      @threads.not_nil!.each &.join
    end

    private def stop_threads
      @threads.not_nil!.each &.stop
    end
  end

  class CommandFailed < Exception
  end
end
