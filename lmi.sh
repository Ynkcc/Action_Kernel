#!/usr/bin/env bash
# shellcheck disable=SC2199
# shellcheck disable=SC2086
# shellcheck source=/dev/null
#
# Copyright (C) 2020-22 UtsavBalar1231 <utsavbalar1231@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

apt-get install -y bison build-essential bc bison curl libssl-dev git zip python python3 flex cpio libncurses5-dev wget
# Anykernel3
git clone https://github.com/UtsavBalar1231/Anykernel3 --depth=1 -b kona anykernel

TYPE=REL-6.0.0
DEVICE=lmi
KBUILD_BUILD_USER=UtsavTheCunt
KBUILD_BUILD_HOST=CuntsSpace
HOME=$PWD
PD_API_KEY=01bb9656-2704-4347-8d31-c7635f49e0f2

# Clone compiler
if [[ "$@" =~ "aosp-clang"* ]]; then
	git clone https://android.googlesource.com/platform/prebuilts/gas/linux-x86/ -b master --depth=1 gas
	git clone https://gitlab.com/reinazhard/aosp-clang -b master --depth=1 clang
elif [[ "$@" =~ "gcc"* ]]; then
	git clone https://github.com/mvaisakh/gcc-arm -b gcc-master --depth=1 gcc32
	git clone https://github.com/mvaisakh/gcc-arm64 -b gcc-master --depth=1 gcc64
else
	git clone https://github.com/kdrag0n/proton-clang -b master --depth=1 clang
fi



if [[ "$@" =~ "gcc"* ]]; then
    KBUILD_COMPILER_STRING=$(${HOME}/gcc64/bin/aarch64-elf-gcc --version | head -n1 | sed -e 's/aarch64-elf-gcc\ //' | perl -pe 's/\(//gs' | perl -pe 's/\)//gs')
    KBUILD_LINKER_STRING=$(${HOME}/gcc64/bin/aarch64-elf-ld --version | head -n1 | perl -pe 's/\(//gs' | perl -pe 's/\)//gs')
