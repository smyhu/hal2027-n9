#!/bin/sh
# Cross-build hal2027-rec for the Nokia N9 (Harmattan, hard-float ARMv7). Same toolchain as build-fetch.sh.
set -e
TC=${TC:-/tmp/claude-0/x/tc}
H=$TC/hdr/usr/arm-linux-gnueabihf
T="--target=arm-linux-gnueabihf -march=armv7-a -mtune=cortex-a8 -mfpu=neon -mfloat-abi=hard -mthumb"
CF="$T -O2 -fno-pic -nostdinc -isystem $(clang -print-resource-dir)/include -isystem $H/include -U_FORTIFY_SOURCE -fno-stack-protector -D_FILE_OFFSET_BITS=32"
O=${TMPDIR:-/tmp}/halrec.o
clang $CF -c "$1" -o $O
clang $T --ld-path=$TC/ld-arm -no-pie -nostdlib -Wl,--allow-shlib-undefined -Wl,--gc-sections -Wl,--hash-style=both -Wl,-z,norelro -Wl,-dynamic-linker,/lib/ld-linux.so.3 \
  $H/lib/crt1.o $H/lib/crti.o $TC/hdr/usr/lib/gcc-cross/arm-linux-gnueabihf/13/crtbegin.o $O \
  $TC/sysroot/usr/lib/libpulse-simple.so.0 $TC/sysroot/usr/lib/libpulse.so.0 $TC/sysroot/lib/libc.so.6 \
  $TC/hdr/usr/lib/gcc-cross/arm-linux-gnueabihf/13/crtend.o $H/lib/crtn.o -o "$2"
llvm-strip "$2" 2>/dev/null || true
