require "./lib_pthread"

class ReadWriteLock
  def initialize
    LibC.pthread_rwlock_init(out @lock, nil)
  end

  def read_lock
    LibC.pthread_rwlock_rdlock(self)
    yield
  ensure
    unlock
  end

  def write_lock
    LibC.pthread_rwlock_wrlock(self)
    yield
  ensure
    unlock
  end

  def unlock
    LibC.pthread_rwlock_unlock(self)
  end

  def to_unsafe
    pointerof(@lock)
  end
end
