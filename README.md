i.MX EasyEVSE MPU Meta Layer
============================

This repository holds the needed additional configuration to prepare the
i.MX Linux BSP and build the i.MX EasyEVSE Linux demo.


Yocto Image
-----------

The following instructions are abbreviated. Please consult the
[i.MX Linux Yocto Project User's Guide](https://www.nxp.com/docs/en/user-guide/IMX_YOCTO_PROJECT_USERS_GUIDE.pdf) for specific details.

* Default Build

    ```sh
    repo init -u https://github.com/nxp-imx-support/nxp-easyevse-mpu-manifest.git -b release/easyevse-mpu-2.0 -m imx-6.1.55-2.2.0_evse.xml
    repo sync
    ```

* Download the Plug & Trust Middleware (04.05.00)
    * Login to NXP.com and download the
      [EdgeLock SE05x Plug & Trust Middleware 04.05.00](https://www.nxp.com/webapp/sps/download/license.jsp?colCode=SE05x-PLUG-TRUST-MW-v04-05-00&appType=file1&DOWNLOAD_ID=null)
    * Copy the downloaded `se05x_mw_v04.05.00.zip` file to the directory
      where you ran `repo sync` above.

* Build the Image

    ```sh
    DISTRO=fsl-imx-wayland MACHINE=imx93evk-easyevse . imx-setup-easyevse.sh -b imx93 -r humble
    bitbake imx-image-easyevse
    ```

_Note:_ The image is configured by default for use with the LVDS display (DY1212W-4856).


* _Optional:_ To use the older MIPI-DSI display (MX8-DSI-OLED1A), disable LVDS display
  support before the final build step from above.

    ```sh
    echo 'DISTRO_FEATURES:remove = "LVDS_DISPLAY_SUPPORT"' >> conf/local.conf
    bitbake imx-image-easyevse
    ```

* _Optional:_ Disable SE050 authentication in the ISO 15118 stack before
  the final build step from above.

    ```sh
    echo 'FEATPROD_PKCS11_SUPPORTED ?= "OFF"' >> conf/local.conf
    bitbake imx-image-easyevse
    ```

* Install the image to eMMC or SDCard

    The same image shall be flashed to both the EVSE and EV boards.

    Consult the [i.MX Linux User's Guide](https://www.nxp.com/docs/en/user-guide/IMX_LINUX_USERS_GUIDE.pdf) for details connecting to and
    flashing the system image on the boards.

    * Configure the board to boot in "Download mode"

    * Flash the imx-image-easyevse WIC image compiled above. E.g., using
      [UUU](https://github.com/nxp-imx/mfgtools):

        ```sh
        cd tmp/deploy/images/imx93evk-easyevse
        uuu -b emmc_all imx-boot imx-image-easyevse-imx93evk-easyevse.wic.zst
        ```

    * Boot the image on eMMC or SDCard


Provisioning the SE050
----------------------

Provisioning the SE050 is only necessary once.

* Make sure the SE050 is plugged and working

    ```sh
    OPENSSL_CONF=/etc/ssl/openssl11_sss_se050.cnf nxp_iot_agent_demo
    se05x_GetInfo
    ```

* Run provision script

    ```sh
    cd ~/res/se05x/
    ./provision.sh
    ```

### Clearing the SE050

In certain cases, the SE050 memory may need to be purged and then
re-provisioned.

* Configure the `ssscli` tool

    ```sh
    cd /opt/ssscli
    pip3 uninstall cryptography
    pip3 install 'cryptography<38'
    python3 setup.py develop
    ```

* Connect to the SE050 and clear its internal memory

    ```sh
    cd ~
    ssscli connect se05x t1oi2c /dev/i2c-0:0x48
    ssscli se05x reset
    ```

* Re-provision the SE050 as instructed above

If you continue to experience difficulties, it might be necessary to
unassign your SE050 device at edgelock2go.com and reassign it to the
device group within the EdgeLock 2GO platform.


Wi-Fi Configuration
-------------------

Both connection to a typical Access Point (AP) via the `mlan0` interface
Wi-Fi Direct (WFD) via the `wfd0` interface and can be used. Please
refer to the
[i.MX Linux Reference Manual](https://www.nxp.com/docs/en/reference-manual/IMX_REFERENCE_MANUAL.pdf)
and
[NXP Wireless SoC Features and Release Notes for Linux](https://www.nxp.com/docs/en/release-note/RN00104.pdf)
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


Preparing the ROS demos
-----------------------

Configure the `cloud.conf` file with your credentials (consult the EasyEVSE User
Guide). This is necessary only on the EVSE system.

* EVSE

    ```sh
    cp .nxp-easyevse/cloud.conf ./
    vi cloud.conf
    ```


Run the Demo
------------

* EVSE

    ```sh
    .nxp-easyevse/evse-startup.sh all
    ```

* EV

    ```sh
    ./stx_pev_eth
    ```


Dependencies
------------

* meta-imx: <https://github.com/nxp-imx/meta-imx/>
* meta-iot-cloud: <https://github.com/intel-iot-devkit/meta-iot-cloud>
* nxp-easyevse-mpu: <https://github.com/nxp-imx-support/nxp-easyevse-mpu>


Supported Boards
----------------

* NXP i.MX 93 EVK (imx93evk)


Releases
--------

Releases are tracked against the i.MX Linux software releases. Supported
releases are listed below.

* Mickledore
    * 6.1.55_2.2.0


Reference
---------

* [i.MX Linux Yocto Project User's Guide](https://www.nxp.com/docs/en/user-guide/IMX_YOCTO_PROJECT_USERS_GUIDE.pdf)
* [i.MX Linux User's Guide](https://www.nxp.com/docs/en/user-guide/IMX_LINUX_USERS_GUIDE.pdf)
* [EdgeLock SE05x Plug & Trust Middleware 04.05.00](https://www.nxp.com/webapp/sps/download/license.jsp?colCode=SE05x-PLUG-TRUST-MW-v04-05-00&appType=file1&DOWNLOAD_ID=null)
