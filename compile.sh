#!/bin/sh

# Copyright (C) 2020 Lacia chan / Lyceris chan <ghostdrain@outlook.com>
# Copyright (C) 2018 Harsh 'MSF Jarvis' Shandilya
# Copyright (C) 2018 Akhil Narang
# SPDX-License-Identifier: GPL-3.0-only

# If this script is ran by anyone else then Lacia it will simply only setup the compile environment without setting up any telegram / incremental stuff.

# Setup the compile environment / Pull the latest proton-clang from kdrag0n's repo.
FILE="environment/README.md"
if [ -f "$FILE" ]; then
    cd environment || exit
    sh ./proton-clang.sh
    cd ..
else
    git clone https://github.com/Daisy-Q-sources/scripts environment
    cd environment || exit
    sh ./setup_env.sh
    cd ..
fi

# Export and set some variables that will be used later
CORES=$(grep -c ^processor /proc/cpuinfo)
BUILD_START=$(date +"%s")
DATE=$(date)
PARSE_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
COMMIT_POINT="$(git log --pretty=format:'%h : %s' -1)"
PATH="$(pwd)/proton-clang/bin:$PATH"
KBUILD_COMPILER_STRING="$($(pwd)/proton-clang/bin/clang --version | head -n 1 | perl -pe 's/\((?:http|git).*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')"
RELEASE=$(cat incremental/value.dat)

export PATH
export KBUILD_COMPILER_STRING

# Figure out the localversion
rm -rf localv.txt
grep "SUBLEVEL =" Makefile >localv.txt
SUBLVL="$(sed 's/SUBLEVEL = //g' localv.txt)"
LOCALV=4.9.$SUBLVL

# Clean up out
rm -rf out/*

# Compile the kernel
build_clang() {
    make -j"$(nproc --all)" \
	O=out \
	ARCH=arm64 \
    CC="ccache clang" \
    CXX="ccache clang++" \
    AR="ccache llvm-ar" \
    AS="ccache llvm-as" \
    NM="ccache llvm-nm" \
    LD="ccache ld.lld" \
    STRIP="ccache llvm-strip" \
    OBJCOPY="ccache llvm-objcopy" \
    OBJDUMP="ccache llvm-objdump"\
    OBJSIZE="ccache llvm-size" \
    READELF="ccache llvm-readelf" \
    HOSTCC="ccache clang" \
    HOSTCXX="ccache clang++" \
    HOSTAR="ccache llvm-ar" \
    HOSTAS="ccache llvm-as" \
    HOSTNM="ccache llvm-nm" \
    HOSTLD="ccache ld.lld" \
	CROSS_COMPILE=aarch64-linux-gnu- \
	CROSS_COMPILE_ARM32=arm-linux-gnueabi-
}

make O=out ARCH=arm64 sleepy_defconfig
build_clang

# Calculate how long compiling compiling the kernel took
BUILD_END=$(date +"%s")
DIFF=$(($BUILD_END - $BUILD_START))

# Zip up the kernel
zip_kernelimage() {
    rm -rf "$(pwd)"/AnyKernel3/Image.gz-dtb
    cp "$(pwd)"/out/arch/arm64/boot/Image.gz-dtb AnyKernel3
    rm -rf "$(pwd)"/AnyKernel3/*.zip
    BUILD_TIME=$(date +"%d%m%Y-%H%M")
    cd AnyKernel3 || exit
    zip -r9 Sleepy-r"${RELEASE}"-"${BUILD_TIME}".zip ./*
    cd ..
}

FILE="$(pwd)/out/arch/arm64/boot/Image.gz-dtb"
if [ -f "$FILE" ]; then
    zip_kernelimage
    echo "The kernel has successfully been compiled and can be found in $(pwd)/AnyKernel3/Sleepy-r${RELEASE}-${BUILD_TIME}.zip"
    read -r -p "Press enter to continue"
fi
