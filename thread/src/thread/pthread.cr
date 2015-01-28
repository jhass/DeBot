lib PThread
  EDEADLK = 35

  MUTEX_RECURSIVE  = 1
  MUTEX_ERRORCHECK = 2

  fun mutexattr_init    = pthread_mutexattr_init(mutex_attr : MutexAttr*) : Int32
  fun mutexattr_settype = pthread_mutexattr_settype(mutex_attr : MutexAttr*, type : Int32) : Int32

  fun mutex_init_fixed = pthread_mutex_init(mutex : Mutex*, mutex_attr : MutexAttr*) : Int32

  type Rwlock = Int64[8]
  type RwlockAttr = Void*

  fun rwlock_init   = pthread_rwlock_init(lock : Rwlock*, lock_attr : RwlockAttr*) : Int32
  fun rwlock_rdlock = pthread_rwlock_rdlock(lock : Rwlock*) : Int32
  fun rwlock_wrlock = pthread_rwlock_wrlock(lock : Rwlock*) : Int32
  fun rwlock_unlock = pthread_rwlock_unlock(lock : Rwlock*) : Int32
end
