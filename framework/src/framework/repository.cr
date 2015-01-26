require "thread/read_write_lock"

module Framework
    class Repository(K,V)
    def initialize
      @store = Hash(K,V).new
      @lock = ReadWriteLock.new
    end

    def fetch key : K
      exists = @lock.read_lock do
        @store.has_key?(key)
      end

      if exists
        @lock.read_lock do
          @store[key]
        end
      else
        @lock.write_lock do
          @store[key] ||= yield
        end
      end
    end
  end
end
