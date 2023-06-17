#!/bin/bash
echored () {
  echo "${TEXTRED}$1${TEXTRESET}"
}

echogreen () {
  echo "${TEXTGREEN}$1${TEXTRESET}"
}

TEXTRESET=$(tput sgr0)
TEXTGREEN=$(tput setaf 2)
TEXTRED=$(tput setaf 1)

export TOOLCHAIN=$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64
export ARCH=$1
export API=32

[ -z $ARCH ] && ARCH=arm
case $ARCH in
    arm64|aarch64) ARCH=aarch64; TARGET=aarch64-linux-android;;
    arm) ARCH=arm; TARGET=armv7a-linux-androideabi;;
    x64|x86_64) ARCH=x86_64; TARGET=x86_64-linux-android;;
    x86|i686) ARCH=i686; TARGET=i686-linux-android;;
    *) echored "Invalid arch: $ARCH!"; exit 1;;
esac

export AR=$TOOLCHAIN/bin/llvm-ar
export CC=$TOOLCHAIN/bin/$TARGET$API-clang
export AS=$CC
export CXX=$TOOLCHAIN/bin/$TARGET$API-clang++
export LD=$TOOLCHAIN/bin/ld
export RANLIB=$TOOLCHAIN/bin/llvm-ranlib
export STRIP=$TOOLCHAIN/bin/llvm-strip
export GCC=$CC
export GXX=$CXX

sed -i 's/-rdynamic//g' configure.ac
sed -i '/strtoimax/Id' configure.ac
sed -i '/strtoimax/d' Makefile.in
sed -i -e 's/strtoimax.c strtoumax.c/strtoumax.c/' -e '/strtoimax/d' lib/sh/Makefile.in
rm -f m4/strtoimax.m4 lib/sh/strtoimax.c

echogreen "Configuring"
./configure CFLAGS="-g -O2 -static" LDFLAGS="-g -O2 -static" \
  --host=$TARGET --target=$TARGET --prefix=$PREFIX \
  --enable-static-link \
  --disable-nls \
  --without-bash-malloc \
  --enable-largefile \
  --enable-alias \
  --enable-readline \
  --enable-history \
  --enable-multibyte \
  --enable-job-control \
  --enable-array-variables \
  bash_cv_dev_fd=whacky \
  bash_cv_getcwd_malloc=yes \
  bash_cv_job_control_missing=present \
  bash_cv_sys_siglist=yes \
  bash_cv_func_sigsetjmp=present \
  bash_cv_unusable_rtsigs=no \
  ac_cv_func_mbsnrtowcs=no
[ $? -eq 0 ] || { echored "Configure failed!"; exit 1; }

sed -i 's/${LIBOBJDIR}mbschr$U.o ${LIBOBJDIR}strtoimax$U.o/${LIBOBJDIR}mbschr$U.o/' lib/sh/Makefile

echogreen "Building"
make -j16
[ $? -eq 0 ] && { $STRIP "bash"; echogreen "Bash binary built sucessfully"; }