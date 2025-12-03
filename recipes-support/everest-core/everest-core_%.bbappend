FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
NXP_FILES := "${THISDIR}/files"

SRC_URI:append = " \
    git://git@bitbucket.sw.nxp.com/micrse/nxp-everest-core.git;name=sigboardnxp;branch=${SRC_BRANCH}/sigbrd2;protocol=ssh;subdir=git/modules/SigboardNXP;subpath=modules/SigboardNXP \
    file://configs/ \
    file://libnfc-configs/ \
    file://everest-core/0001-Integrated-config-file-for-basic-charging-and-ocpp.patch \
    file://everest-core/0002-Change-RFID-token-Provider-to-PN7160TokenProvider.patch \
    file://everest-core/0003-Add-ocpp-config-file-for-imx93-with-nfc.patch \
    file://everest-core/0004-Add-SigBoard-specific-only-config-files.patch \
    file://everest-core/0005-Enable-ocpp-with-only-ONE-connector.patch \
    file://everest-core/0006-Disable-Meter-by-default.patch \
    file://everest-core/0007-update-config-files-for-basic-charging-with.patch \
    file://everest-core/0008-Avoid-power-budget-expiry.patch \
    file://everest-core/0009-Add-config-file-for-ISO2-with-ocpp201.patch \
    file://everest-core/0010-add-password-for-ISO2-with-OCPP201.patch \
    file://everest-core/0011-IIOTSOL1-956-tls-Enable-OpenSSL-default-and-se05x-pr.patch \
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
    cp -r ${NXP_FILES}/libnfc-configs/* ${S}/modules/PN7160TokenProvider/libnfc-nci_config
    cp -r ${NXP_FILES}/configs/* ${S}/config
    cp -r ${NXP_FILES}/scripts/* ${S}/scripts
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
