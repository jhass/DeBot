require "./lib_pthread"

class RecursiveMutex < Mutex
  def initialize
    LibPThread.mutexattr_init(out @attr)
    LibPThread.mutexattr_settype(pointerof(@attr), LibPThread::MUTEX_RECURSIVE)
    LibPThread.mutex_init_fixed(out @mutex, pointerof(@attr))
  end
end
