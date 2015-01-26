require "json"

require "thread/read_write_lock"

module Framework
  class JsonStore(K, V)
    def initialize @path
      @lock = ReadWriteLock.new
      @data = Hash(K, V).new
      load
    end

    def fetch key
      @lock.read_lock do
        yield @data[key]?
      end
    end

    def modify key
      @lock.write_lock do
        value = yield @data[key]?
        @data[key] = value
        write
      end
    end

    def set key, value
      @lock.write_lock do
        @data[key] = value
        write
      end
    end

    private def load
      if File.exists? @path
        @data = Hash(K, V).from_json(File.read(@path))
      else
        Dir.mkdir_p File.dirname @path
        write
      end
    end

    private def write
      File.write @path, @data.to_json
    end
  end
end
