DESCRIPTION = "An i.MX EasyEVSE MPU image full with EVerest functionality installed."

LICENSE = "MIT"

require ../../../meta-imx/meta-imx-sdk/dynamic-layers/qt6-layer/recipes-fsl/images/imx-image-full.bb

# EVerest related packages
IMAGE_INSTALL += " \
        python3-pip \
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
        sqlite3 \
        everest-core \
        everest-admin-panel \
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
        "
        
INSANE_SKIP:everest-framework += "already-stripped"


ROOTFS_POSTPROCESS_COMMAND:append:mx93-nxp-bsp = " \
    install_demo; \
    install_demo_easyevse; \
    prepare_sigb_network_interface; \
    "

ROOTFS_POSTPROCESS_COMMAND:append:mx8-nxp-bsp = " \
    install_demo; \
    install_demo_easyevse; \
    prepare_sigb_network_interface; \
    "

install_demo_easyevse() {
	printf "\n\n[output]\nname=DSI-1\nmode=1920x1080@60\ntransform=rotate-270" >> ${IMAGE_ROOTFS}${sysconfdir}/xdg/weston/weston.ini
}

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
