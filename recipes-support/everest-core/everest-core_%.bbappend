FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
NXP_FILES := "${THISDIR}/files"

SRC_URI:append = " \
    git://git@bitbucket.sw.nxp.com/micrse/nxp-everest-core.git;name=sigboardnxp;branch=implement-everest-sigbrd2-driver;protocol=ssh;subdir=git/modules/SigboardNXP;subpath=modules/SigboardNXP \
    file://configs/ \
    file://libnfc-configs/ \
"

SRCREV_FORMAT = "everest"
SRCREV_sigboardnxp = "${AUTOREV}"

addtask do_prepare_nxp_additions after do_patch before do_configure

do_prepare_nxp_additions() {
    cp -r ${FILE_DIRNAME}/everest-core/everest.service ${WORKDIR}
    cp -r ${NXP_FILES}/libnfc-configs/* ${S}/modules/PN7160TokenProvider/libnfc-nci_config
    cp -r ${NXP_FILES}/configs/* ${S}/config
    sed -i "1s/^/ev_add_module(SigboardNXP)\n/" ${S}/modules/CMakeLists.txt
}
