..
    This file is part of Brazil Data Cube LaSRC Docker.
    Copyright (C) 2022 INPE.

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program. If not, see <https://www.gnu.org/licenses/gpl-3.0.html>.


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
    -v /path/to/lasrc-auxiliaries/L8:/mnt/atmcor-aux/lasrc/L8:ro \
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
