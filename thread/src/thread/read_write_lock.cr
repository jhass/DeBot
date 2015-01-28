require "./pthread"

class ReadWriteLock
  def initialize
    PThread.rwlock_init(out @lock, nil)
  end

  def read_lock
    PThread.rwlock_rdlock(self)
    yield
  ensure
    unlock
  end

  def write_lock
    PThread.rwlock_wrlock(self)
    yield
  ensure
    unlock
  end

  def unlock
    PThread.rwlock_unlock(self)
  end

  def to_unsafe
    pointerof(@lock)
  end
end
