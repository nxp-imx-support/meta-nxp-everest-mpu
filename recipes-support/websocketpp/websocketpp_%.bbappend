HOMEPAGE = "https://github.com/jcelerier/websocketpp"
LIC_FILES_CHKSUM = "file://${S}/COPYING;md5=caca8c57fc82d4528bfd694b3de9b7cf"

SRC_URI = "git://github.com/jcelerier/websocketpp.git;protocol=https;branch=ossia/2024-12-18 \
          "

SRCREV = "3b86173af2b936df997f1a32609ea09336447eb1"

SKIP_RECIPE[websocketpp] = ""