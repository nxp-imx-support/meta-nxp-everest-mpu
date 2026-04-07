FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
NXP_FILES := "${THISDIR}/files"

SRC_BRANCH = "develop/everest-mpu-2.0"

SRC_URI:append = " \
    git://git@bitbucket.sw.nxp.com/micrse/nxp-everest-core.git;name=sigboardnxp;branch=${SRC_BRANCH}/sigbrd2;protocol=ssh;destsuffix=git/modules/SigboardNXP;subpath=modules/SigboardNXP \
    file://configs/ \
    file://libnfc-configs/ \
    file://everest-core/0002-Change-RFID-token-Provider-to-PN7160TokenProvider.patch \
    file://everest-core/0012-IIOTSOL1-1210-Add-CSMS-connection-status-monitoring-.patch \
    file://everest-core/0013-IIOTSOL1-1249-Block-RFID-authorization-when-EV-not-c.patch \
    file://scripts/ \
"

SRCREV_FORMAT = "everest"
SRCREV_sigboardnxp = "${AUTOREV}"

addtask do_prepare_nxp_additions after do_patch before do_configure

EXTRA_OECMAKE:append = " \
    -DISO15118_2_GENERATE_AND_INSTALL_CERTIFICATES=OFF \
"

do_prepare_nxp_additions() {
    mkdir -p ${S}/scripts
    cp -r ${FILE_DIRNAME}/everest-core/everest.service ${WORKDIR}
    cp -r ${NXP_FILES}/libnfc-configs/* ${S}/modules/HardwareDrivers/NfcReaders/PN7160TokenProvider/libnfc-nci_config
    cp -r ${NXP_FILES}/configs/* ${S}/config
    cp -r ${NXP_FILES}/scripts/* ${S}/scripts
    cp -r ${UNPACKDIR}/git/modules/SigboardNXP ${S}/modules
    sed -i "1s/^/ev_add_module(SigboardNXP)\n/" ${S}/modules/CMakeLists.txt
}

do_install:append() {
    install -d "${D}${sysconfdir}/everest/scripts"

    for f in ${NXP_FILES}/scripts/*; do
        install -m 0755 $f "${D}${sysconfdir}/everest/scripts"
    done
}

# Include scripts in the rootfilesystem
FILES:${PN} += "${sysconfdir}/everest"