else
    KBUILD_COMPILER_STRING=$(${HOME}/clang/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')
    KBUILD_LINKER_STRING=$(${HOME}/clang/bin/ld.lld --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//' | sed 's/(compatible with [^)]*)//')
fi

export KBUILD_COMPILER_STRING
export KBUILD_LINKER_STRING

#
# Enviromental Variables
#

# Set the last commit author
AUTHOR=$(git log -n 1 --pretty=format:'%an')

# Set the current branch name
BRANCH=$(git rev-parse --symbolic-full-name --abbrev-ref HEAD)

# Set the last commit sha
COMMIT=$(git rev-parse --short HEAD)

# Set current date
DATE=$(date +"%d.%m.%y")

# Set Kernel link
KERNEL_LINK=https://github.com/UtsavBalar1231/kernel_xiaomi_sm8250

# Set Kernel Version
KERNELVER=$(make kernelversion)

# Set Post Message
MESSAGE="$AUTHOR: $REF$KERNEL_LINK/commit/$COMMIT"

# Set our directory
OUT_DIR=${HOME}/out

if [[ "$@" =~ "gcc"* ]]; then
    VERSION=$(echo "${KBUILD_COMPILER_STRING}" | awk '{print $1,$2,$3}')
elif [[ "$@" =~ "aosp-clang"* ]]; then
    if [[ -f ${HOME}/clang/AndroidVersion.txt ]]; then
        VERSION=$(cat ${HOME}/clang/AndroidVersion.txt | head -1)
    fi
else
    VERSION=""
fi
export VERSION

# Set Compiler
if [[ "$@" =~ "gcc"* ]]; then
    COMPILER=${VERSION}
elif [[ "$@" =~ "aosp-clang"* ]]; then
    COMPILER="AOSP Clang ${VERSION}"
else
    COMPILER="Proton Clang ${VERSION}"
fi
export COMPILER

# Get reference string
REF=$(echo "${BRANCH}" | grep -Eo "[^ /]+\$")

CSUM=$(cksum <<<${COMMIT} | cut -f 1 -d ' ')

# Select LTO or non LTO builds
if [[ "$@" =~ "lto"* ]]; then
    VERSION="IMMENSITY-X-${DEVICE^^}-${TYPE}-LTO-${CSUM}-${DATE}"
else
    VERSION="IMMENSITY-X-${DEVICE^^}-${TYPE}-${CSUM}-${DATE}"
fi

# Export Zip name
export ZIPNAME="${VERSION}.zip"

# How much kebabs we need? Kanged from @raphielscape :)
if [[ -z "${KEBABS}" ]]; then
    COUNT="$(grep -c '^processor' /proc/cpuinfo)"
    export KEBABS="$((COUNT * 2))"
fi

if [[ "$@" =~ "gcc"* ]]; then
    ARGS="ARCH=arm64 \
    O=${OUT_DIR} \
    CROSS_COMPILE=aarch64-elf- \
    CROSS_COMPILE_COMPAT=arm-eabi- \
    -j${KEBABS}
    "
else
    ARGS="ARCH=arm64 \
    O=${OUT_DIR} \
    LLVM=1 \
    LLVM_IAS=1 \
    CLANG_TRIPLE=aarch64-linux-gnu- \
    CROSS_COMPILE=aarch64-linux-gnu- \
    CROSS_COMPILE_COMPAT=arm-linux-gnueabi- \
    -j${KEBABS}
"
fi

dts_source=arch/arm64/boot/dts/vendor/qcom
# Correct panel dimensions on MIUI builds
function miui_fix_dimens() {
    sed -i 's/<70>/<695>/g' $dts_source/dsi-panel-j3s-37-02-0a-dsc-video.dtsi
    sed -i 's/<70>/<695>/g' $dts_source/dsi-panel-j11-38-08-0a-fhd-cmd.dtsi
    sed -i 's/<70>/<695>/g' $dts_source/dsi-panel-l11r-38-08-0a-dsc-cmd.dtsi
    sed -i 's/<70>/<695>/g' $dts_source/dsi-panel-k11a-38-08-0a-dsc-cmd.dtsi
    sed -i 's/<71>/<710>/g' $dts_source/dsi-panel-j1s*
    sed -i 's/<71>/<710>/g' $dts_source/dsi-panel-j2*
    sed -i 's/<155>/<1544>/g' $dts_source/dsi-panel-j3s-37-02-0a-dsc-video.dtsi
    sed -i 's/<155>/<1545>/g' $dts_source/dsi-panel-j11-38-08-0a-fhd-cmd.dtsi
    sed -i 's/<155>/<1546>/g' $dts_source/dsi-panel-l11r-38-08-0a-dsc-cmd.dtsi
    sed -i 's/<155>/<1546>/g' $dts_source/dsi-panel-k11a-38-08-0a-dsc-cmd.dtsi
    sed -i 's/<154>/<1537>/g' $dts_source/dsi-panel-j1s*
    sed -i 's/<154>/<1537>/g' $dts_source/dsi-panel-j2*
}

# Enable back mi smartfps while disabling qsync min refresh-rate
function miui_fix_fps() {
    sed -i 's/qcom,mdss-dsi-qsync-min-refresh-rate/\/\/qcom,mdss-dsi-qsync-min-refresh-rate/g' $dts_source/dsi-panel*
    sed -i 's/\/\/ mi,mdss-dsi-smart-fps-max_framerate/mi,mdss-dsi-smart-fps-max_framerate/g' $dts_source/dsi-panel*
    sed -i 's/\/\/ mi,mdss-dsi-pan-enable-smart-fps/mi,mdss-dsi-pan-enable-smart-fps/g' $dts_source/dsi-panel*
    sed -i 's/\/\/ qcom,mdss-dsi-pan-enable-smart-fps/qcom,mdss-dsi-pan-enable-smart-fps/g' $dts_source/dsi-panel*
}

# Enable back refresh rates supported on MIUI
function miui_fix_dfps() {
    sed -i 's/120 90 60/120 90 60 50 30/g' $dts_source/dsi-panel-g7a-37-02-0a-dsc-video.dtsi
    sed -i 's/120 90 60/120 90 60 50 30/g' $dts_source/dsi-panel-g7a-37-02-0b-dsc-video.dtsi
    sed -i 's/120 90 60/120 90 60 50 30/g' $dts_source/dsi-panel-g7a-36-02-0c-dsc-video.dtsi
    sed -i 's/144 120 90 60/144 120 90 60 50 48 30/g' $dts_source/dsi-panel-j3s-37-02-0a-dsc-video.dtsi
}

# Enable back brightness control from dtsi
function miui_fix_fod() {
    sed -i 's/\/\/39 01 00 00 01 00 03 51 03 FF/39 01 00 00 01 00 03 51 03 FF/g' $dts_source/dsi-panel-j11-38-08-0a-fhd-cmd.dtsi
    sed -i 's/\/\/39 01 00 00 00 00 03 51 03 FF/39 01 00 00 00 00 03 51 03 FF/g' $dts_source/dsi-panel-j11-38-08-0a-fhd-cmd.dtsi
    sed -i 's/\/\/39 00 00 00 00 00 05 51 0F 8F 00 00/39 00 00 00 00 00 05 51 0F 8F 00 00/g' $dts_source/dsi-panel-j1s-42-02-0a-dsc-cmd.dtsi
    sed -i 's/\/\/39 01 00 00 00 00 05 51 07 FF 00 00/39 01 00 00 00 00 05 51 07 FF 00 00/g' $dts_source/dsi-panel-j1s-42-02-0a-dsc-cmd.dtsi
    sed -i 's/\/\/39 00 00 00 00 00 05 51 0F 8F 00 00/39 00 00 00 00 00 05 51 0F 8F 00 00/g' $dts_source/dsi-panel-j1s-42-02-0a-mp-dsc-cmd.dtsi
    sed -i 's/\/\/39 01 00 00 00 00 05 51 07 FF 00 00/39 01 00 00 00 00 05 51 07 FF 00 00/g' $dts_source/dsi-panel-j1s-42-02-0a-mp-dsc-cmd.dtsi
    sed -i 's/\/\/39 01 00 00 00 00 03 51 0F FF/39 01 00 00 00 00 03 51 0F FF/g' $dts_source/dsi-panel-j1u-42-02-0b-dsc-cmd.dtsi
    sed -i 's/\/\/39 01 00 00 00 00 03 51 07 FF/39 01 00 00 00 00 03 51 07 FF/g' $dts_source/dsi-panel-j1u-42-02-0b-dsc-cmd.dtsi
    sed -i 's/\/\/39 01 00 00 00 00 03 51 00 00/39 01 00 00 00 00 03 51 00 00/g' $dts_source/dsi-panel-j2-38-0c-0a-dsc-cmd.dtsi
    sed -i 's/\/\/39 01 00 00 00 00 03 51 00 00/39 01 00 00 00 00 03 51 00 00/g' $dts_source/dsi-panel-j2-38-0c-0a-dsc-cmd.dtsi
    sed -i 's/\/\/39 01 00 00 00 00 03 51 0F FF/39 01 00 00 00 00 03 51 0F FF/g' $dts_source/dsi-panel-j2-42-02-0b-dsc-cmd.dtsi
    sed -i 's/\/\/39 01 00 00 00 00 03 51 07 FF/39 01 00 00 00 00 03 51 07 FF/g' $dts_source/dsi-panel-j2-42-02-0b-dsc-cmd.dtsi
    sed -i 's/\/\/39 00 00 00 00 00 05 51 0F 8F 00 00/39 00 00 00 00 00 05 51 0F 8F 00 00/g' $dts_source/dsi-panel-j2-mp-42-02-0b-dsc-cmd.dtsi
    sed -i 's/\/\/39 01 00 00 00 00 05 51 07 FF 00 00/39 01 00 00 00 00 05 51 07 FF 00 00/g' $dts_source/dsi-panel-j2-mp-42-02-0b-dsc-cmd.dtsi
    sed -i 's/\/\/39 01 00 00 00 00 03 51 0F FF/39 01 00 00 00 00 03 51 0F FF/g' $dts_source/dsi-panel-j2-p1-42-02-0b-dsc-cmd.dtsi
    sed -i 's/\/\/39 01 00 00 00 00 03 51 07 FF/39 01 00 00 00 00 03 51 07 FF/g' $dts_source/dsi-panel-j2-p1-42-02-0b-dsc-cmd.dtsi
    sed -i 's/\/\/39 00 00 00 00 00 03 51 0D FF/39 00 00 00 00 00 03 51 0D FF/g' $dts_source/dsi-panel-j2-p2-1-38-0c-0a-dsc-cmd.dtsi
    sed -i 's/\/\/39 01 00 00 11 00 03 51 03 FF/39 01 00 00 11 00 03 51 03 FF/g' $dts_source/dsi-panel-j2-p2-1-38-0c-0a-dsc-cmd.dtsi
    sed -i 's/\/\/39 00 00 00 00 00 05 51 0F 8F 00 00/39 00 00 00 00 00 05 51 0F 8F 00 00/g' $dts_source/dsi-panel-j2-p2-1-42-02-0b-dsc-cmd.dtsi
    sed -i 's/\/\/39 01 00 00 00 00 05 51 07 FF 00 00/39 01 00 00 00 00 05 51 07 FF 00 00/g' $dts_source/dsi-panel-j2-p2-1-42-02-0b-dsc-cmd.dtsi
    sed -i 's/\/\/39 00 00 00 00 00 05 51 0F 8F 00 00/39 00 00 00 00 00 05 51 0F 8F 00 00/g' $dts_source/dsi-panel-j2s-mp-42-02-0a-dsc-cmd.dtsi
    sed -i 's/\/\/39 01 00 00 00 00 05 51 07 FF 00 00/39 01 00 00 00 00 05 51 07 FF 00 00/g' $dts_source/dsi-panel-j2s-mp-42-02-0a-dsc-cmd.dtsi
    sed -i 's/\/\/39 00 00 00 00 00 03 51 03 FF/39 00 00 00 00 00 03 51 03 FF/g' $dts_source/dsi-panel-j9-38-0a-0a-fhd-video.dtsi
    sed -i 's/\/\/39 01 00 00 00 00 03 51 03 FF/39 01 00 00 00 00 03 51 03 FF/g' $dts_source/dsi-panel-j9-38-0a-0a-fhd-video.dtsi
}

# Post to CI channel
function tg_post_msg() {
echo "tg_post_msg"
}

function tg_post_error() {
echo "tg_post_error"
}

function enable_lto() {
    if [ "$1" == "gcc" ]; then
        scripts/config --file ${OUT_DIR}/.config \
            -e LTO_GCC \
            -e LD_DEAD_CODE_DATA_ELIMINATION \
            -d MODVERSIONS
    else
        scripts/config --file ${OUT_DIR}/.config \
            -e LTO_CLANG
    fi

    # Make olddefconfig
    cd ${OUT_DIR} || exit
    make -j${KEBABS} ${ARGS} olddefconfig
    cd ../ || exit
}

function disable_lto() {
    if [ "$1" == "gcc" ]; then
        scripts/config --file ${OUT_DIR}/.config \
            -d LTO_GCC \
            -d LD_DEAD_CODE_DATA_ELIMINATION \
            -e MODVERSIONS
    else
        scripts/config --file ${OUT_DIR}/.config \
            -d LTO_CLANG
    fi
}

function pack_image_build() {
    mkdir -p anykernel/kernels/$1

    # Check if the kernel is built
    if [[ -f ${OUT_DIR}/System.map ]]; then
        if [[ -f ${OUT_DIR}/arch/arm64/boot/Image.gz ]]; then
            cp ${OUT_DIR}/arch/arm64/boot/Image.gz anykernel/kernels/$1
        elif [[ -f ${OUT_DIR}/arch/arm64/boot/Image ]]; then
            cp ${OUT_DIR}/arch/arm64/boot/Image anykernel/kernels/$1
        else
            tg_post_error $1
        fi
    else
        tg_post_error $1
    fi

    cp ${OUT_DIR}/arch/arm64/boot/dtb anykernel/kernels/$1
    cp ${OUT_DIR}/arch/arm64/boot/dtbo.img anykernel/kernels/$1
}

START=$(date +"%s")

tg_post_msg

# Set compiler Path
if [[ "$@" =~ "gcc"* ]]; then
    PATH=${HOME}/gcc64/bin:${HOME}/gcc32/bin:${PATH}
elif [[ "$@" =~ "aosp-clang"* ]]; then
    PATH=${HOME}/gas:${HOME}/clang/bin/:$PATH
    export LD_LIBRARY_PATH=${HOME}/clang/lib64:${LD_LIBRARY_PATH}
else
    PATH=${HOME}/clang/bin/:${PATH}
fi

# Make defconfig
make -j${KEBABS} ${ARGS} "${DEVICE}"_defconfig

# AOSP Build
echo "------ Stating AOSP Build ------"
OS=aosp

if [[ "$@" =~ "lto"* ]]; then
    # Enable LTO
    if [[ "$@" =~ "gcc"* ]]; then
        enable_lto gcc
    else
        enable_lto clang
    fi

    # Make olddefconfig
    cd ${OUT_DIR} || exit
    make -j${KEBABS} ${ARGS} olddefconfig
    cd ../ || exit

fi

make -j${KEBABS} ${ARGS} 2>&1 | tee build.log
find ${OUT_DIR}/$dts_source -name '*.dtb' -exec cat {} + >${OUT_DIR}/arch/arm64/boot/dtb

pack_image_build ${OS}
echo "------ Finishing AOSP Build ------"

# MIUI Build
echo "------ Starting MIUI Build ------"
OS=miui

# Make defconfig
make -j${KEBABS} ${ARGS} "${DEVICE}"_defconfig

scripts/config --file ${OUT_DIR}/.config \
    -d LOCALVERSION_AUTO \
    -d TOUCHSCREEN_COMMON \
    --set-str STATIC_USERMODEHELPER_PATH /system/bin/micd \
    -e BOOT_INFO \
    -e BINDER_OPT \
    -e IPC_LOGGING \
    -e KPERFEVENTS \
    -e MIGT \
    -e MIGT_ENERGY_MODEL \
    -e MIHW \
    -e MILLET \
    -e MI_DRM_OPT \
    -e MIUI_ZRAM_MEMORY_TRACKING \
    -e MI_RECLAIM \
    -d OSSFOD \
    -e PACKAGE_RUNTIME_INFO \
    -e PERF_HUMANTASK \
    -e PERF_CRITICAL_RT_TASK \
    -e SF_BINDER \
    -e TASK_DELAY_ACCT

if [[ "$@" =~ "lto"* ]]; then
    if [[ "$@" =~ "gcc"* ]]; then
        # Enable GCC LTO
        enable_lto gcc
    fi
fi
# Make olddefconfig
cd ${OUT_DIR} || exit
make -j${KEBABS} ${ARGS} olddefconfig
cd ../ || exit

miui_fix_dimens
miui_fix_fps
miui_fix_dfps
miui_fix_fod

make -j${KEBABS} ${ARGS} 2>&1 | tee build.log

find ${OUT_DIR}/$dts_source -name '*.dtb' -exec cat {} + >${OUT_DIR}/arch/arm64/boot/dtb

pack_image_build ${OS}

git checkout arch/arm64/boot/dts/vendor &>/dev/null
echo "------ Finishing MIUI Build ------"

# AOSPA Build
echo "------ Starting AOSPA Build ------"
OS=aospa

# Make defconfig
make -j${KEBABS} ${ARGS} "${DEVICE}"_defconfig

scripts/config --file ${OUT_DIR}/.config \
    -d SDCARD_FS \
    -e UNICODE

if [[ "$@" =~ "lto"* ]]; then
    # Enable LTO
    if [[ "$@" =~ "gcc"* ]]; then
        enable_lto gcc
    else
        enable_lto clang
    fi
fi

# Make olddefconfig
cd ${OUT_DIR} || exit
make -j${KEBABS} ${ARGS} olddefconfig
cd ../ || exit

make -j${KEBABS} ${ARGS} 2>&1 | tee build.log

find ${OUT_DIR}/$dts_source -name '*.dtb' -exec cat {} + >${OUT_DIR}/arch/arm64/boot/dtb

pack_image_build ${OS}
echo "------ Finishing AOSPA Build ------"

END=$(date +"%s")
DIFF=$((END - START))

cd anykernel || exit
zip -r9 "${ZIPNAME}" ./* -x .git .gitignore ./*.zip
cp ${ZIPNAME} ${OUT_DIR}/arch/arm64/boot/lmi.zip
RESPONSE=$(curl -# -F "name=${ZIPNAME}" -F "file=@${ZIPNAME}" -u :"${PD_API_KEY}" https://pixeldrain.com/api/file)
FILEID=$(echo "${RESPONSE}" | grep -Po '(?<="id":")[^"]*')

CHECKER=$(find ./ -maxdepth 1 -type f -name "${ZIPNAME}" -printf "%s\n")
if (($((CHECKER / 1048576)) > 5)); then
	echo"假装发了通知"
else
    tg_post_error
fi
cd "$(pwd)" || exit

# Cleanup
rm -fr anykernel/
