FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
NXP_FILES := "${THISDIR}/files"

SRC_BRANCH = "release/everest-mpu-2.0"

SRC_URI:append = " \
    git://git@bitbucket.sw.nxp.com/micrse/nxp-everest-core.git;name=sigboardnxp;branch=${SRC_BRANCH}/sigbrd2;protocol=ssh;destsuffix=git/modules/SigboardNXP;subpath=modules/SigboardNXP \
    file://configs/ \
    file://libnfc-configs/ \
    file://everest-core/0001-IIOTSOL1-1521-Add-support-of-NXP-SE050-Secure-Elemen.patch \
    file://everest-core/0002-Change-RFID-token-Provider-to-PN7160TokenProvider.patch \
    file://everest-core/0003-fix-Evse15118D20-Prevent-EVSE-that-supports-multi-ph.patch \
    file://everest-core/0012-IIOTSOL1-1210-Add-CSMS-connection-status-monitoring-.patch \
    file://everest-core/0013-IIOTSOL1-1249-Block-RFID-authorization-when-EV-not-c.patch \
    file://everest-core/0014-IIOTSOL1-1589-IsoMux-enable-TLS-1.3-cipher-suites-fo.patch \
    file://everest-core/0015-IIOTSOL1-1587-IsoMux-select-protocol-by-EV-supplied-.patch \
    file://everest-core/0016-IIOTSOL1-1588-IsoMux-forward-AC-update_-commands-to-.patch \
    file://everest-core/0017-IIOTSOL1-1586-IsoMux-support-multiple-TLS-cert-chain.patch \
    file://everest-core/0018-IIOTSOL1-1607-Enable-ISO-15118-2-PnC-over-IsoMux-loo.patch \
    file://everest-core/everest.service \
    file://everest-core/everest.default \
    file://scripts/ \
"

SRCREV_FORMAT = "everest"
SRCREV_sigboardnxp = "${AUTOREV}"

addtask do_prepare_nxp_additions after do_patch before do_configure

DEPENDS:append = "\
    openssl-provider-se050 \
"

EXTRA_OECMAKE:append = " \
    -DISO15118_2_GENERATE_AND_INSTALL_CERTIFICATES=OFF \
    -DUSING_CUSTOM_PROVIDER=ON \
"

# Default demo config: change DEMO_CONFIG to repoint /etc/everest/config.yaml
# at build time. At runtime the operator can also override via
# /etc/default/everest (EVEREST_CONFIG=...).
DEMO_CONFIG ?= "config-nxp-easyevse-demo-no-ocpp.yaml"

# --- systemd integration --------------------------------------------------
# The upstream everest-core base recipe does not install the unit. The
# bbappend now owns it together with /etc/everest/, so unit + configs + the
# default symlink ship and version as one package.
inherit systemd
SYSTEMD_SERVICE:${PN} = "everest.service"
SYSTEMD_AUTO_ENABLE:${PN} = "enable"
# --------------------------------------------------------------------------


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

    # systemd unit + env file
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${UNPACKDIR}/everest-core/everest.service \
        ${D}${systemd_system_unitdir}/everest.service

    install -d ${D}${sysconfdir}/default
    install -m 0644 ${UNPACKDIR}/everest-core/everest.default \
        ${D}${sysconfdir}/default/everest

    # Make the demo config the default.
    if [ ! -e ${D}${sysconfdir}/everest/${DEMO_CONFIG} ]; then
        bbfatal "Demo config ${DEMO_CONFIG} not found in /etc/everest after install"
    fi
    ln -sf ${DEMO_CONFIG} ${D}${sysconfdir}/everest/config.yaml
}

# Include scripts, unit, env file and the default config symlink in the package
FILES:${PN} += " \
    ${sysconfdir}/everest \
    ${sysconfdir}/default/everest \
    ${systemd_system_unitdir}/everest.service \
"
