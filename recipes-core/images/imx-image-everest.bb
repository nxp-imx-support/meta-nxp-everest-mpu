DESCRIPTION = "An i.MX EasyEVSE MPU image full with EVerest functionality installed."

LICENSE = "MIT"

require ../../../meta-imx/meta-imx-sdk/dynamic-layers/qt6-layer/recipes-fsl/images/imx-image-full.bb

# EVerest related packages
IMAGE_INSTALL += " \
        python3-pip \
        python3-terminal \
        python3-ptyprocess \
        python3-ply \
        python3-cffi \
        python3-asyncio-glib \
        python3-cryptography \
        python3-psutil \
        python3-netifaces \
        python3-dateutil \
        python3-iso15118 \
        python3-sqlite3 \
        python3-wheel \
        python3-pytest \
        python3-pytest-asyncio \
        python3-rpds-py \
        python3-referencing \
        python3-attrs \
        python3-jsonschema \
        python3-jsonschema-specifications \
        python3-paho-mqtt \
        python3-websockets \
        python3-pyopenssl \
        python3-pyyaml \
        sqlite3 \
        everest-core \
        everest-admin-panel \
        everest-dev-keys \
        stm32flash \
        libocpp \
        mosquitto \
        fontconfig \
        tzdata \
        screen \
        openssh \
        nano \
        htop \
        lsof \
        minicom \
        util-linux \
        coreutils \
        iproute2 \
        tree \
        perf \
        nodejs \
        systemd-analyze \
        fbida \
        lumissil-hpgp-sdk \
        lms-eth2spi \
        python3-spsdk \
        gui-guider \
        jq \
        freerdp \
        weston-rdp-service \
        "
INSANE_SKIP:everest-framework += "already-stripped"

# Onnxruntime dependency eigen download path is unreliable.
# There are some possible fixes in upstream, need to adjust them for our configuration
# https://github.com/belle2/externals/commit/b756b70798255ab3c28e5c5ad80aa328a021f011
# For now, simply remove it from the image, by removing the entire ML packagegroup
IMAGE_INSTALL:remove = "\
  packagegroup-imx-ml \
"

# Security-related packages
IMAGE_INSTALL += " \
    se05x \
    opensc \
    p11-kit \
    softhsm \
    "

# imx-secure-enclave does not build,
# plug-and-trust-ecc demo conflicts with se050,
# so remove them from packagegroup-imx-security and only keep what we need from it
IMAGE_INSTALL:remove = " \
  packagegroup-imx-security \
"

IMAGE_INSTALL += " \
    e2fsprogs-mke2fs \
    python3-requests \
    keyutils \
    lvm2 \
    util-linux \
    openssl-provider-se050 \
"

# SDK customization
TOOLCHAIN_TARGET_TASK:remove = " \
    coreutils \
"

TOOLCHAIN_TARGET_TASK:append = " \
    wayland \
    wayland-dev \
    libxkbcommon \
    libxkbcommon-dev \
    lvgl-dev \
    lvgl-staticdev \
    lv-drivers-dev \
    lv-drivers-staticdev \
    paho-mqtt-c \
    paho-mqtt-c-dev \
"

ROOTFS_POSTPROCESS_COMMAND:append = " \
    install_demo; \
    prepare_sigb_network_interface; \
    configure_security; \
    hide_weston_panel; \
"

ROOTFS_POSTPROCESS_COMMAND:append = " \
    ${@bb.utils.contains('DISTRO_FEATURES', 'LVDS_DISPLAY_SUPPORT', 'calibrate_lvds;', '', d)} \
"

ROOTFS_POSTPROCESS_COMMAND:append = " \
    ${@bb.utils.contains('PACKAGE_INSTALL', 'weston-rdp-service', 'generate_rdp_tls_key;', '',d)} \
"

install_demo() {
    if ! grep -q "HOME=/home/root/" ${IMAGE_ROOTFS}${sysconfdir}/default/weston
    then
        printf "\nHOME=/home/root/\nQT_QPA_PLATFORM=wayland" >> ${IMAGE_ROOTFS}${sysconfdir}/default/weston
    fi
}

