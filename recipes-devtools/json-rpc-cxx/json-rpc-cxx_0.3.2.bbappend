# Ensure Yocto searches our layer for files/
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# Override SRC_URI to add unpack=1 to the cmake config file
SRC_URI:remove = "file://json-rpc-cxxConfig.cmake"
SRC_URI:append = " file://json-rpc-cxxConfig.cmake;unpack=1"
