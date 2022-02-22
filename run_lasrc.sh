#!/bin/bash
#
# This file is part of LaSRC Docker.
# Copyright (C) 2021-2022 INPE.
#
# LaSRC Docker is free software; you can redistribute it and/or modify it
# under the terms of the MIT License; see LICENSE file for more details.
#

set -e
shopt -s nullglob

if [ $1 == "--help" ]; then
    echo "Usage: \
    docker run --rm \
    -v /path/to/input/:/mnt/input-dir:ro \
    -v /path/to/output:/mnt/output-dir:rw \
    -v /path/to/lasrc_auxiliaries/L8:/mnt/atmcor_aux/L8:ro \
    -t brazildatacube/lasrc:2.0.1 <LANDSAT-8 FOLDER OR SENTINEL-2.SAFE>"
    exit 0
fi

# Set default directories to the INDIR
# You can customize it using INDIR=/my/custom run_lasrc.sh
if [ -z "${INDIR}" ]; then
    INDIR=/mnt/input-dir
fi

if [ -z "${WORKDIR}" ]; then
    WORKDIR=/mnt/work-dir/
fi
mkdir -p ${WORKDIR}

if [ -z "${OUTDIR}" ]; then
    OUTDIR=/mnt/output-dir
fi

INPUT_PRODUCT=$1

# Ensure that workdir/sceneid is clean
if [ -d "${WORKDIR}/${INPUT_PRODUCT}" ]; then
    rm -r ${WORKDIR}/${INPUT_PRODUCT}
fi

# Landsat
if [[ $1 == "LC08"* ]]; then
    SCENE_ID=$INPUT_PRODUCT
    OUTDIR=${OUTDIR}/${SCENE_ID}
    WORKDIR=$WORKDIR/$SCENE_ID

    cp -r ${INDIR}/$SCENE_ID ${WORKDIR}

    MTD_FILES=$(find ${WORKDIR} -name "${SCENE_ID}_MTL.txt" -o -name "${SCENE_ID}_ANG.txt")
    TIF_PATTERNS="${SCENE_ID}_*.tif -iname ${SCENE_ID}_*.TIF"

    # Only make files with the correct scene ID visible
    for f in $(find ${WORKDIR} -iname "${SCENE_ID}*.tif"); do
        echo $f
        if gdalinfo $f | grep -q 'Block=.*x1\s'; then
            continue
        else
            # convert tiled tifs to striped layout
            gdal_translate -co TILED=NO $f $WORKDIR/$(basename $f).tmp
            mv $WORKDIR/$(basename $f).tmp $WORKDIR/$(basename $f)
        fi
    done

    cd $WORKDIR

    # Run ESPA stack
    convert_lpgs_to_espa --mtl=${SCENE_ID}_MTL.txt

    do_lasrc_landsat.py --xml ${SCENE_ID}.xml # --write_toa
    OUT_PATTERNS="$WORKDIR/${SCENE_ID}_sr_*.tif $WORKDIR/${SCENE_ID}_radsat_qa.tif $WORKDIR/${SCENE_ID}_sensor*.tif $WORKDIR/${SCENE_ID}_solar*.tif"
    # TODO Option to export toa and bt
    # $WORKDIR/${SCENE_ID}_toa_*.tif $WORKDIR/${SCENE_ID}_bt_*.tif

    convert_espa_to_gtif --xml=${SCENE_ID}.xml --gtif=$SCENE_ID --del_src_files
    # Copy outputs from workdir
    mkdir -p $OUTDIR
    for f in $OUT_PATTERNS; do
        gdal_translate -co "COMPRESS=DEFLATE" $f $OUTDIR/$(basename $f)
    done
    for f in $MTD_FILES; do
        cp $WORKDIR/$(basename $f) $OUTDIR/$(basename $f)
    done
    rm -rf $WORKDIR
# SENTINEL-2
elif [[ $1 == "S2"* ]]; then
    SAFENAME_L1C=$INPUT_PRODUCT
    SCENE_ID=${SAFENAME_L1C%.SAFE*}

    cp -r ${INDIR}/${SAFENAME_L1C} ${WORKDIR}
    OUTDIR=${OUTDIR}/${SCENE_ID}

    JP2_PATTERNS=$(find ${WORKDIR}/${SAFENAME_L1C} -name "${SCENE_ID}_*.jp2" -o -name "${SCENE_ID}_*.JP2")

    cd ${WORKDIR}/${SAFENAME_L1C}/GRANULE
    for entry in `ls ${WORKDIR}/${SAFENAME_L1C}/GRANULE`; do
        GRANULE_SCENE=${WORKDIR}/${SAFENAME_L1C}/GRANULE/${entry}
    done
    IMG_DATA=${GRANULE_SCENE}/IMG_DATA
    cd ${IMG_DATA}
    # Copy XMLs
    cp ${WORKDIR}/${SAFENAME_L1C}/MTD_MSIL1C.xml ${IMG_DATA}
    cp ${GRANULE_SCENE}/MTD_TL.xml ${IMG_DATA}
    # Run ESPA stack
    convert_sentinel_to_espa
    for entry in `ls ${IMG_DATA}/S2*.xml`; do
        SCENE_ID_XML=${entry}
    done
    do_lasrc_sentinel.py --xml=${SCENE_ID_XML}
    convert_espa_to_gtif --xml=${SCENE_ID_XML} --gtif=${SCENE_ID} --del_src_files
    # Copy outputs from workdir
    mkdir -p $OUTDIR
    OUT_PATTERNS="${IMG_DATA}/${SCENE_ID}_sr_*.tif"
    for f in $OUT_PATTERNS; do
        gdal_translate -co "COMPRESS=DEFLATE" $f $OUTDIR/$(basename $f)
    done
    # Copy XMLs
    cp ${WORKDIR}/${SAFENAME_L1C}/MTD_MSIL1C.xml $OUTDIR
    cp ${GRANULE_SCENE}/MTD_TL.xml $OUTDIR
    rm -rf ${WORKDIR}/$SAFENAME_L1C
fi

exit 0
