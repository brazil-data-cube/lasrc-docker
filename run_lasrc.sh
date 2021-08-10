#!/bin/bash
set -e
shopt -s nullglob
if [ $1 == "--help" ]; then
    echo "Usage: \
    docker run --rm \
    -v /path/to/input/:/mnt/input-dir:ro \
    -v /path/to/output:/mnt/output-dir:rw \
    -v /path/to/lasrc_auxiliaries/L8:/mnt/atmcor_aux/L8:ro \
    -t lasrc <LANDSAT-8 FOLDER OR SENTINEL-2.SAFE>"
    exit 0
fi
# Set default directories to the INDIR and OUTDIR
# You can customize it using INDIR=/my/custom OUTDIR=/my/out run_lasrc.sh
if [ -z "${INDIR}" ]; then
    INDIR=/mnt/input-dir
fi

##Landsat
if [[ $1 == "LC08"* ]]; then
    SCENE_ID=$1
    WORKDIR=/work/${SCENE_ID}

    if [ -z "${OUTDIR}" ]; then
        OUTDIR=/mnt/output-dir/${SCENE_ID}
    fi

    MTD_FILES=$(find ${INDIR} -name "${SCENE_ID}_MTL.txt" -o -name "${SCENE_ID}_ANG.txt")
    TIF_PATTERNS="${SCENE_ID}_*.tif -iname ${SCENE_ID}_*.TIF"
    # ensure that workdir/sceneid is clean
    rm -rf ${WORKDIR}
    mkdir -p $WORKDIR
    cd $WORKDIR
    # only make files with the correct scene ID visible
    for f in $(find ${INDIR} -iname "${SCENE_ID}*.tif"); do
        echo $f
        if gdalinfo $f | grep -q 'Block=.*x1\s'; then
            ln -s $(readlink -f $f) $WORKDIR/$(basename $f)
        else
            # convert tiled tifs to striped layout
            gdal_translate -co TILED=NO $f $WORKDIR/$(basename $f)
        fi
    done
    for f in $MTD_FILES; do
        cp $f $WORKDIR
    done
    # run ESPA stack
    convert_lpgs_to_espa --mtl=${SCENE_ID}_MTL.txt

    do_lasrc_landsat.py --xml ${SCENE_ID}.xml # --write_toa
    OUT_PATTERNS="$WORKDIR/${SCENE_ID}_toa_*.tif $WORKDIR/${SCENE_ID}_sr_*.tif $WORKDIR/${SCENE_ID}_bt_*.tif $WORKDIR/${SCENE_ID}_radsat_qa.tif $WORKDIR/${SCENE_ID}_sensor*.tif $WORKDIR/${SCENE_ID}_solar*.tif"

    convert_espa_to_gtif --xml=${SCENE_ID}.xml --gtif=$SCENE_ID --del_src_files
    ## Copy outputs from workdir
    mkdir -p $OUTDIR
    for f in $OUT_PATTERNS; do
        gdal_translate -co "COMPRESS=DEFLATE" $f $OUTDIR/$(basename $f)
    done
    for f in $MTD_FILES; do
        cp $WORKDIR/$(basename $f) $OUTDIR/$(basename $f)
    done
    rm -rf $WORKDIR
## SENTINEL-2
elif [[ $1 == "S2"* ]]; then
    SAFENAME=$1
    SAFEDIR=${INDIR}/${SAFENAME}
    SCENE_ID=${SAFENAME:0:-5}

    if [ -z "${OUTDIR}" ]; then
        OUTDIR=/mnt/output-dir/${SCENE_ID}
    fi

    WORKDIR=/work/${SAFENAME}
    JP2_PATTERNS=$(find ${INDIR} -name "${SCENE_ID}_*.jp2" -o -name "${SCENE_ID}_*.JP2")
    # ensure that workdir/sceneid is clean
    rm -rf ${WORKDIR}
    mkdir -p ${WORKDIR}
    cp -r ${SAFEDIR}/* ${WORKDIR}/
    cd ${WORKDIR}/GRANULE
    for entry in `ls ${WORKDIR}/GRANULE`; do
        GRANULE_SCENE=${WORKDIR}/GRANULE/${entry}
    done
    IMG_DATA=${GRANULE_SCENE}/IMG_DATA
    cd ${IMG_DATA}
    #Copy XMLs
    cp $WORKDIR/MTD_MSIL1C.xml $IMG_DATA
    cp $GRANULE_SCENE/MTD_TL.xml $IMG_DATA
    # run ESPA stack
    convert_sentinel_to_espa
    for entry in `ls ${IMG_DATA}/S2*.xml`; do
        SCENE_ID_XML=${entry}
    done
    do_lasrc_sentinel.py --xml=${SCENE_ID_XML}
    convert_espa_to_gtif --xml=${SCENE_ID_XML} --gtif=${SCENE_ID} --del_src_files
    ## Copy outputs from workdir
    mkdir -p $OUTDIR
    OUT_PATTERNS="${IMG_DATA}/${SCENE_ID}_sr_*.tif"
    for f in $OUT_PATTERNS; do
        gdal_translate -co "COMPRESS=DEFLATE" $f $OUTDIR/$(basename $f)
    done
    #Copy XMLs
    cp $WORKDIR/MTD_MSIL1C.xml $OUTDIR
    cp $GRANULE_SCENE/MTD_TL.xml $OUTDIR
    rm -rf $WORKDIR
fi
exit 0
