SUMMARY = "EVerest development PKI (ISO 15118-2 & ISO 15118-20)"
DESCRIPTION = "Generates and installs the unified EVerest dev PKI under /etc/everest, supporting ISO 15118-2 and ISO 15118-20 with optional SE050 key generation."
LICENSE = "CLOSED"
LIC_FILES_CHKSUM = ""
AUTHOR = "Marouene Boubakri <marouene.boubakri@nxp.com>"


SRC_BRANCH ?= "develop/everest-mpu-2.0"
SRC_URI = "git://git@bitbucket.sw.nxp.com/micrse/everest-dev-keys.git;branch=${SRC_BRANCH};protocol=ssh"

SRCREV = "${AUTOREV}"

S = "${WORKDIR}/git"

inherit allarch

DEPENDS += "openssl-native"

do_compile[noexec] = "1"

do_configure() {
    cd ${S}

    bbnote "Checking for existing dev PKI (ISO15118-2 and ISO15118-20)..."

    NEED_GEN_ISO2=0
    NEED_GEN_ISO20=0

    #
    # Check ISO15118-2 PKI
    #
    if [ ! -f "certs/iso2/ca/v2g/V2G_ROOT_CA.pem" ]; then
        bbnote "ISO15118-2 PKI missing -> will generate."
        NEED_GEN_ISO2=1
    fi

    #
    # Check ISO15118-20 PKI
    #
    if [ ! -f "certs/iso20/ca/v2g/V2G_ROOT_CA.pem" ]; then
        bbnote "ISO15118-20 PKI missing -> will generate."
        NEED_GEN_ISO20=1
    fi


    #
    # Generate PKI only if missing
    #
    if [ $NEED_GEN_ISO2 -eq 1 ] || [ $NEED_GEN_ISO20 -eq 1 ]; then
        bbnote "Generating missing PKI trees..."

        if [ $NEED_GEN_ISO2 -eq 1 ]; then
            ./gen_pki.sh --regen --iso-2
        fi

        if [ $NEED_GEN_ISO20 -eq 1 ]; then
            ./gen_pki.sh --regen --iso-20 --suite 2
        fi
    else
        bbnote "PKI already present for both ISO versions. Skipping generation."
    fi


    #
    # Validate both ISO versions separately
    #
    if [ -d "certs/iso2" ]; then
        bbnote "Validating ISO15118-2 PKI..."
        ./chk_pki.sh --iso-2
    fi

    if [ -d "certs/iso20" ]; then
        bbnote "Validating ISO15118-20 PKI..."
        ./chk_pki.sh --iso-20 --suite 2
    fi
}

do_install() {
    install -d ${D}${sysconfdir}/everest

    #
    # Install generated PKI output
    #
    if [ -d "${S}/certs" ]; then
        cp -r "${S}/certs" "${D}${sysconfdir}/everest/"
    fi

    if [ -d "${S}/csrs" ]; then
        cp -r "${S}/csrs" "${D}${sysconfdir}/everest/"
    fi

    #
    # Install OpenSSL configurations (repo contents)
    #
    if [ -d "${S}/openssl" ]; then
        cp -r "${S}/openssl" "${D}${sysconfdir}/everest/"
    fi

    #
    # Install scripts
    #
    install -m 0755 "${S}/chk_pki.sh" "${D}${sysconfdir}/everest/"
    install -m 0755 "${S}/gen_pki.sh" "${D}${sysconfdir}/everest/"

    #
    # Set permissions
    #
    find "${D}${sysconfdir}/everest" -type f -exec chmod 0644 {} +
    find "${D}${sysconfdir}/everest" -type f -name "*.key" -exec chmod 0600 {} +
    find "${D}${sysconfdir}/everest" -type f -name "*.sh"  -exec chmod 0755 {} +
}

FILES:${PN} += "${sysconfdir}/everest"
