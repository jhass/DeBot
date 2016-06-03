lib LibC
  # MUTEX_RECURSIVE  = 1
  # MUTEX_ERRORCHECK = 2

  fun pthread_mutexattr_init(mutex_attr : PthreadMutexattrT*) : Int32
  fun pthread_mutexattr_settype(mutex_attr : PthreadMutexattrT*, type : Int32) : Int32

  fun pthread_mutex_init(mutex : PthreadMutexT*, mutex_attr : PthreadMutexattrT*) : Int32

  type Rwlock = Int64[8]
  type RwlockAttr = Void*

  fun pthread_rwlock_init(lock : Rwlock*, lock_attr : RwlockAttr*) : Int32
  fun pthread_rwlock_rdlock(lock : Rwlock*) : Int32
  fun pthread_rwlock_wrlock(lock : Rwlock*) : Int32
  fun pthread_rwlock_unlock(lock : Rwlock*) : Int32
end
