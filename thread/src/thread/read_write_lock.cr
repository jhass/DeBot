lib PThread
  type Rwlock = Int64[8]
  type RwlockAttr = Void*

  fun rwlock_init = pthread_rwlock_init(lock : Rwlock*, lock_attr : RwlockAttr*) : Int32
  fun rwlock_rdlock = pthread_rwlock_rdlock(lock : Rwlock*) : Int32
  fun rwlock_wrlock = pthread_rwlock_wrlock(lock : Rwlock*) : Int32
  fun rwlock_unlock = pthread_rwlock_unlock(lock : Rwlock*) : Int32
end

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
