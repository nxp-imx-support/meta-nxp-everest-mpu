FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:remove = "https://raw.githubusercontent.com/EVerest/everest-core/4c7b9f5f15a8adce2a38113926c09fe8ba486b21/lib/staging/tls/openssl-3.0.8-feat-updates-to-support-status_request_v2.patch;apply=yes;downloadfilename=everest-openssl.patch;name=everest-openssl-patch"
SRC_URI += " \
    file://0001-feat-updates-to-support-status_request_v2.patch \
"
