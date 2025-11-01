#!/bin/sh
#
# NXP Build Enviroment Setup Script
#
# Copyright (C) 2015-2016 Freescale Semiconductor
# Copyright 2024-2025 NXP
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

echo -e "\n----------------\n"
imx-easyevse_exit_message()
{
   echo "i.MX EVerest EVSE setup complete"
}

imx-easyevse_usage()
{
    echo -e "\nDescription: setup-imx-easyevse.sh will setup the bblayers and local.conf for an i.MX EasyEVSE MPU build."
    echo -e "\nUsage: source setup-imx-everest.sh
    Optional parameters: [-b build-dir] [-h]"
    echo "
    * [-b build-dir]: Build directory, if unspecified, script uses 'build-imx-easyevse' as the output directory
    * [-h]: help
"
}

echo Reading command line parameters
# Read command line parameters
while getopts "k:t:b:e:gh" nxp_setup_flag
do
    case $nxp_setup_flag in
        b) BUILD_DIR="$OPTARG";
           echo -e "\n Build directory is $BUILD_DIR" ;
           ;;
        h) nxp_setup_help='true';
           ;;
        ?) nxp_setup_error='true';
           ;;
    esac
done

RELEASEPROGNAME="./imx-setup-release.sh"

# Supported yocto version
YOCTOVERSION="styhead walnascar"

# NXP EVerest / EVSE layer list
LAYER_LIST=" \
	meta-nxp-everest-mpu \
	meta-nxp-evse-common-mpu \
	meta-everest \
"

EXTRA_LAYER_LIST=" \
    meta-nxp-evse-common-mpu-dev \
    meta-nxp-everest-mpu-dev \
"

# Get command line options
OLD_OPTIND=$OPTIND

if [ -z "$BUILD_DIR" ]; then
    BUILD_DIR=build-imx-easyevse
fi

if [ -n "$BASH_SOURCE" ]; then
	ROOTDIR="`readlink -f $BASH_SOURCE | xargs dirname`"
elif [ -n "$ZSH_NAME" ]; then
	ROOTDIR="`readlink -f $0 | xargs dirname`"
else
	ROOTDIR="`readlink -f $PWD | xargs dirname`"
fi
SOURCEDIR="$ROOTDIR/../.."

echo source $RELEASEPROGNAME -b $BUILD_DIR
source $RELEASEPROGNAME -b $BUILD_DIR


# Add our EVSE layers
# Some layers need to be forced to be compatible with styhead
for layer in $(eval echo $LAYER_LIST); do
    append_layer=""
    if [ -e "${SOURCEDIR}/${layer}" ]; then
        append_layer="${SOURCEDIR}/${layer}"
    fi
    if [ -n "${append_layer}" ]; then
        echo "BBLAYERS += \"\${BSPDIR}/sources/$layer\"" >> $BUILD_DIR/conf/bblayers.conf

        # check if layer is compatible with supported yocto version.
        # if not, make it so.
        conffile_path="${append_layer}/conf/layer.conf"
        yocto_compatible=`grep "LAYERSERIES_COMPAT" "${conffile_path}" | grep "${YOCTOVERSION}" || true`
        if [ -z "${yocto_compatible}" ]; then
		    sed -E "/LAYERSERIES_COMPAT/s/(\".*)\"/\1 $YOCTOVERSION\"/g" -i "${conffile_path}"
		    echo Layer ${layer} updated for ${YOCTOVERSION}.
		fi
    fi
done

for layer in $(eval echo ${EXTRA_LAYER_LIST}); do
	if [ -e "${SOURCEDIR}/${layer}" ]; then
		echo "BBLAYERS += \"\${BSPDIR}/sources/$layer\"" >> $BUILD_DIR/conf/bblayers.conf
	fi
done

# EdgeLock2Go support
echo "EDGELOCK2GO_HOSTNAME = \"w4dx9d3ansxis0hw.device-link.edgelock2go.com\"" >> $BUILD_DIR/conf/local.conf
echo "EDGELOCK2GO_PORT = \"443\"" >> $BUILD_DIR/conf/local.conf

echo

imx-easyevse_exit_message

echo "Cleaning up variables"
unset BUILD_DIR
unset nxp_setup_help nxp_setup_error nxp_setup_flag
