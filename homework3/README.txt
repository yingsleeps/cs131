### Performance Analysis:
In each trial, I used the example input, `input=/usr/local/cs/jdk-21.0.2/lib/modules`. Here, the input file
has size of 139257677 bytes, and the compression ratios listed below are of the form (raw size/compressed size).

**Default:**
In the following time results for each program, we see the differences between the default settings of Pigzj and 
pigz, compared to gzip. gzip is the worst of the three, with an average real time of 9.76s, and pigz is the best, 
with an average real time of 5.74s. Pigzj is between these two in terms of real time, with the average being 
7.13s. My implementation is not as fast as pigz, with an average difference of 1.39s, but it does do better than 
the no-parallelization case (gzip).

For the compression ratios, all three programs are all extremely similar, with gzip having the best out of the 
three. It seems that the parallel compression programs are ever so slightly worse, in terms of compression 
ratio. However, all three are pretty good, considering they are decreasing the size by roughly 3 times.

gzip: 
```
real    0m10.968s
user    0m7.819s        
sys     0m0.075s

real    0m8.954s
user    0m7.801s        
sys     0m0.057s

real    0m9.348s
user    0m7.739s
sys     0m0.122s

compressed ratio: 139257677 / 47109893 ~ 2.956
```

pigz: 
```
real    0m5.770s
user    0m8.187s
sys     0m0.074s

real    0m5.807s
user    0m8.476s
sys     0m0.095s

real    0m5.629s
user    0m8.191s
sys     0m0.119s

compressed ratio: 139257677 / 47008845 ~ 2.962
```

Pigzj:
```
real    0m7.633s
user    0m8.488s
sys     0m0.420s

real    0m7.000s
user    0m8.545s
sys     0m0.374s

real    0m6.759s
user    0m8.488s
sys     0m0.428s

compressed size: 139257677 / 47010417 ~ 2.962
```

**Changing the number of processors:**
In the case where we only have a single thread, we observe that the performance of both parallelized 
programs suffer, both becoming worse than gzip. For pigz, the average real time becomes 14.91s (around
5s worse than gzip), and for Pigzj, the average real time becomes 13.33s (around 3.5s worse than gzip).
Interestingly, Pigzj does better than pigz, when there is only one thread. 

For the other tests, we see an expected pattern of doing better with more processors (more threads running
in parallel). Both pigz and Pigzj improve in real time, when going from 1 processor to 2. For Pigzj, we can 
also see that increasing the number of processors to 10 (more than available resources), actually hurts the 
performance slightly (compared to the default case). This might be due to the overhead of switching between
threads, since not all of them can run at the same time. In each case the user (cpu) time for both Pigzj 
and pigz stays roughly the same. And the sys time for both increases a tiny bit when using more processors. 
This could be attributed to more calls being made to the kernel when scheduling threads. 

1 processor:

pigz:
```
real    0m17.715s
user    0m7.999s
sys     0m0.072s

real    0m14.059s
user    0m8.001s
sys     0m0.090s

real    0m12.959s
user    0m8.150s
sys     0m0.075s
```

Pigzj: 
```
real    0m14.910s
user    0m8.464s
sys     0m0.338s

real    0m13.570s
user    0m8.486s
sys     0m0.343s

real    0m11.518s
user    0m8.457s
sys     0m0.285s
```

2 processors:

pigz:
```
real    0m8.033s
user    0m8.169s
sys     0m0.084s

real    0m6.664s
user    0m8.145s
sys     0m0.093s

real    0m8.915s
user    0m8.312s
sys     0m0.051s
```

Pigzj:
```
real    0m11.132s
user    0m8.680s
sys     0m0.396s

real    0m10.944s
user    0m8.531s
sys     0m0.333s

real    0m8.817s
user    0m8.558s
sys     0m0.325s
```

10 processors:

pigz:
```
real    0m3.701s
user    0m8.199s
sys     0m0.121s

real    0m3.680s
user    0m8.218s
sys     0m0.131s

real    0m3.996s
user    0m8.181s
sys     0m0.122s
```

Pigzj:
```
real    0m7.108s
user    0m8.522s
sys     0m0.420s

real    0m9.104s
user    0m8.566s
sys     0m0.437s

real    0m8.361s
user    0m8.540s
sys     0m0.445s
```

### Strace Analysis: 
In order to compare the system call traces of the three programs, I used the following commands:
``` 
strace gzip <$input >gzip.gz 2>gzip-strace.txt
strace pigz <$input >pigz.gz 2>pigz-strace.txt
strace java Pigzj <$input >Pigzj.gz 2>Pigzj-strace.txt
```

In terms of pure amount of system calls, gzip has by far the most, with 4462 calls. Then pigz follows
that, with 1904 calls. And Pigzj has the lease by far, with 203 calls. The Java implementation has a 
shockingly small amount of system calls, compared to the other programs. From a bit of research, it 
seems to be due to the fact that Java abstracts away many details and operations, as well as performs
several optimizations; this leads to many calls not being visible to strace.

By examining the traces for each program more closely, we observe that the traces for both gzip and 
pigz are dominated by `read` calls, with gzip having 4252 `read` calls and pigz having 1073 `read`
calls. For gzip and pigz, a correlation can be made between performance and number of system calls. 
pigz has almost half the amount of system calls, compared to gzip, and it also performs much better. 
However, with Pigzj, since it's a Java program and most calls are actually being abstracted away 
by the virtual machine, the number of system calls do not tell us anything about the performance of
the program. 

### Potential Problems: 
When the number of threads scale up, performance can actually suffer. When there are many more threads
than there are actual cores available, each thread gets less time with the cpu. Then with wayyy too 
many threads, none of the threads are able to complete their tasks quickly. This also comes with 
the overhead of managing + switching between the threads, as well as memory for keeping track of 
each thread instance. 

Anotehr issue arises as the file size scales up. In this case, we will run into memory issues. As 
blocks of the input are read in, they need to be stored to be compressed. Then after they are
compressed, that compressed data needs to be stored to be outputted. If the file size gets too 
large, we may run out of memory to store all of this data. In my implementation, I tried to save 
on memory by clearing the compressed data that has already been outputted, but this does not get 
rid of the memory usage issue. There can be a situation where too many bytes are read in, and they 
are not being compressed + outputted fast enough; thus we run out of memory. A way we can get around
this would be to have the main thread keep track of how much memory has been used to store data. Then
when the amount of memory reaches a certain threshold, have the main thread wait (so that it stops 
reading the input) until some of that memory is cleared (by compressing and outputting the data). 
Additionally, specifically for my implementation, I can also clear the blocks of raw data and the 
dictionaries that I am storing to decrease the amount of memory I use. 