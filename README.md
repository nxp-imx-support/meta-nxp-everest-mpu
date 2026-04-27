i.MX EasyEVSE EVerest MPU Meta Layer
====================================

This repository holds the needed additional configuration to prepare and build the i.MX Linux BSP for the EVSE part of the EasyEVSE on EVerest demo.

The NXP EasyEVSE EV Charging Station Development Platform on EVerest, rev. 1.0, is an Early Access Release.
It is a combined solution, using i.MX93 running Linux for the EVSE, and i.MXRT106x running FreeRTOS for the EV.


Yocto Image for the EVSE
------------------------

The following instructions are abbreviated. Please consult the
[i.MX Linux Yocto Project User's Guide](https://www.nxp.com/docs/en/user-guide/UG10164.pdf) for specific details.

* Default Build

    ```sh
    repo init -u https://github.com/nxp-imx-support/nxp-easyevse-mpu-manifest -b release/everest-mpu-1.0 -m imx-6.12.20-2.0.0_everest.xml
    repo sync
    ```

* Download the Plug & Trust Middleware (04.05.00)

    * Login to NXP.com and download the
      [EdgeLock SE05x Plug & Trust Middleware 04.05.00](https://www.nxp.com/webapp/sps/download/license.jsp?colCode=SE05x-PLUG-TRUST-MW-v04-05-00&appType=file1&DOWNLOAD_ID=null)

    * Copy the downloaded `se05x_mw_v04.05.00.zip` file to the directory
      where you ran `repo sync` above.

* Download the Lumissil CG5317 Firmware and Tools package (04.05.000)

    * Login to NXP.com and download the
      [Lumissil CG5317 Firmware and Tools 4.05.000](https://www.nxp.com/webapp/sps/download/license.jsp?colCode=CG5317_4_05_000_tgz&appType=file1&DOWNLOAD_ID=null)

    * Copy the downloaded `CG5317_4.05.000.tgz` file to the directory
      where you ran `repo sync` above.

* Build the EVSE Image

    ```sh
    DISTRO=fsl-imx-wayland MACHINE=imx93evk-easyevse . imx-setup-everest.sh -b imx93
    bitbake imx-image-everest
    ```

_Note:_ The image is configured for use with the LVDS display (DY1212W-4856).


* Install the EVSE image to the eMMC or SDCard of the i.MX93 board

    Consult the [i.MX Linux User's Guide](https://www.nxp.com/docs/en/user-guide/UG10163.pdf) for details on connecting to and flashing the system image on the board.

    * Configure the board to boot in "Download mode"

    * Flash the imx-image-everest WIC image compiled above. E.g., using
      [UUU](https://github.com/nxp-imx/mfgtools):

        ```sh
        cd tmp/deploy/images/imx93evk-easyevse
        uuu -b emmc_all imx-boot imx-image-everest-imx93evk-easyevse.rootfs.wic.zst
        ```

    * Boot the image on eMMC or SDCard


MCU application for the EV
--------------------------

Login to NXP.com and download the [EasyEVSE EV MCU Application](https://www.nxp.com/webapp/Download?colCode=EasyEVSE_EVerest_EV_RT106x_SEVENSTAX&appType=license).

Consult the [NXP EasyEVSE EV Charging Station Development Platform for MCU User Guide](https://www.nxp.com/webapp/Download?colCode=CCEVCPGSUG) for details on connecting to and installing the downloaded application (EasyEVSE_EVerest_EV_RT106x_SEVENSTAX.zip) on the i.MXRT 106x board.


Using the SE050
---------------

The Secure Element SE050 is used for secure storage and usage of certificates for TLS authentication during ISO15118 charging sessions.
Current version of EasyEVSE on EVerest supports ISO 15118-2 EIM (External Identification Means) Charging with TLS 1.2.
The product provides a set of development keys and certificates which are used for demonstrating this functionality.
They are installed on the Linux image at build time for the EVSE, as well as in the EV FreeRTOS application, and are used
during TLS authentication process.

For the ISO15118-2 EIM with TLS demo, the EVSE certificates need to be copied in the SE050 once, before they are used the first time.
This can be done running the command:

```sh
cd /etc/everest
./gen_pki.sh -s
```

_Note:_ For more details, see [README.md](https://github.com/nxp-imx-support/everest-dev-keys/blob/master/README.md).

Wi-Fi Configuration
-------------------

Both connection to a typical Access Point (AP) via the `mlan0` interface
Wi-Fi Direct (WFD) via the `wfd0` interface and can be used. Please
refer to the [i.MX Linux Reference Manual](https://www.nxp.com/docs/en/reference-manual/RM00293.pdf)
and [NXP Wireless SoC Features and Release Notes for Linux](https://www.nxp.com/docs/en/release-note/RN00104.pdf)
for specific Wi-Fi details.

Connection to an AP uses the `mlan0` interfaces. Wi-Fi Direct uses the
`wfd0` interface.

* Edit the
  /etc/wpa_supplicant/wpa_supplicant-*interface*.conf
  file, choosing the appropriate `mlan0` or `wfd0` for _interface_.

    ```conf
    ctrl_interface=/var/run/wpa_supplicant
    ctrl_interface_group=0
    update_config=1
    ap_scan=1

    network={
    	key_mgmt=WPA-PSK
    	ssid="NAME-OF-YOUR-NETWORK"
    	psk="PASSWORD"
    }
    ```

* Enable the systemd wpa_supplicant@*interface* service to start on next
  boot and, optionally, start it immediately. Again, choose `mlan0` or
  `wfd0` as appropriate for the _interface_ name. E.g.,

    * AP:

        ```sh
        systemctl enable wpa_supplicant@mlan0
        systemctl start wpa_supplicant@mlan0
        ```

    * WFD:

        ```sh
        systemctl enable wpa_supplicant@wfd0
        systemctl start wpa_supplicant@wfd0
        ```


Set up a CSMS server for the Demos
----------------------------------

NXP EasyEVSE on EVerest is intended to be used with a Charging Station Management System (CSMS).

To set up a CSMS, install and configure a CitrineOS OCPP server, install CitrineOS Operator UI,
add a ChargePoint (EVSE) and NFC UIDs for authentication, consult the [Charging Station Management
System (CSMS) Installation and Configuration User Guide](https://www.nxp.com/doc/UG10362).


EVerest EVSE UI Application
---------------------------

NXP EasyEVSE on EVerest features a modern EVSE user interface built with NXP's GuiGuider and LVGL framework, designed for EVerest-based charging stations.

* Weston Panel Modifier Script
```bash
# Remove panel (default behavior)
/etc/everest/scripts/modify_panel.sh
```

The GUI application is installed by the Yocto build in `/usr/bin/` and is recommended to be started in the background:

```sh
/usr/bin/gui_guider &
```


Run the Demos
-------------

* Basic charging

    ```sh
    manager --conf /etc/everest/config-nxp-easyevse-basic-sigb.yaml
    ```

* Basic charging with NFC

    ```sh
    manager --conf /etc/everest/config-nxp-easyevse-basic-sigb-nfc.yaml
    ```

* ISO 15118-2 EIM charging

    ```sh
    /home/root/res/cg5317/host/host_loading_service -g gpiochip0 -o 18 \
        -f /home/root/res/cg5317/binaries/CG5317-04.05.000.0020-DEFAULT.bin \
        -c /home/root/res/cg5317/binaries/eth_evse_config.bin -i 1

    manager --conf /etc/everest/config-nxp-easyevse-ISO2-sigb.yaml
    ```

* Basic charging with NFC and OCPP

    ```sh
    manager --conf /etc/everest/config-nxp-easyevse-basic-sigb-nfc-ocpp201.yaml
    ```

* ISO 15118-2 EIM Charging with NFC and OCPP

    ```sh
    /home/root/res/cg5317/host/host_loading_service -g gpiochip0 -o 18 \
        -f /home/root/res/cg5317/binaries/CG5317-04.05.000.0020-DEFAULT.bin \
        -c /home/root/res/cg5317/binaries/eth_evse_config.bin -i 1

    manager --conf /etc/everest/config-nxp-easyevse-basic-sigb-nfc-ocpp201.yaml
    ```

* ISO 15118-2 EIM with TLS 1.2

    ```sh
    cd /etc/everest

    ./gen_pki.sh -s

    /home/root/res/cg5317/host/host_loading_service -g gpiochip0 -o 18 \
        -f /home/root/res/cg5317/binaries/CG5317-04.05.000.0020-DEFAULT.bin \
        -c /home/root/res/cg5317/binaries/eth_evse_config.bin -i 1

    manager --conf /etc/everest/config-nxp-easyevse-ISO2-sigb-tls.yaml
    ```

* ISO 15118-2 Plug & Charge (PnC) charging

    ```sh
    /home/root/res/cg5317/host/host_loading_service -g gpiochip0 -o 18 \
        -f /home/root/res/cg5317/binaries/CG5317-04.05.000.0020-DEFAULT.bin \
        -c /home/root/res/cg5317/binaries/eth_evse_config.bin -i 1

    manager --conf /etc/everest/config-nxp-easyevse-ISO2-sigb-ocpp201-pnc.yaml
    ```

Dependencies
------------

* meta-imx: <https://github.com/nxp-imx/meta-imx/>


Supported Boards
----------------

* EVSE: NXP i.MX 93 EVK
* EV: NXP i.MXRT 106x EVK

Releases
--------

Releases are tracked against the i.MX Linux software releases. Supported releases are listed below.

* Walnascar
    * imx-6.12.20-2.0.0


Reference
---------

* [i.MX Linux Yocto Project User's Guide](https://www.nxp.com/docs/en/user-guide/UG10164.pdf)
* [i.MX Linux User's Guide](https://www.nxp.com/docs/en/user-guide/UG10163.pdf)
* [i.MX Linux Reference Manual](https://www.nxp.com/docs/en/reference-manual/RM00293.pdf)
* [EdgeLock SE05x Plug & Trust Middleware 04.05.00](https://www.nxp.com/webapp/sps/download/license.jsp?colCode=SE05x-PLUG-TRUST-MW-v04-05-00&appType=file1&DOWNLOAD_ID=null)
* [NXP EasyEVSE EV Charging Station Development Platform for MCU User Guide](https://www.nxp.com/webapp/Download?colCode=CCEVCPGSUG)
* [Charging Station Management
System (CSMS) Installation and Configuration User Guide](https://www.nxp.com/doc/UG10362)
