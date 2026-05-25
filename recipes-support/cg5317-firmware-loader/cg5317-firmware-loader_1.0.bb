SUMMARY = "systemd integration for the Lumissil CG5317 firmware loader"
DESCRIPTION = "Provides a systemd oneshot service that loads the CG5317 \
PLC firmware via host_loading_service at boot, ordered before \
everest.service so EVerest's SLAC module finds the PLC interface ready."
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"
AUTHOR = "Marouene Boubakri <marouene.boubakri@nxp.com>"

SRC_URI = " \
    file://cg5317-firmware-load.service \
    file://10-cg5317.conf \
    file://cg5317_0.cfg \
"

inherit systemd allarch

SYSTEMD_SERVICE:${PN} = "cg5317-firmware-load.service"
SYSTEMD_AUTO_ENABLE:${PN} = "enable"

do_install() {
    # systemd unit
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${UNPACKDIR}/cg5317-firmware-load.service \
        ${D}${systemd_system_unitdir}/cg5317-firmware-load.service

    # everest.service drop-in adding the After=/Requires= dependency
    install -d ${D}${systemd_system_unitdir}/everest.service.d
    install -m 0644 ${UNPACKDIR}/10-cg5317.conf \
        ${D}${systemd_system_unitdir}/everest.service.d/10-cg5317.conf

    # Operator-editable EnvironmentFile with loader parameters.
    # Marked as CONFFILE so package upgrades preserve local changes.
    install -d ${D}${sysconfdir}/lumissil
    install -m 0644 ${UNPACKDIR}/cg5317_0.cfg \
        ${D}${sysconfdir}/lumissil/cg5317_0.cfg
}

FILES:${PN} += " \
    ${systemd_system_unitdir}/cg5317-firmware-load.service \
    ${systemd_system_unitdir}/everest.service.d/10-cg5317.conf \
    ${sysconfdir}/lumissil/cg5317_0.cfg \
"

CONFFILES:${PN} += "${sysconfdir}/lumissil/cg5317_0.cfg"

# The systemd unit calls host_loading_service from the Lumissil SDK
# and orders before everest-core's everest.service.
RDEPENDS:${PN} += "lumissil-hpgp-sdk everest-core"
