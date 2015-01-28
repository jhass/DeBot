require "./pthread"

class RecursiveMutex < Mutex
  def initialize
    PThread.mutexattr_init(out @attr)
    PThread.mutexattr_settype(pointerof(@attr), PThread::MUTEX_RECURSIVE)
    PThread.mutex_init_fixed(out @mutex, pointerof(@attr))
  end
end
