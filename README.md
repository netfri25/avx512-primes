# Prime generation with AVX512

## About
small implementation of 1M prime numbers generation using some of the AVX512 instructions.

this is just for learning, and you should probably not use it ever for anything other than messing around / learning AVX512.

I've implemented most of it using the help of some really smart people in tsoding's discord server.
###### thanks a lot!: @ikxi, @mrgerman, @x4204, and especially @fiuzeri

## performance
tested on 1M primes with printing turned off on a non-quiet system.
```
non-avx: ~1.291s
avx512:  ~0.967s
```
about `~33%` speedup

## Dependencies
 - `x86-64` architecture
 - linux kernel
 - fasm
 - cpu with [avx512](https://en.wikipedia.org/wiki/AVX-512#CPUs_with_AVX-512)

###### no need for libc :)


## Getting started

#### Build
```shell
fasm main.asm
```

#### Clean
```shell
rm main
```

#### Usage
```shell
./main
```
