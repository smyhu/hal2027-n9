#!/bin/sh
# Cross-build espeak-ng CLI (static lib inside) for the Nokia N9 (armhf, glibc 2.10)
set -e
TC=${TC:-/tmp/claude-0/x/tc}
H=$TC/hdr/usr/arm-linux-gnueabihf
T="--target=arm-linux-gnueabihf -march=armv7-a -mtune=cortex-a8 -mfpu=neon -mfloat-abi=hard -mthumb"
CF="$T -O2 -fno-pic -nostdinc -isystem $(clang -print-resource-dir)/include -isystem $H/include -U_FORTIFY_SOURCE -fno-stack-protector -D_FILE_OFFSET_BITS=32 -std=c99 -D_DEFAULT_SOURCE -fwrapv -fvisibility=hidden"
S=$(pwd)
O=$S/build-arm; mkdir -p $O
INC="-I $S/build-host/src/libespeak-ng/include -I $S/src/include -I $S/src/include/compat -I $S/src/ucd-tools/src/include -I $S/src/libespeak-ng"
for f in common mnemonics error ieee80 compiledata compiledict dictionary encoding intonation langopts numbers phoneme phonemelist readclause setlengths soundicon spect ssml synthdata synthesize tr_languages translate translateword voices wavegen speech espeak_api; do
  clang $CF $INC -DLIBESPEAK_NG_EXPORT=1 -DPATH_ESPEAK_DATA='"/opt/hal2027/espeak-ng-data"' -c src/libespeak-ng/$f.c -o $O/$f.o
done
for f in src/ucd-tools/src/*.c; do clang $CF $INC -c $f -o $O/ucd-$(basename $f .c).o; done
clang $CF $INC -DLIBESPEAK_NG_EXPORT=1 -c src/espeak-ng.c -o $O/main.o
clang $CF -c $(dirname "$0")/stat-shim.c -o $O/stat-shim.o
clang $T --ld-path=$TC/ld-arm -no-pie -nostdlib -Wl,--allow-shlib-undefined -Wl,--gc-sections -Wl,--hash-style=both -Wl,-z,norelro -Wl,-dynamic-linker,/lib/ld-linux.so.3 \
  $H/lib/crt1.o $H/lib/crti.o $TC/hdr/usr/lib/gcc-cross/arm-linux-gnueabihf/13/crtbegin.o $O/*.o \
  $TC/sysroot/lib/libm.so.6 $TC/sysroot/lib/libc.so.6 $TC/sysroot/lib/libgcc_s.so.1 \
  $TC/hdr/usr/lib/gcc-cross/arm-linux-gnueabihf/13/crtend.o $H/lib/crtn.o -o $O/espeak-ng
llvm-strip $O/espeak-ng
