SRC_URI = "https://github.com/EVerest/everest-admin-panel/releases/download/v0.2.0/everest-admin-panel.tar.gz;subdir=${WORKDIR}/${BP} \
           npmsw://${THISDIR}/${BPN}/npm-shrinkwrap.json \
          "

UNPACKDIR = "${WORKDIR}/${BP}"

do_install() {
    install -d ${D}/usr/share/everest/www
    cp -a --no-preserve=ownership ${WORKDIR}/${BP}/* ${D}/usr/share/everest/www/
}
