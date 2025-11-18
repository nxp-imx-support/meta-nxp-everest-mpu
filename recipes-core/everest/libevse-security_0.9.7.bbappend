FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " \
    file://0001-IIOTSOL1-956-Rework-OpenSSL-provider-loading-to-prio.patch \
"

DEPENDS:append = "\
    openssl-provider-se050 \
"

EXTRA_OECMAKE:append  = "\
    -DUSING_CUSTOM_PROVIDER=ON \
"
