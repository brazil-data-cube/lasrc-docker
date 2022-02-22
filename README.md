# LaSRC 2.0.1

Landsat-8 and Sentinel-2 atmospheric correction through LaSRC 2.0.1.

## Dependencies

- Docker

## LaSRC Auxiliary Data

Download the [https://edclpdsftp.cr.usgs.gov/downloads/auxiliaries/lasrc_auxiliary/L8/](https://edclpdsftp.cr.usgs.gov/downloads/auxiliaries/lasrc_auxiliary/L8/) into *L8*. The LADS folder can contain only data from dates that are going to be processed.

Or, you can also download MODIS CMG and CMA to generate the LADS files by running the following command from within the container:
    ```bash
    $ python /opt/espa-surface-reflectance/lasrc/landsat_aux/scripts/updatelads.py --today
    ```

## Installation

1. Run

   ```bash
   $ docker build -t brazildatacube/lasrc:2.0.1 .
   ```

   from the root of this repository.

## Usage

To process a Landsat-8 scene (e.g. `LC08_L1TP_220069_20190112_20190131_01_T1`) run

```bash
$ docker run --rm \
    -v /path/to/input/:/mnt/input-dir:rw \
    -v /path/to/output:/mnt/output-dir:rw \
    -v /path/to/lasrc_auxiliaries/L8:/mnt/atmcor_aux/lasrc/L8:ro \
    -t brazildatacube/lasrc:2.0.1 LC08_L1TP_220069_20190112_20190131_01_T1
```

To process a Sentinel-2 scene (e.g. `S2A_MSIL1C_20190105T132231_N0207_R038_T23LLF_20190105T145859.SAFE`) run

```bash
$ docker run --rm \
    -v /path/to/input/:/mnt/input-dir:rw \
    -v /path/to/output:/mnt/output-dir:rw \
    -v /path/to/lasrc_auxiliaries/L8:/mnt/atmcor_aux/lasrc/L8:ro \
    -t brazildatacube/lasrc:2.0.1 S2A_MSIL1C_20190105T132231_N0207_R038_T23LLF_20190105T145859.SAFE
```

Results are written on mounted `/mnt/output-dir/SCENEID`.

## Acknowledgements

Copyright for portions of LaSRC 1.4 docker code are held by [DHI GRAS A/S](https://github.com/DHI-GRAS), 2018 as part of project [lasrclicious](https://github.com/DHI-GRAS/lasrclicious).
