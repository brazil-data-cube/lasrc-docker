#!/bin/bash
#
# This file is part of LaSRC Docker.
# Copyright (C) 2021 INPE.
#
# LaSRC Docker is free software; you can redistribute it and/or modify it
# under the terms of the MIT License; see LICENSE file for more details.
#

set -eou pipefail

#
# General functions
#
usage() {
    echo "Usage: $0 [-n] [-b ubuntu:18.04]" 1>&2;

    exit 1;
}

#
# General variables
#
BASE_IMAGE="ubuntu:ubuntu@sha256:122f506735a26c0a1aff2363335412cfc4f84de38326356d31ee00c2cbe52171" # ubuntu:18.04
BUILD_MODE=""

#
# Get build options
#
while getopts "b:nh" o; do
    case "${o}" in
        b)
            BASE_IMAGE=${OPTARG}
            ;;
        n)
            BUILD_MODE="--no-cache"
            ;;
        h)
            usage
            ;;
        *)
            usage
            ;;
    esac
done

#
# Build a Linux Ubuntu image with all the dependencies already installed
#
echo "Building LaSRC Image"

docker build ${BUILD_MODE} \
       -t "lasrc" \
       --build-arg BASE_IMAGE=${BASE_IMAGE} \
       --file ./Dockerfile .