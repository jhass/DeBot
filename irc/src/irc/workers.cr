require "core_ext/thread"
require "thread/queue"

require "./message"

module IRC
  class Reader
    delegate join, @th
    getter logger

    def initialize socket, queue, @logger
      @socket = socket
      pipe, @pipe = IO.pipe
      @th = Thread.new do
        reader = self
        loop do
          begin
            ios = IO.select([socket, pipe])

            if ios.includes? pipe
              if pipe.gets == "stop\n"
                reader.logger.debug "Reader received stop signal, shutting down"
                break
              end

              next
            end

            line = socket.gets
            if line
              reader.logger.debug "r> #{line.chomp}"
              message = Message.from(line)
              queue << message if message
            end
          rescue e : Errno
            unless e.errno == Errno::EINTR
              reader.logger.fatal "Failed to read message: #{e.message} (#{e.class})"
              exit 1
            end
          rescue e
            reader.logger.fatal "Failed to read message: #{e.message} (#{e.class})"
            exit 1
          end
        end
        reader.logger.debug "Stopped reader"
      end

      @th.name = "Reader"
    end

    def stop
      logger.debug "Stopping reader"
      @pipe.puts "stop"
      @pipe.close
      @socket.close
    end
  end

  class Sender
    delegate join, @th
    getter logger

    def initialize socket, queue, @logger
      @queue = queue
      @th = Thread.new do
        sender = self
        begin
          loop do
            message = queue.shift
            if message.is_a? String
              sender.logger.debug "w> #{message.chomp}"
              socket.puts message
            elsif message == :stop
              sender.logger.debug "Sender received stop signal, shutting down"
              break
            end
          end
        rescue e
          sender.logger.fatal "Failed to send message: #{e.message} (#{e.class})"
          exit 1
        end
      end

      @th.name = "Sender"
    end

    def stop
      logger.debug "Stopping sender"
      @queue << :stop
    end
  end

  class Processor
    record Job, message, handler

    delegate join, @th

    def initialize id, pool, queue, logger
      @th = Thread.new do
        processor = self
        loop do
          begin
            work = queue.shift
            if work.is_a? Message
              pool.handlers.each do |handler|
                queue << Job.new(work, handler)
              end
            elsif work.is_a? Job
              work.handler.call(work.message)
            elsif work == :stop
              logger.debug "Processor #{id} received stop signal, shutting down"
              break
            end
          rescue e
            logger.error "Couldn't process message: #{e.message} (#{e.class})"
          end
        end
      end

      @th.name = "Processor #{id}"
    end
  end

  class ProcessorPool
    getter queue
    getter handlers

    def initialize @size, @logger
      @queue = Queue(Processor::Job|Message|Symbol).new
      @processors = Array.new(@size) {|id| Processor.new(id+1, self, queue, @logger) }
      @handlers = Array(Message ->).new
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
      @logger.debug "Stopping processors"
      @size.times do
        @queue << :stop
      end
    end

    def join
      @processors.each &.join
    end
  end
end
