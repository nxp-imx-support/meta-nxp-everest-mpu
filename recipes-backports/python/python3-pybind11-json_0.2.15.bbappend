FILESEXTRAPATHS:prepend := "${THISDIR}/python3-pybind11-json:"

SRC_URI:append = " \
    file://0001-Removed-PYTHON_INCLUDE_DIRS-from-CMakeLists.patch \
"