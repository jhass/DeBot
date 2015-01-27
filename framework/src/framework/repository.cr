require "thread/read_write_lock"

module Framework
    class Repository(K,V)
    def initialize
      @store = Hash(K,V).new
      @lock = ReadWriteLock.new
    end

    def fetch key : K
      if exists? key
        @lock.read_lock do
          @store[key]
        end
      else
        @lock.write_lock do
          @store[key] ||= yield
        end
      end
    end

    def exists? key
      @lock.read_lock do
        @store.has_key?(key)
      end
    end

    def rename oldkey, newkey
      unless exists? oldkey
        raise ArgumentError.new "#{oldkey.inspect} not present in repository"
      end

      @lock.write_lock do
        @store[newkey] = @store[oldkey]
        @store.delete oldkey
      end
    end
  end
end
