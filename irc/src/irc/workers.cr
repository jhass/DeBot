require "./message"

module IRC
  class Reader
    getter logger

    def initialize socket, channel, @logger
      spawn do
        loop do
          begin
            line = socket.gets
            if line
              logger.debug "r> #{line.chomp}"
              message = Message.from(line)
              channel.send message if message
            end
          rescue e : InvalidByteSequenceError
            logger.warn "Failed to decode message: #{line.try(&.dump) || line.inspect}"
          rescue e : Errno
            unless e.errno == Errno::EINTR
              logger.fatal "Failed to read message: #{e.message} (#{e.class})"
              exit 1
            end
          rescue e
            logger.fatal "Failed to read message: #{e.message} (#{e.class})"
            exit 1
          end
        end
        logger.debug "Stopped reader"
      end
    end

    def stop
      # We'll just die as main exits
    end
  end

  class Sender
    getter logger

    def initialize socket, channel, @logger
      @stop_signal = ::Channel(Symbol).new
      spawn do
        begin
          loop do
            message = ::Channel.select(@stop_signal, channel).receive
            if message.is_a? String
              logger.debug "w> #{message.chomp}"
              message.to_s(socket)
              socket.flush
            elsif message == :stop
              logger.debug "Sender received stop signal, shutting down"
              break
            end
          end
        rescue e
          logger.fatal "Failed to send message: #{e.message} (#{e.class})"
          exit 1
        end
      end
    end

    def stop
      logger.debug "Stopping sender"
      @stop_signal.send :stop
    end
  end

  class Processor
    getter channel
    getter handlers

    def initialize @logger
      @channel = ::Channel(Message).new(64)
      @handlers = Array(Message ->).new
      @pending_handlers = 0

      process
    end

    def handle(&handler : Message ->)
      @handlers << handler
      handler
    end

    def on *types, &handler : Message ->
      handle do |message|
        handler.call(message) if types.includes? message.type
      end
    end

    def stop
      # We'll just die as main exits
    end

    def handle_others
      loop do
        pending_handlers = @pending_handlers
        Scheduler.yield
        break if pending_handlers == @pending_handlers
      end
    end

    def process
      spawn do
        loop do
          message = @channel.receive
          @handlers.each do |handler|
            handle_others if @pending_handlers >= 100
            @pending_handlers += 1
            spawn do
              handler.call(message)
              @pending_handlers -= 1
            end
          end
        end
      end
    end
  end
end
