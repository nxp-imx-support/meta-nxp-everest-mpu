
i.MX EasyEVSE EVerest MPU Meta Layer
====================================

This repository holds the needed additional configuration to prepare and build the i.MX Linux BSP for the EVSE part of the EasyEVSE on EVerest demo.

The NXP EasyEVSE EV Charging Station Development Platform on EVerest, rev. 2.0.
It is a combined solution, using i.MX93 running Linux for the EVSE, and i.MXRT106x running FreeRTOS for the EV.


Yocto Image for the EVSE
------------------------

The following instructions are abbreviated. Please consult the
[i.MX Linux Yocto Project User's Guide](https://www.nxp.com/docs/en/user-guide/UG10164.pdf) for specific details.

* Default Build

    ```sh
    repo init -u https://github.com/nxp-imx-support/nxp-easyevse-mpu-manifest -b release/everest-mpu-2.0 -m imx-6.12.20-2.0.0_everest.xml
    repo sync
    ```

* Download the Plug & Trust Middleware (04.07.01)

    * Login to NXP.com and download the
      [EdgeLock SE05x Plug & Trust Middleware 04.07.01](https://www.nxp.com/webapp/Download?colCode=SE05x-PLUG-TRUST-MW&appType=license)

    * Copy the downloaded `se05x_mw_v04.07.01.zip` file to the directory
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

The SE050 secure element can back TLS 1.2/1.3 for ISO 15118 charging sessions. When provisioned, the long-term private keys used for TLS authentication — both to the CSMS and during the EVSE-to-EV session — are generated inside the SE050 and stored there permanently, and the cryptographic operations using these keys are offloaded to the secure element rather than running on the application processor.

The corresponding certificates are provided as pregenerated hierarchies for both ISO 15118-2 and ISO 15118-20 and reside on the filesystem. They are installed on the EVSE Linux image at build time, as well as in the EV FreeRTOS application, and are used during the TLS authentication process.

Provisioning the keys into the SE050 is **optional**. The image already ships with the full PKI (certificate hierarchies and keys) on the filesystem, so the TLS-enabled and Plug & Charge configs run out of the box using the software (filesystem) key path — no SE050 step required.

Run the helper script only if you want the long-term private keys backed by the secure element (generated and stored inside the SE050, with crypto offloaded to hardware) instead of the filesystem:

```sh
cd /etc/everest
./gen_pki.sh -s
```

_Note:_ ISO 15118 TLS and PnC validate certificate validity windows, so set the EVSE and EV clocks correctly before the first handshake. For more details on the security architecture and tools, see [README.md](https://github.com/nxp-imx-support/everest-dev-keys/blob/master/README.md).

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


Set up a CSMS server for the Demos (optional)
---------------------------------------------

A CSMS is **optional**. The default config (`config-nxp-easyevse-demo-no-ocpp.yaml`) runs charging sessions fully standalone with no backend. A CSMS is only needed for OCPP 2.0.1 operation and for ISO 15118-2 Plug & Charge.

To run the OCPP demos, set up a CitrineOS CSMS and register the charge point:

* On the CSMS side — install and configure the CitrineOS OCPP server and Operator UI, then create a charging station, add an EVSE and connector, and add the NFC/RFID UIDs for authentication. See the [Charging Station Management System (CSMS) Installation and Configuration User Guide](https://www.nxp.com/doc/UG10362).

* On the EVSE side — point EVerest at the CSMS with the helper script (avoid editing `InternalCtrlr.json` / `SecurityCtrlr.json` by hand), then restart EVerest:

    ```sh
    /etc/everest/scripts/ocpp201-sp-config.sh {CSMS_HOST_IP} {your_charger_name} sp1
    systemctl restart everest
    ```

    `sp1` selects Security Profile 1 (basic HTTP authentication). `{your_charger_name}` is the Charging Station Id registered in CitrineOS (for example `cp001`).

_Note (RFID token type):_ when adding an authorization in CitrineOS, the token **Type must be set to `Local`**, not `ISO14443`. The upstream PN7160 NFC provider reports all RFID cards as `Local`; if the type does not match, authorization silently fails even with the correct UID. This applies to entries pushed via `sendLocalList` as well.

For the full charge-point registration flow, the `sendLocalList` call, PnC prerequisites, and clearing failed transactions, see section 8 of UG10357.


EVerest EVSE UI Application
---------------------------

NXP EasyEVSE on EVerest features a modern EVSE user interface built with NXP's GuiGuider and LVGL framework, designed for EVerest-based charging stations.

The GUI is an LVGL application running full-screen under Wayland. It does not control charging directly; it is a *view* onto the EVerest charging stack, which it follows by subscribing to EVerest's MQTT topics. Every value on screen reflects the last state reported by EVerest, the powermeter (SigBoard), the NFC reader, and the CSMS.

The GUI application is installed by the Yocto build and **starts automatically at boot** on the LVDS display; no manual launch or panel configuration is required (see [Startup](#startup)).


Run the Demos
-------------

### Startup

On power-up the demo comes up automatically, in this order. All three are started by systemd; no manual steps are required:

* **CG5317 PLC firmware** — loaded first by the `cg5317-firmware-load.service` systemd oneshot, since ISO 15118 communication runs over the HomePlug Green PHY. It is ordered before `everest.service`, so EVerest does not start until the PHY is up. The manual `host_loading_service` step required by earlier releases is **no longer needed** for any ISO 15118 configuration.
* **EVerest** — `everest.service` starts the charging stack with the configured scenario.
* **GUI** — the LVGL HMI launches on the touchscreen, showing live session data.

Start-up takes a few seconds. Wait for the GUI to reach the idle screen before starting a session.

### EVerest Configuration

EVerest now runs as a systemd service (`everest.service`) that starts automatically at boot. The active configuration is selected through systemd — **not** via `manager --conf` on the command line, as in earlier releases.

The service starts the manager with the config pointed to by the `EVEREST_CONFIG` variable in `/etc/default/everest`, which defaults to `/etc/everest/config.yaml`:

```sh
EVEREST_CONFIG=/etc/everest/config.yaml
```

`/etc/everest/config.yaml` is a symlink, pointing at `config-nxp-easyevse-demo-no-ocpp.yaml` out of the box.

#### Default configuration

At boot, EVerest starts `config-nxp-easyevse-demo-no-ocpp.yaml` (via the `config.yaml` symlink). This runs a charging session out of the box, with no CSMS setup required.

Offered (standalone, no backend needed):

* IEC 61851-1 basic AC (PWM fallback)
* ISO 15118-2 AC, EIM (NFC authorization)
* ISO 15118-20 AC, EIM and AC BPT (bidirectional)
* NFC authorization via a built-in dummy-token validator

Not offered:

* No OCPP / CSMS connection — sessions run fully standalone.
* No ISO 15118-2 Plug & Charge — PnC requires a CSMS and contract-certificate validation, so it cannot be exercised with this config.

#### Full-feature configuration

The all-features config is `config-nxp-easyevse-demo.yaml` — the same protocols plus OCPP 2.0.1 (CSMS-driven authorization), which also enables ISO 15118-2 PnC. It requires a CSMS endpoint, certificates, and a provisioned IdToken before a session will run.

#### Switching the active configuration

Choose one of the following.

**Persistent (survives reboot)** — point `EVEREST_CONFIG` at the desired config and restart the service:

```sh
sed -i 's|^EVEREST_CONFIG=.*|EVEREST_CONFIG=/etc/everest/config-nxp-easyevse-ISO20-sigb-nfc.yaml|' /etc/default/everest
systemctl restart everest
```

**One-off (until next reboot)** — override the config for a single run without editing the default file:

```sh
systemctl stop everest
EVEREST_CONFIG=/etc/everest/config-nxp-easyevse-ISO20-sigb-nfc.yaml manager --conf $EVEREST_CONFIG
```

Check status and logs with:

```sh
systemctl status everest
journalctl -u everest -f
```

#### Bring-up configurations

The following configs under `/etc/everest/` are **bring-up files**, not production configurations. Each enables a single charging mode and authentication/backend combination for validating one feature in isolation. Point `EVEREST_CONFIG` at one of them using either method above.

| Configuration file | Charging mode | Auth | CSMS / OCPP |
| --- | --- | --- | --- |
| `config-nxp-easyevse-basic-sigb.yaml` | IEC 61851-1 basic AC | none | none |
| `config-nxp-easyevse-basic-sigb-nfc.yaml` | IEC 61851-1 basic AC | EIM | none |
| `config-nxp-easyevse-basic-sigb-nfc-ocpp201.yaml` | IEC 61851-1 basic AC | EIM | OCPP 2.0.1 |
| `config-nxp-easyevse-basic-sigb-ocpp-dummyToken.yaml` | IEC 61851-1 basic AC | dummy token | OCPP 2.0.1 |
| `config-nxp-easyevse-ISO2-sigb.yaml` | ISO 15118-2 AC | none | none |
| `config-nxp-easyevse-ISO2-sigb-nfc.yaml` | ISO 15118-2 AC | EIM | none |
| `config-nxp-easyevse-ISO2-sigb-tls.yaml` | ISO 15118-2 AC | EIM (TLS enforced) | none |
| `config-nxp-easyevse-ISO2-sigb-ocpp201-nfc.yaml` | ISO 15118-2 AC | EIM  | OCPP 2.0.1 |
| `config-nxp-easyevse-ISO2-sigb-ocpp201-pnc.yaml` | ISO 15118-2 AC | Plug & Charge (contract cert) | OCPP 2.0.1 |
| `config-nxp-easyevse-ISO20-sigb-nfc.yaml` | ISO 15118-20 AC (incl. BPT) | EIM  | none |
| `config-nxp-easyevse-ISO20-sigb-dummytoken.yaml` | ISO 15118-20 AC (incl. BPT) | dummy token | none |
| `config-nxp-easyevse-ISO20-sigb-ocpp201-nfc.yaml` | ISO 15118-20 AC (incl. BPT) | EIM | OCPP 2.0.1|

_Note (TLS):_ the image ships with the PKI on the filesystem, so the `*-tls` and PnC configs run out of the box using the software key path. Optionally back the keys with the SE050 via `cd /etc/everest && ./gen_pki.sh -s` (see [Using the SE050](#using-the-se050)). ISO 15118 TLS and PnC validate certificate validity windows, so the EVSE and EV clocks must be set correctly first.

_Note (PnC):_ ISO 15118-2 Plug & Charge requires `config-nxp-easyevse-demo.yaml` (or `config-nxp-easyevse-ISO2-sigb-ocpp201-pnc.yaml`), a running CSMS, and contract certificates pre-provisioned on the EV. In a lab, a mock OCSP responder is also required — the contract certs in `everest-dev-keys` hardcode their OCSP AIA to `http://ocsp.local`. ISO 15118-20 PnC is not implemented in upstream EVerest; ISO 15118-20 sessions authenticate via EIM only. See section 8.7 of UG10357 for details.

### Driving the EV from the console

With the EVSE running and an EV firmware set up (above), drive a session from the EV console:

* Set/Check the date first ( ISO 15118 TLS and PnC check certificate validity windows; if the clock is wrong or unset the handshake fails ). The date must be consistent with the EVSE side:
   ```sh
   date get
   date set YYYY-MM-DDTHH:MM:SSZ
   ```
* Select protocol:
  ```sh
  protocol J1772/ISO15118-2/ISO15118-20
  ```
* Select auth method EIM (NFC) or PnC:
  ```sh
  auth EIM/PnC
  ```
* Connect CP line; assert the Control Pilot (simulate plug-in); SLAC and V2G start:
  ```sh
  cp connect
  ```
* Disconnect CP line; release the CP (simulate unplug):
  ```sh
  cp disconnect
  ```
* Begin energy transfer/Start charging session:
  ```sh
  charge start
  ```
* End energy transfer/Stop charging session:
  ```sh
  charge stop
  ```

_Note:_ Apply the date and protocol settings after every reboot.

Dependencies
------------

* meta-everest: <https://github.com/EVerest/EVerest/tree/main/yocto/scarthgap/meta-everest>
* meta-nxp-evse-common: <https://github.com/nxp-imx-support/meta-nxp-evse-common-mpu>
* meta-imx: <https://github.com/nxp-imx/meta-imx/>
* meta-nxp-demo-experience: <https://github.com/nxp-imx-support/meta-nxp-demo-experience>



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
* [EdgeLock SE05x Plug & Trust Middleware 04.07.01](https://www.nxp.com/webapp/Download?colCode=SE05x-PLUG-TRUST-MW&appType=license)
* [NXP EasyEVSE EV Charging Station Development Platform for MCU User Guide](https://www.nxp.com/webapp/Download?colCode=CCEVCPGSUG)
* [Charging Station Management
System (CSMS) Installation and Configuration User Guide](https://www.nxp.com/doc/UG10362)
