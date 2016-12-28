require "json"

module Framework
  class JsonStore(K, V)
    def initialize(@path : String)
      @data = Hash(K, V).new
      load
    end

    def fetch(key)
      yield @data[key]?
    end

    def modify(key)
      value = yield @data[key]?
      @data[key] = value
      write
    end

    def set(key, value)
      @data[key] = value
      write
    end

    def keys
      @data.keys
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
