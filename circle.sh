#!/usr/bin/env bash
# Copyright (C) 2019-2020 Jago Gardiner (nysascape)
#
# Licensed under the Raphielscape Public License, Version 1.d (the "License");
# you may not use this file except in compliance with the License.
#
# CI build script

# Needed exports
export TELEGRAM_TOKEN=1206672611:AAGYbqxf4SN8f_Zsg3pa6nxOltilb3e8IN0
export ANYKERNEL=$(pwd)/anykernel3

# Avoid hardcoding things
KERNEL=STRIX
DEFCONFIG=whyred_defconfig
DEVICE=whyred
CIPROVIDER=CircleCI
PARSE_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
PARSE_ORIGIN="$(git config --get remote.origin.url)"
COMMIT_POINT="$(git log --pretty=format:'%h : %s' -1)"

# Export custom KBUILD
export KBUILD_BUILD_USER=builder
export KBUILD_BUILD_HOST=fiqriardyansyah

# Export image file
export KERN_IMG=${OUTDIR}/arch/arm64/boot/Image.gz-dtb

# Kernel channel
CI_CHANNEL=-1001466536460
TG_GROUP=-1001287488921

# Set default local datetime
DATE=$(TZ=Asia/Jakarta date +"%Y%m%d-%T")
BUILD_DATE=$(TZ=Asia/Jakarta date +"%Y%m%d-%H%M")

# Kernel revision
KERNELTYPE=EAS
KERNELRELEASE=test

# Function to replace defconfig versioning
setversioning() {

    # For staging branch
    KERNELNAME="${KERNEL}-${KERNELTYPE}-${KERNELRELEASE}-nightly-${BUILD_DATE}-oldcam"

    # Export our new localversion and zipnames
    export KERNELTYPE KERNELNAME
    export TEMPZIPNAME="${KERNELNAME}-unsigned.zip"
    export ZIPNAME="${KERNELNAME}.zip"
}

# Send to channel
tg_channelcast() {
    "${TELEGRAM}" -c "${CI_CHANNEL}" -H \
    "$(
		for POST in "${@}"; do
			echo "${POST}"
		done
    )"
}

# Send to main group
tg_groupcast() {
    "${TELEGRAM}" -c "${TG_GROUP}" -H \
    "$(
        for POST in "${@}"; do
            echo "${POST}"
        done
    )"
}

paste() {
    curl -F document=build.log "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" \
            -F chat_id="$CI_CHANNEL" \
            -F "disable_web_page_preview=true" \
            -F "parse_mode=html" 
}

# Fin Error
finerr() {
        paste
        curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage" \
            -d chat_id="$CI_CHANNEL" \
            -d "disable_web_page_preview=true" \
            -d "parse_mode=markdown" \
            -d text="Build throw an error(s)"
}

# Fix long kernel strings
kernelstringfix() {
    git config --global user.name "Fiqri Ardyansyah"
    git config --global user.email "fiqri15072019@gmail.com"
    git add .
    git commit -m "stop adding dirty"
}

# Clone Anykernel3
cloneak3() {
    rm -rf anykernel3
    git clone https://github.com/fiqri19102002/AnyKernel3.git -b whyred-aosp anykernel3
}

# Make the kernel
makekernel() {
    kernelstringfix
    export CROSS_COMPILE="${KERNELDIR}/gcc/bin/aarch64-linux-gnu-"
    export CROSS_COMPILE_ARM32="${KERNELDIR}/gcc32/bin/arm-eabi-"
    make O=out ARCH=arm64 ${DEFCONFIG}
    make -j$(nproc --all) O=out ARCH=arm64

    # Check if compilation is done successfully.
    if ! [ -f "${OUTDIR}"/arch/arm64/boot/Image.gz-dtb ]; then
	    END=$(date +"%s")
	    DIFF=$(( END - START ))
	    echo -e "Kernel compilation failed, See buildlog to fix errors"
	    tg_channelcast "Build for ${DEVICE} <b>failed</b> in $((DIFF / 60)) minute(s) and $((DIFF % 60)) second(s)! Check ${CIPROVIDER} for errors!"
        tg_groupcast "Build for ${DEVICE} <b>failed</b> in $((DIFF / 60)) minute(s) and $((DIFF % 60)) second(s)! Check ${CIPROVIDER} for errors @unknown_name123 !!!"
	    exit 1
    fi
}

# Ship the compiled kernel
shipkernel() {
    # Copy compiled kernel
    cp "${KERN_IMG}" "${ANYKERNEL}"

    # Zip the kernel, or fail
    cd "${ANYKERNEL}" || exit
    zip -r9 "${TEMPZIPNAME}" *

    # Sign the zip before sending it to Telegram
    curl -sLo zipsigner-3.0.jar https://raw.githubusercontent.com/baalajimaestro/AnyKernel2/master/zipsigner-3.0.jar
    java -jar zipsigner-3.0.jar ${TEMPZIPNAME} ${ZIPNAME}

    # Ship it to the CI channel
    "${TELEGRAM}" -f "$ZIPNAME" -c "${CI_CHANNEL}"

    # Go back for any extra builds
    cd ..
}

# Ship China firmware builds
setnewcam() {
    export CAMLIBS=NewCam
    # Pick DSP change
    sed -i 's/CONFIG_XIAOMI_NEW_CAMERA_BLOBS=n/CONFIG_XIAOMI_NEW_CAMERA_BLOBS=y/g' arch/arm64/configs/${DEFCONFIG}
    echo -e "Newcam ready"
}

# Ship China firmware builds
clearout() {
    # Pick DSP change
    rm -rf out
    mkdir -p out
}

# Setver 2 for newcam
setver2() {
    KERNELNAME="${KERNEL}-${VERSION}-${KERNELRELEASE}-nightly-${BUILD_DATE}-NewCam-"
    sed -i "50s/.*/CONFIG_LOCALVERSION=\"-${KERNELNAME}\"/g" arch/arm64/configs/${DEFCONFIG}
    export KERNELTYPE KERNELNAME
    export TEMPZIPNAME="${KERNELNAME}-unsigned.zip"
    export ZIPNAME="${KERNELNAME}.zip"
}

## Start the kernel buildflow ##
setversioning
tg_groupcast "compile started at $(date +%Y%m%d-%H%M)"
tg_channelcast "Device: ${DEVICE}" \
               "Kernel: <code>${KERNEL}, ${KERNELRELEASE}</code>" \
               "Linux Version: <code>$(make kernelversion)</code>" \
               "Branch: <code>${PARSE_BRANCH}</code>" \
               "Latest commit: <code>${COMMIT_POINT}</code>" \
               "Started at: <b>${BUILD_DATE}</b>"
START=$(date +"%s")
cloneak3
makekernel || exit 1
shipkernel
setver2
setnewcam
cloneak3
makekernel || exit 1
shipkernel
END=$(date +"%s")
DIFF=$(( END - START ))
tg_channelcast "Build for ${DEVICE} with ${COMPILER_STRING} <b>succeed</b> took $((DIFF / 60)) minute(s) and $((DIFF % 60)) second(s)!"
tg_groupcast "Build for ${DEVICE} with ${COMPILER_STRING} <b>succeed</b> took $((DIFF / 60)) minute(s) and $((DIFF % 60)) second(s)! @unknown_name123"
