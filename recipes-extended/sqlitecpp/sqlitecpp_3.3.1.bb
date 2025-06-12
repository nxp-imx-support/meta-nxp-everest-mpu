LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE.txt;md5=3d149a8cb6c7dab01d788f477294cebc"

SRC_URI = "git://github.com/SRombauts/SQLiteCpp.git;branch=master;protocol=https"

inherit cmake

# tag 3.3.1
SRCREV = "fe6086c12679d8744c02fa03e83e75feca2413d8"

S = "${WORKDIR}/git"

FILES:${PN}-dev += "${datadir}"

DEPENDS += "sqlite3"

EXTRA_OECMAKE += " \
    -DSQLITECPP_INTERNAL_SQLITE=OFF \
    -DBUILD_SHARED_LIBS=ON \
"
