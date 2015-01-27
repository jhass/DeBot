require "socket"
require "signal"

require "thread/queue"

require "./channel"
require "./message"
require "./workers"

module IRC
  class Connection
    property nick
    property user
    property! userhost
    property? connected

    def initialize @server : String, @port=6667, @nick="Crystal" : String, @user="crystal" : String, @realname="Crystal", processors = 2
      @send_queue = Queue(String|Symbol).new
      @channels = {} of String => Channel
      @processor = ProcessorPool.new(processors)
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

    def send type : String, *parameters : Array(String)
      send type, parameters.to_a
    end

    def send type : String, parameters : Array(String)
      if parameters.empty?
        message = Message.from(type)
        unless message
          raise Message::Malformed.new "#{type} does not parse as an IRC message"
        end
      else
        message = Message.new(type, parameters)
      end

      send message
    end

    def nick= nick : String
      oldnick = @nick
      @nick = nick
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
        handler.call(message) if target == @nick
      end
    end

    def connect
      socket = TCPSocket.new @server, @port

      self.nick = @nick
      send Message::USER, @user, "0", "*", @realname

      processor = @processor.not_nil!
      reader = Reader.new socket, processor.queue
      sender = Sender.new socket, @send_queue

      Signal.trap(Signal::INT) do
        quit
      end

      on Message::ERROR do |error|
        if error.message.starts_with? "Closing Link"
          socket.close
          stop_threads
          exit
        end
      end

      on Message::PING do
        send Message::PONG, self.userhost? || @user
      end

      on Message::ERR_NICKCOLLISION, Message::ERR_NICKNAMEINUSE do |error|
        self.nick = "#{nick}_"
      end

      # on Message::RPL_USERHOST do |reply|
      #   userhosts = reply.parameters.last.split.map {|entry|
      #     nick, host = entry.split("=")
      #     away, host = host[0], host[1..-1]
      #     op = nick.ends_with?("*")
      #     nick = nick[0..-2] if op

      #     {nick, host, (away == "-"), op}
      #   }
      #   mine = userhosts.find(&.[0].==(nick))
      #   self.userhost = mine[1] if mine
      # end

      on Message::RPL_WELCOME do |message|
        self.connected = true
        self.nick = message.parameters.first
      end

      on Message::JOIN do |message|
        if prefix = message.prefix
          nick, rest = prefix.split('!')
          user, _rest = rest.split('@')
          if nick == self.nick
            self.userhost = prefix
            self.user = user
          end
        end
      end

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
