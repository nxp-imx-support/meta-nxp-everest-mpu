SUMMARY = "Systemd service for Weston RDP backend"
LICENSE = "CLOSED"
DEPENDS += "openssl-native"
LIC_FILES_CHKSUM = ""

SRC_URI:append = " file://weston-rdp.service"
S = "${UNPACKDIR}"

inherit systemd

SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "weston-rdp.service"
SYSTEMD_AUTO_ENABLE = "enable"

do_install() {
    install -d ${D}${systemd_unitdir}/system
    install -m 0644 ${UNPACKDIR}/weston-rdp.service ${D}${systemd_unitdir}/system/
}

FILES:${PN} += "${systemd_unitdir}/system/weston-rdp.service"
