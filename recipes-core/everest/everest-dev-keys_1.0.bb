SUMMARY = "EVerest development PKI (certs, keys, openssl configs, scripts)"
DESCRIPTION = "Installs EVerest dev PKI material under /etc/everest from a Git repo."
LICENSE = "CLOSED"
LIC_FILES_CHKSUM = ""
AUTHOR = "Marouene Boubakri <marouene.boubakri@nxp.com>"

DEV_KEYS_TAG ?= "everest-mpu-${PV}"
DEV_KEYS_BRANCH ?= "master"
SRC_URI = "git://git@bitbucket.sw.nxp.com/micrse/everest-dev-keys.git;branch=${DEV_KEYS_BRANCH};tag=${DEV_KEYS_TAG};protocol=ssh"

SRCREV = "62f57cb186bb9e8fbe09b0d667d656ff727e744a"

S = "${WORKDIR}/git"

inherit allarch

DEPENDS += "openssl-native"

do_compile[noexec] = "1"

do_configure() {
    cd ${S}

    if [ ! -f "certs/ca/v2g/V2G_ROOT_CA.der" ] || \
       [ ! -f "certs/ca/v2g/V2G_ROOT_CA.pem" ]; then
        bbnote "V2G ROOT CA not found, generating dev PKI..."

        ./gen_pki.sh -r

        ./chk_pki.sh
    else
        bbnote "PKI already present in repo, skipping generation."
    fi
}

do_install() {
    install -d ${D}${sysconfdir}/everest

    if [ -d "${S}/certs" ]; then
        cp -r "${S}/certs" "${D}${sysconfdir}/everest/"
    fi

    if [ -d "${S}/csrs" ]; then
        cp -r "${S}/csrs" "${D}${sysconfdir}/everest/"
    fi

    if [ -d "${S}/openssl" ]; then
        cp -r "${S}/openssl" "${D}${sysconfdir}/everest/"
    fi

    if [ -f "${S}/chk_pki.sh" ]; then
        install -m 0755 "${S}/chk_pki.sh" "${D}${sysconfdir}/everest/"
    fi
    if [ -f "${S}/gen_pki.sh" ]; then
        install -m 0755 "${S}/gen_pki.sh" "${D}${sysconfdir}/everest/"
    fi

    find "${D}${sysconfdir}/everest" -type f -exec chmod 0644 {} +
    find "${D}${sysconfdir}/everest" -type f -name "*.key" -exec chmod 0600 {} +
    find "${D}${sysconfdir}/everest" -type f -name "*.sh"  -exec chmod 0755 {} +
}

FILES:${PN} += "${sysconfdir}/everest"
