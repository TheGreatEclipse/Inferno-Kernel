#!/usr/bin/env bash
#
SECONDS=0
ZIPNAME="Inferno-Ginkgo-$(TZ=Asia/Baku date +"%Y%m%d-%H%M").zip"
TC_DIR="/home/xmoon/Documents/GINKGO/Kernel_Build/Toolchain/"
CLANG_DIR="${TC_DIR}clang-r498229b"
GCC_64_DIR="${TC_DIR}android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9"
GCC_32_DIR="${TC_DIR}android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9"
AK3_DIR="$(pwd)/AnyKernel3"
DEFCONFIG="vendor/ginkgo_defconfig"

# ===== Set timezone =====
export TZ=Asia/Jakarta


# ===== ENV =====
export PATH="$CLANG_DIR/bin:$PATH"
export LD_LIBRARY_PATH="$CLANG_DIR/lib:$LD_LIBRARY_PATH"
export KBUILD_BUILD_VERSION="1"
export LOCALVERSION



mkdir -p out
make O=out ARCH=arm64 $DEFCONFIG

# ===== BUILD =====
echo "🔨 Compilation Started"
make -j$(nproc --all) O=out \
ARCH=arm64 \
CC=clang \
LD=ld.lld \
AR=llvm-ar \
AS=llvm-as \
NM=llvm-nm \
OBJCOPY=llvm-objcopy \
OBJDUMP=llvm-objdump \
STRIP=llvm-strip \
CROSS_COMPILE=aarch64-linux-android- \
CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
CLANG_TRIPLE=aarch64-linux-gnu- \
Image.gz-dtb \
dtbo.img 2>&1 | tee log.txt

# ===== CHECK RESULT =====
if [ -f "out/arch/arm64/boot/Image.gz-dtb" ] && [ -f "out/arch/arm64/boot/dtbo.img" ]; then
echo "✅ Build Success"
echo "Zipping kernel..."

if [ -d "$AK3_DIR" ]; then
cp -r $AK3_DIR AnyKernel3
else
git clone -q https://github.com/neophyteprjkt/AnyKernel3
fi

cp out/arch/arm64/boot/Image.gz-dtb AnyKernel3
cp out/arch/arm64/boot/dtbo.img AnyKernel3

rm -rf *zip
cd AnyKernel3
git checkout main &> /dev/null
zip -r9 "../$ZIPNAME" * -x '*.git*' README.md *placeholder
cd ..

echo "📦 Kernel Build Finished"
echo "⏱ Time: $((SECONDS / 60))m $((SECONDS % 60))s"

rm -rf AnyKernel3
rm -rf out/arch/arm64/boot
else
echo "❌ Build Failed"
echo "Check log.txt"
fi

echo "🎉 Done!"
