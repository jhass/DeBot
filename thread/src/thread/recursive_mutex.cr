lib PThread
  MUTEX_RECURSIVE = 1
  fun mutexattr_init = pthread_mutexattr_init(mutex_attr : MutexAttr*) : Int32
  fun mutexattr_settype = pthread_mutexattr_settype(mutex_attr : MutexAttr*, type : Int32) : Int32

  fun mutex_init_fixed = pthread_mutex_init(mutex : Mutex*, mutex_attr : MutexAttr*) : Int32
end

class RecursiveMutex < Mutex
  def initialize
    PThread.mutexattr_init(out @attr)
    PThread.mutexattr_settype(pointerof(@attr), PThread::MUTEX_RECURSIVE)
    PThread.mutex_init_fixed(out @mutex, pointerof(@attr))
  end
end