prepare_sigb_network_interface() {
	rm ${IMAGE_ROOTFS}${sysconfdir}/resolv.conf
	ln -sf /etc/resolv-conf.systemd ${IMAGE_ROOTFS}${sysconfdir}/resolv.conf
	touch ${IMAGE_ROOTFS}${sysconfdir}/systemd/network/20-eth0.network
	printf "[Match]\nName=eth0\nKernelCommandLine=!nfsroot\n[Network]\nAddress=169.254.0.10/16" >> ${IMAGE_ROOTFS}${sysconfdir}/systemd/network/20-eth0.network
	touch ${IMAGE_ROOTFS}${sysconfdir}/systemd/network/21-wireless.network
	printf "[Match]\nName=wfd0\n[Network]\nDHCP=ipv4\nLinkLocalAddressing=no\n[DHCP]\nRouteMetric=20" >> ${IMAGE_ROOTFS}${sysconfdir}/systemd/network/21-wireless.network
	touch ${IMAGE_ROOTFS}${sysconfdir}/systemd/network/22-wireless.network
	printf "[Match]\nName=mlan0\n[Network]\nDHCP=ipv4\nLinkLocalAddressing=no\n[DHCP]\nRouteMetric=20" >> ${IMAGE_ROOTFS}${sysconfdir}/systemd/network/22-wireless.network
	touch ${IMAGE_ROOTFS}${sysconfdir}/modprobe.d/wifi.conf
	printf "options moal mod_para=nxp/wifi_mod_para.conf" >> ${IMAGE_ROOTFS}${sysconfdir}/modprobe.d/wifi.conf
	touch ${IMAGE_ROOTFS}${sysconfdir}/modules-load.d/wifi.conf
	printf "moal" >> ${IMAGE_ROOTFS}${sysconfdir}/modules-load.d/wifi.conf
	mkdir ${IMAGE_ROOTFS}${sysconfdir}/wpa_supplicant
	touch ${IMAGE_ROOTFS}${sysconfdir}/wpa_supplicant/wpa_supplicant-wfd0.conf
	printf "ctrl_interface=/var/run/wpa_supplicant\nctrl_interface_group=0\nupdate_config=1\nap_scan=1\n\nnetwork={\n	key_mgmt=WPA-PSK\n	ssid=\"NAME-OF-YOUR-NETWORK\"\n	psk=\"PASSWORD\"\n}\n" >> ${IMAGE_ROOTFS}${sysconfdir}/wpa_supplicant/wpa_supplicant-wfd0.conf
	touch ${IMAGE_ROOTFS}${sysconfdir}/wpa_supplicant/wpa_supplicant-mlan0.conf
	printf "ctrl_interface=/var/run/wpa_supplicant\nctrl_interface_group=0\nupdate_config=1\nap_scan=1\n\nnetwork={\n	key_mgmt=WPA-PSK\n	ssid=\"NAME-OF-YOUR-NETWORK\"\n	psk=\"PASSWORD\"\n}\n" >> ${IMAGE_ROOTFS}${sysconfdir}/wpa_supplicant/wpa_supplicant-mlan0.conf

}

