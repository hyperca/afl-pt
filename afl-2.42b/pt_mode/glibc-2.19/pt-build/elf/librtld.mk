rtld-csu +=check_fds.os
rtld-csu +=errno.os
rtld-setjmp +=setjmp.os
rtld-setjmp +=__longjmp.os
rtld-string +=strchr.os
rtld-string +=strcmp.os
rtld-string +=strcpy.os
rtld-string +=strlen.os
rtld-string +=strnlen.os
rtld-string +=memchr.os
rtld-string +=memcmp.os
rtld-string +=memmove.os
rtld-string +=memset.os
rtld-string +=mempcpy.os
rtld-string +=stpcpy.os
rtld-string +=memcpy.os
rtld-string +=wordcopy.os
rtld-string +=rawmemchr.os
rtld-string +=strcmp-ssse3.os
rtld-string +=strcmp-sse2-unaligned.os
rtld-string +=memcmp-sse4.os
rtld-string +=memcpy-ssse3.os
rtld-string +=memcpy-sse2-unaligned.os
rtld-string +=mempcpy-ssse3.os
rtld-string +=memmove-ssse3.os
rtld-string +=mempcpy-ssse3-back.os
rtld-string +=memmove-ssse3-back.os
rtld-string +=strcpy-ssse3.os
rtld-string +=stpcpy-ssse3.os
rtld-string +=strcpy-sse2-unaligned.os
rtld-string +=stpcpy-sse2-unaligned.os
rtld-string +=strchr-sse2-no-bsf.os
rtld-string +=memcmp-ssse3.os
rtld-string +=cacheinfo.os
rtld-dirent +=closedir.os
rtld-dirent +=readdir.os
rtld-dirent +=rewinddir.os
rtld-dirent +=getdents.os
rtld-dirent +=fdopendir.os
rtld-posix +=uname.os
rtld-posix +=waitpid.os
rtld-posix +=_exit.os
rtld-posix +=getpid.os
rtld-posix +=environ.os
rtld-io +=xstat.os
rtld-io +=fxstat.os
rtld-io +=lxstat.os
rtld-io +=open.os
rtld-io +=read.os
rtld-io +=write.os
rtld-io +=access.os
rtld-io +=fcntl.os
rtld-io +=close.os
rtld-misc +=mmap.os
rtld-misc +=munmap.os
rtld-misc +=mprotect.os
rtld-misc +=llseek.os
rtld-gmon +=profil.os
rtld-gmon +=prof-freq.os
rtld-nptl +=libc-lowlevellock.os
rtld-nptl +=libc-cancellation.os
rtld-nptl +=libc_multiple_threads.os
rtld-csu +=init-arch.os
rtld-signal +=sigaction.os
rtld-time +=setitimer.os
rtld-nptl +=forward.os
rtld-stdlib +=exit.os
rtld-stdlib +=cxa_atexit.os
rtld-stdlib +=cxa_thread_atexit_impl.os
rtld-subdirs = csu dirent gmon io misc nptl posix setjmp signal stdlib string time
