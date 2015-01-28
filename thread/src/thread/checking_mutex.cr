require "./pthread"

class CheckingMutex < Mutex
  def initialize
    PThread.mutexattr_init(out @attr)
    PThread.mutexattr_settype(pointerof(@attr), PThread::MUTEX_ERRORCHECK)
    PThread.mutex_init_fixed(out @mutex, pointerof(@attr))
  end

  def lock
    ret = PThread.mutex_lock(self)

    case ret
    when 0
    else
      puts "le"
      pp ret
      raise "Locking the mutex failed with #{ret}"
    end
  end

  def try_lock
    ret = PThread.mutex_trylock(self)

    case ret
    when 0
    else
      puts "te"
      pp ret
      raise "Locking the mutex failed with #{ret}"
    end
  end

  def unlock
    ret = PThread.mutex_unlock(self)

    case ret
    when 0
    else
      puts "ue"
      pp ret
      raise "Locking the mutex failed with #{ret}"
    end
  end

  def relock
    ret = PThread.mutex_lock(self)

    case ret
    when 0
      true
    when PThread::EDEADLK
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
