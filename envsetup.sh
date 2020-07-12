#!/usr/bin/env bash
#
# Copyright (C) 2019 nysascape
#
# Licensed under the Raphielscape Public License, Version 1.d (the "License");
# you may not use this file except in compliance with the License.
#
# Probably the 3rd bad apple coming
# Enviroment variables

# Export KERNELDIR as en environment-wide thingy
# We start in scripts, so like, don't clone things there
KERNELDIR="$(pwd)"
SCRIPTS=${KERNELDIR}/kernelscripts
OUTDIR=${KERNELDIR}/out

git clone https://github.com/najahiiii/aarch64-linux-gnu.git -b linaro8-20190402 --depth=1 "${KERNELDIR}/gcc"
git clone https://github.com/innfinite4evr/android-prebuilts-gcc-linux-x86-arm-arm-eabi-7.2.git -b master --depth=1 "${KERNELDIR}/gcc32"

export KERNELDIR SCRIPTS OUTDIR

git clone https://github.com/fabianonline/telegram.sh/ telegram

# Export Telegram.sh
TELEGRAM=${KERNELDIR}/telegram/telegram

export TELEGRAM JOBS
