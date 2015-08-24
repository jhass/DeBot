require "./read_write_lock"

# A simple thread safe map
class Repository(K,V)
  def initialize
    @store = Hash(K,V).new
    @lock = ReadWriteLock.new
  end

  def fetch key
    fetch(key) { raise KeyError.new "Repository #{self} doesn't have key #{key}" }
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

  def [] key
    fetch(key)
  end

  def []? key
    @lock.read_lock do
      @store[key]?
    end
  end

  def []= key : K, value : V
    @lock.write_lock do
      @store[key] = value
    end
  end

  def exists? key
    @lock.read_lock do
      @store.has_key?(key)
    end
  end

  def delete key
    @lock.write_lock do
      @store.delete key
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

  def rehash
    @lock.write_lock do
      @store.rehash
    end
  end
end
