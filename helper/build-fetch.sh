#!/bin/sh
# Cross-build hal2027-fetch for the Nokia N9 (Harmattan, hard-float ARMv7).
# TC = folder with hdr/ (Ubuntu armhf cross headers+crt), sysroot/ (N9 libs),
# qtdev/ (Harmattan libqt4-dev headers), ld-arm (GNU ld wrapper).
set -e
TC=${TC:-/tmp/claude-0/x/tc}
H=$TC/hdr/usr/arm-linux-gnueabihf
Q=$TC/qtdev/usr/include/qt4
T="--target=arm-linux-gnueabihf -march=armv7-a -mtune=cortex-a8 -mfpu=neon -mfloat-abi=hard -mthumb"
CF="$T -O2 -fno-pic -nostdinc -isystem $(clang -print-resource-dir)/include -isystem $H/include/c++/13 -isystem $H/include/c++/13/arm-linux-gnueabihf -isystem $H/include -U_FORTIFY_SOURCE -D_FILE_OFFSET_BITS=32"
clang++ $CF -std=gnu++98 -fno-rtti -fno-exceptions -fno-threadsafe-statics -DQT_NO_DEBUG -DQT_SHARED -I $Q -c "$1" -o /tmp/halfetch.o
clang++ $T --ld-path=$TC/ld-arm -no-pie -nostdlib -Wl,--allow-shlib-undefined -Wl,--gc-sections -Wl,--as-needed -Wl,--hash-style=both -Wl,-z,norelro -Wl,-dynamic-linker,/lib/ld-linux.so.3 \
  $H/lib/crt1.o $H/lib/crti.o $TC/hdr/usr/lib/gcc-cross/arm-linux-gnueabihf/13/crtbegin.o /tmp/halfetch.o \
  $TC/sysroot/usr/lib/libQtNetwork.so.4 $TC/sysroot/usr/lib/libQtCore.so.4 $TC/sysroot/usr/lib/libstdc++.so.6 $TC/sysroot/lib/libc.so.6 $TC/sysroot/lib/libgcc_s.so.1 \
  $TC/hdr/usr/lib/gcc-cross/arm-linux-gnueabihf/13/crtend.o $H/lib/crtn.o -o "$2"
llvm-strip "$2" 2>/dev/null || true
