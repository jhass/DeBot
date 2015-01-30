require "./lib_pthread"

class ReadWriteLock
  def initialize
    LibPThread.rwlock_init(out @lock, nil)
  end

  def read_lock
    LibPThread.rwlock_rdlock(self)
    yield
  ensure
    unlock
  end

  def write_lock
    LibPThread.rwlock_wrlock(self)
    yield
  ensure
    unlock
  end

  def unlock
    LibPThread.rwlock_unlock(self)
  end

  def to_unsafe
    pointerof(@lock)
  end
end
