require "./lib_pthread"

class CheckingMutex < Mutex
  def initialize
    LibPThread.mutexattr_init(out @attr)
    LibPThread.mutexattr_settype(pointerof(@attr), LibPThread::MUTEX_ERRORCHECK)
    LibPThread.mutex_init_fixed(out @mutex, pointerof(@attr))
  end

  def lock
    ret = LibPThread.mutex_lock(self)

    case ret
    when 0
    else
      puts "le"
      pp ret
      raise "Locking the mutex failed with #{ret}"
    end
  end

  def try_lock
    ret = LibPThread.mutex_trylock(self)

    case ret
    when 0
    else
      puts "te"
      pp ret
      raise "Locking the mutex failed with #{ret}"
    end
  end

  def unlock
    ret = LibPThread.mutex_unlock(self)

    case ret
    when 0
    else
      puts "ue"
      pp ret
      raise "Locking the mutex failed with #{ret}"
    end
  end

  def relock
    ret = LibPThread.mutex_lock(self)

    case ret
    when 0
      true
    when LibPThread::EDEADLK
      false
    else
      puts "re"
      pp ret
      raise "Locking the mutex failed with #{ret}"
    end
  end

  def synchronize
    do_unlock = relock
    yield self
  ensure
    unlock if do_unlock
  end
end
