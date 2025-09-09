# Prime generation with AVX512

## About
small implementation of 1M prime numbers generation using some of the AVX512 instructions.

this is just for learning, and you should probably not use it ever for anything other than messing around / learning AVX512.

I've implemented most of it using the help of some really smart people in tsoding's discord server.
###### thanks a lot!: @ikxi, @mrgerman, @x4204, and especially @fiuzeri

## What I've learned
 - how to implement trailing zero count (thanks to @fiuzeri)
 - fasm macro
 - wheel method for prime generation
 - proper masking of packed vector instructions
 - there's no form of modulo nor integer division in avx512
 - divisibility check can be done using gcd
 - instrucions
    * `kand`
    * `kandn`
    * `kmov`
    * `knot`
    * `kor`
    * `kortest`
    * `vmovdqa32` (and the difference between the 64 version)
    * `vmovdqu32` (and the difference between the 64 version)
    * `vpadd`
    * `vpandn`
    * `vpcmpeq`
    * `vpcmpgt`
    * `vpcompress`
    * `vplzcnt`
    * `vpmax`
    * `vpmin`
    * `vpmuldq`
    * `vpmulhu`
    * `vpmull`
    * `vpmuludq`
    * `vpsrl`
    * `vpsrlv`
    * `vpternlog`
    * `vptestm`

## performance
tested on 1M primes with printing turned off on a non-quiet system.
```
regular: ~1.291s
avx512:  ~0.691s
```
about `~86.831%` speedup

## Dependencies
 - `x86-64` architecture
 - linux kernel
 - fasm
 - make
 - cpu with [avx512](https://en.wikipedia.org/wiki/AVX-512#CPUs_with_AVX-512)

###### no need for libc :)


## Getting started

#### Build
```shell
make
```

#### Clean
```shell
make clean
```

#### Usage
```shell
./build/trial-division/avx
```
