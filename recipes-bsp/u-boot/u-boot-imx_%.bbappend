FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " \
    ${@bb.utils.contains('DISTRO_FEATURES', 'LVDS_DISPLAY_SUPPORT', 'file://0001-EVerest-Select-by-default-the-device-tree-for-the-L.patch', '', d)} \
"