configure_security() {
    # Set port name through EX_SSS_BOOT_SSS_PORT for SE05x
    install -d ${IMAGE_ROOTFS}${sysconfdir}/profile.d

    echo 'export EX_SSS_BOOT_SSS_PORT="/dev/i2c-0:0x48"' > ${IMAGE_ROOTFS}${sysconfdir}/profile.d/se05x.sh

    chmod 755 ${IMAGE_ROOTFS}${sysconfdir}/profile.d/se05x.sh

    PKCS11_MODULES_PATH=${IMAGE_ROOTFS}${datadir}/p11-kit/modules

    mkdir -p ${PKCS11_MODULES_PATH}

    # Only system configuration, ignore user configuration
    echo "user-config: none" >> ${IMAGE_ROOTFS}${sysconfdir}/pkcs11/pkcs11.conf

    # Remove any unneeded preconfigured module
    rm -rf ${PKCS11_MODULES_PATH}/*

    # SE05x
    echo "module: /usr/lib/libsss_pkcs11.so" >> ${PKCS11_MODULES_PATH}/sss_pkcs11.module
    echo "priority: 10" >> ${PKCS11_MODULES_PATH}/sss_pkcs11.module
    echo "critical: yes" >> ${PKCS11_MODULES_PATH}/sss_pkcs11.module

    # TEE
    echo "module: /usr/lib/libckteec.so.0" >> ${PKCS11_MODULES_PATH}/libckteec.module
    echo "priority: 3" >> ${PKCS11_MODULES_PATH}/libckteec.module
    echo "critical: no" >> ${PKCS11_MODULES_PATH}/libckteec.module
    echo "enable-in: stx_evse_*" >> ${PKCS11_MODULES_PATH}/libckteec.module

    # SoftHSMv2
    echo "module: /usr/lib/softhsm/libsofthsm2.so" >> ${PKCS11_MODULES_PATH}/softhsm2.module
    echo "priority: 2" >> ${PKCS11_MODULES_PATH}/softhsm2.module
    echo "critical: no" >> ${PKCS11_MODULES_PATH}/softhsm2.module
    echo "enable-in: stx_evse_*" >> ${PKCS11_MODULES_PATH}/softhsm2.module
}

calibrate_lvds() {
	if [ ! -f "${IMAGE_ROOTFS}${sysconfdir}/udev/rules.d/touchscreen.rules" ]
	then
		touch ${IMAGE_ROOTFS}${sysconfdir}/udev/rules.d/touchscreen.rules
		echo '# Create a symlink to any touchscreen input device' >> ${IMAGE_ROOTFS}${sysconfdir}/udev/rules.d/touchscreen.rules
		echo 'SUBSYSTEM=="input", KERNEL=="event[0-9]*", ATTRS{modalias}=="input:*-e0*,3,*a0,1,*18,*", SYMLINK+="input/touchscreen0"' >> ${IMAGE_ROOTFS}${sysconfdir}/udev/rules.d/touchscreen.rules
		echo 'SUBSYSTEM=="input", KERNEL=="event[0-9]*", ATTRS{modalias}=="ads7846", SYMLINK+="input/touchscreen0"' >> ${IMAGE_ROOTFS}${sysconfdir}/udev/rules.d/touchscreen.rules
		echo '# i.MX specific touchscreen rules' >> ${IMAGE_ROOTFS}${sysconfdir}/udev/rules.d/touchscreen.rules
		echo 'SUBSYSTEM=="input", KERNEL=="event[0-9]*", ENV{ID_INPUT_TOUCHSCREEN}=="1", SYMLINK+="input/touchscreen0"' >> ${IMAGE_ROOTFS}${sysconfdir}/udev/rules.d/touchscreen.rules
	fi
	echo '# LVDS calibration matrix' >> ${IMAGE_ROOTFS}${sysconfdir}/udev/rules.d/touchscreen.rules
	echo 'SUBSYSTEM=="input", KERNEL=="event[0-9]*", ENV{ID_INPUT_TOUCHSCREEN}=="1", ENV{LIBINPUT_CALIBRATION_MATRIX}="4.023985 -0.041337 0.003694 -0.086464 4.011504 0.000577"' >> ${IMAGE_ROOTFS}${sysconfdir}/udev/rules.d/touchscreen.rules
}

do_rootfs[depends] += " \
    ${@bb.utils.contains('PACKAGE_INSTALL', 'weston-rdp-service', 'openssl-native:do_populate_sysroot', '', d)} \
"

generate_rdp_tls_key() {
    dest=${IMAGE_ROOTFS}/etc/xdg/weston
    mkdir -p $dest

    if [ ! -f $dest/rdp.key ]; then
        openssl req -x509 -newkey rsa:2048 -nodes \
            -keyout $dest/rdp.key \
            -out $dest/rdp.crt \
            -days 9999 \
            -subj "/CN=weston"
        chmod 0600 $dest/rdp.key
        chmod 0644 $dest/rdp.crt
    fi
}

hide_weston_panel() {
    ini="${IMAGE_ROOTFS}${sysconfdir}/xdg/weston/weston.ini"

    # If panel-position already exists under [shell], replace it
    if sed -n '/^\[shell\]/,/^\[/{/panel-position=/p}' "$ini" | grep -q panel-position; then
        sed -i '/^\[shell\]/,/^\[/{s/^panel-position=.*/panel-position=none/}' "$ini"
    else
        # Otherwise, add it inside the [shell] section
        sed -i '/^\[shell\]/a panel-position=none' "$ini"
    fi
}
