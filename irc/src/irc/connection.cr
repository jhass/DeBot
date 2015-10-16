require "socket"
require "signal"
require "base64"

require "logger"

require "core_ext/openssl"
require "thread/repository"

require "./channel"
require "./mask"
require "./message"
require "./network"
require "./user_manager"
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
      setter    logger

      private def initialize
        @port       = 6667
        @nick       = "Crystal"
        @user       = "crystal"
        @password   = nil
        @realname   = "Crystal IRC"
        @ssl        = false
        @try_sasl   = false
        @logger     = nil
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

      def logger
        @logger ||= Logger.new(STDOUT)
      end
    end

    property? connected
    getter config
    getter users
    getter channels
    getter network
    delegate logger, config

    def self.build &block : Config ->
      new Config.build(&block)
    end

    def self.new server : String
      new Config.new(server)
    end

    def initialize @config : Config
      @send_queue   = ::Channel(String).new(64)
      @users        = UserManager.new
      @channels     = Repository(String, Channel).new
      @processor    = Processor.new(logger)
      @network      = Network.new
      @connected    = false
      @exit_channel = ::Channel(Int32).new

      @users.track Mask.parse(@config.nick) # Track self with pseudo mask
    end

    def await *types, &callback : Message -> Bool
      channel = ::Channel(Message).new
      handler = @processor.on(*types) do |message|
        channel.send(message) if callback.call(message)
      end

      channel.receive.tap do
        @processor.handlers.delete(handler)
        @processor.handle_others
      end
    end

    def await *types
      await(*types) do |_message|
        true
      end
    end

    def send message : Message
      @send_queue.send message.to_s
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
      @users.nick Mask.parse(oldnick), nick unless nick == oldnick
      send Message::NICK, nick unless connected? && nick == oldnick
    end

    def join channel_name
      Channel.new(self, channel_name).tap do |channel|
        channel.join
        @users.join Mask.parse(config.nick), channel
        @channels[channel_name] = channel
      end
    end

    def part channel_name
      @channels[channel_name]?.tap do |channel|
        if channel
          channel.part
          @users.part Mask.parse(config.nick), channel
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
      logger.info "Connecting to #{config.server}:#{config.port}#{" (SSL enabled)" if config.ssl?}"

      socket = TCPSocket.new config.server, config.port
      socket = OpenSSL::SSL::Socket.new socket if config.ssl?

      send Message::CAP, "LS"

      on Message::CAP do |cap|
        case cap.parameters[1]
        when "LS"
          capabilities = cap.parameters.last.split(' ')

          send Message::CAP, "REQ", "account-notify" if capabilities.includes? "account-notify"
          send Message::CAP, "REQ", "extended-join" if capabilities.includes? "extended-join"

          if config.try_sasl? && capabilities.includes? "sasl"
            logger.info "Attempting SASL authentication"
            send Message::CAP, "REQ", "sasl"
          else
            send Message::CAP, "END"
          end
        when "ACK"
          network.account_notify = true if cap.parameters.last == "account-notify"
          network.extended_join  = true if cap.parameters.last == "extended-join"

          if cap.parameters.last == "sasl"
            send Message::AUTHENTICATE, "PLAIN"
          end
        when "NAK"
        else
          send Message::CAP, "END"
        end
      end

      on Message::AUTHENTICATE do
        send Message::AUTHENTICATE, Base64.strict_encode("#{config.nick}\0#{config.nick}\0#{config.password}")
      end

      on(Message::RPL_LOGGEDIN,     Message::RPL_LOGGEDOUT, Message::ERR_NICKLOCKED,
         Message::RPL_SASLSUCCESS,  Message::ERR_SASLFAIL,  Message::ERR_SASLTOOLONG,
         Message::RPL_SASL_ABORTED, Message::ERR_SASLALREADY) do |message|

        if {Message::RPL_LOGGEDIN, Message::RPL_SASLSUCCESS, Message::ERR_SASLALREADY}.includes? message.type
          logger.info "SASL authentication succeeded"
        else
          logger.warn "SASL authentication failed"
        end

        send Message::CAP, "END"
      end

      if config.password? && !config.try_sasl?
        send Message::PASS, config.password
      end

      self.nick = config.nick
      send Message::USER, config.user, "0", "*", config.realname

      Signal::INT.trap do
        quit
      end

      Signal::TERM.trap do
        quit
      end

      on Message::ERROR do |error|
        if error.message.starts_with? "Closing Link"
          logger.warn "Server closed connection (#{error.message}), shutting down"

          stop_workers
          exit 1
        end
      end

      on Message::PING do |ping|
        send Message::PONG, ping.message
      end

      on Message::PRIVMSG do |message|
        if message.message == "\u0001VERSION\u0001"
          send Message::PRIVMSG, message.prefix.not_nil!.split("!", 2).first, "#{config.user} 0.1.0"
        end
      end

      on Message::ERR_NICKCOLLISION, Message::ERR_NICKNAMEINUSE, Message::ERR_UNAVAILRESOURCE do |error|
        if error.type != Message::ERR_UNAVAILRESOURCE || error.message == config.nick
          self.nick = "#{config.nick}_"
        end
      end

      on Message::RPL_WELCOME do |message|
        self.connected = true
        self.nick = message.parameters.first
      end

      @users.register_handlers self

      processor = @processor.not_nil!
      reader = Reader.new socket, processor.channel, logger
      sender = Sender.new socket, @send_queue, logger

      @workers = {processor, reader, sender}

      await(Message::RPL_WELCOME)

      logger.info "Connected"
    end

    def quit message="Crystal IRC"
      send Message::QUIT, message
      @processor.handle_others
      stop_workers
      exit
    end

    def exit(code=0)
      @exit_channel.send code
      @exit_channel.close
      @processor.handle_others
      Scheduler.yield
    end

    def block
      ::exit @exit_channel.receive
    end

    private def stop_workers
      @workers.not_nil!.each &.stop
      Scheduler.yield
    end
  end

  class CommandFailed < Exception
  end
end
