lib LibC
  alias UsecondsT = UInt32
  fun usleep(usec : UsecondsT)
  fun calloc(count : SizeT, size : SizeT) : UInt8*
  fun free(ptr : Void*)
  fun putchar(c : Char)
  fun sprintf(s : Char*, format : Char*, ...) : Int
  fun fprintf(stream : Void*, format : Char*, ...) : Int
  fun fflush(stream : Void*)
  fun puts(s : Char*)
  fun fputs(s : Char*, fd : Void*)
  fun fdopen(fd : Int32, mode : Char*) : Void*
  fun getline(s : Char**, size : SizeT*, fd : Void*) : Int32
  fun perror(s : Char*)
  fun strncmp(s : Char*, cmp : Char*, n : SizeT) : Int32

  fun rand : Int32
  fun rand_r(seedp : UInt32*) : Int32
  fun srand(seed : UInt32)

  fun atoi(nptr : Char*) : Int32
  fun atol(nptr : Char*) : Long
  fun atoll(nptr : Char*) : LongLong

  fun exit(status : Int32) : NoReturn

  $stdin : Void*
  $stdout : Void*
  $stderr : Void*

  SOMAXCONN =          128
  RAND_MAX  = 16777215_i32

  SYS_gettid = 186
end
