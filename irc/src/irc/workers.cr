require "./message"

module IRC
  class Reader
    private getter logger

    def initialize(socket, channel, @logger : Logger)
      spawn do
        loop do
          break if channel.closed?
          begin
            line = socket.gets
            if line
              logger.debug "r> #{line.chomp}"
              message = Message.from(line)
              channel.send message if message
            else
              logger.fatal "Socket closed, EOF!"
              channel.send Message.from(":fake PING :fake").not_nil!
              channel.close
              socket.close unless socket.closed?
              break
            end
          rescue IO::Timeout
            if socket.closed?
              logger.fatal "Socket closed while reading!"
              channel.send Message.from(":fake PING :fake").not_nil!
              channel.close
              break
            else
              logger.debug "No message within 300 seconds"
            end
          rescue e : InvalidByteSequenceError
            logger.warn "Failed to decode message: #{line.try &.bytes.inspect}"
          rescue e : Errno
            unless e.errno == Errno::EINTR
              logger.fatal "Failed to read message: #{e.message} (#{e.class})"
            else
              logger.debug "Got #{e.class}: #{e.message}"
            end
          rescue e
            logger.fatal "Failed to read message: #{e.message} (#{e.class})"
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
    RATE_LIMIT = 3 # number of messages per second

    private getter logger
    @write_interval : Time::Span

    def initialize(socket, channel, @logger : Logger)
      @stop_signal = ::Channel(Symbol).new
      @last_write = 1.second.ago
      @write_interval = 1.fdiv(RATE_LIMIT).seconds
      spawn do
        begin
          loop do
            break if channel.closed? || @stop_signal.closed?
            message = ::Channel.receive_first(@stop_signal, channel)
            if message.is_a? String
              begin
                sleep @write_interval if Time.now - @last_write < @write_interval
                logger.debug "w> #{message.chomp}"
                message.to_s(socket)
                socket.flush
                @last_write = Time.now
              rescue IO::Timeout
                if socket.closed?
                  logger.fatal "Socket closed while writing!"
                  channel.close
                  break
                end
              end
            elsif message == :stop
              logger.debug "Sender received stop signal, shutting down"
              channel.close
              socket.close unless socket.closed?
              break
            end
          end
        rescue e
          logger.fatal "Failed to send message: #{e.message} (#{e.class})"
        end

        logger.debug "Stopped sender"
      end
    end

    def stop
      logger.debug "Stopping sender"
      @stop_signal.send :stop
      @stop_signal.close
    end
  end

  class Processor
    getter channel
    getter handlers
    private getter logger

    def initialize(@logger : Logger)
      @channel = ::Channel(Message).new(64)
      @handlers = Array(Message ->).new
      @pending_handlers = 0
      @stop_signal = ::Channel(Symbol).new

      process
    end

    def handle(&handler : Message ->)
      @handlers << handler
      handler
    end

    def on(*types, &handler : Message ->)
      handle do |message|
        handler.call(message) if types.includes? message.type
      end
    end

    def stop
      logger.debug "Stopping processor"
      @stop_signal.send :stop
      @stop_signal.close
    end

    def handle_others
      loop do
        pending_handlers = @pending_handlers
        Fiber.yield
        break if pending_handlers == @pending_handlers
      end
    end

    def process
      spawn do
        loop do
          break if @channel.closed? || @stop_signal.closed?
          message = ::Channel.receive_first(@stop_signal, @channel)
          if message.is_a? Message
            spawn_handlers message
          elsif message == :stop
            logger.debug "Processor received stop signal, shutting down"
            @channel.close
            break
          end
        end
        logger.debug "Stopped processor"
        exit 1
      end
    end

    private def spawn_handlers(message)
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
