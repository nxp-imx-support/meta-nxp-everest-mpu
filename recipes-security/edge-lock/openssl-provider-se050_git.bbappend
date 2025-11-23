FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " \
    file://0001-CMakeLists.txt-Disable-SE05X-RNG-usage-due-to-known-.patch \
"

# Ensure symlink for OpenSSL provider resolution
do_install:append() {
    install -d ${D}${libdir}/ossl-modules

    # Provider name expected by EVerest: nxp_prov
    ln -sf ${libdir}/libsssProvider.so \
        ${D}${libdir}/ossl-modules/nxp_prov.so
}

FILES:${PN} += "${libdir}/ossl-modules/*"

# The provider .so is a runtime plugin, not a devel symlink
INSANE_SKIP:${PN} += "dev-so"
