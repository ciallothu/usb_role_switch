# USB Role Switch

**USB Role Switch** is a KernelSU WebUI module for switching USB Type-C **power roles** and **data roles** independently on rooted Android devices.

Repository: <https://github.com/ciallothu/usb_role_switch>

---

## Overview

USB Role Switch provides a simple WebUI for controlling USB Type-C role states through the Linux sysfs Type-C interface.

## Screenshots

<table>
  <tr>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/bb355e5d-b676-4ca8-a0c9-3d1f44b94d86" width="320" alt="USB Role Switch WebUI status screen" />
    </td>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/3c562d1a-3fc7-42b7-b554-716e8566b811" width="320" alt="USB Role Switch WebUI controls screen" />
    </td>
  </tr>
</table>

It allows a rooted device to switch:

- **Power role**
  - `source`
  - `sink`
- **Data role**
  - `host`
  - `device`

The module is designed for devices that expose USB Type-C role controls under:

```text
/sys/class/typec/port0/
```

Typical available nodes include:

```text
/sys/class/typec/port0/power_role
/sys/class/typec/port0/data_role
/sys/class/typec/port0/preferred_role
/sys/class/typec/port0/power_operation_mode
```

---

## Features

- **KernelSU WebUI interface**
- **Independent power role switching**
  - Set `source`
  - Set `sink`
  - Toggle power role
- **Independent data role switching**
  - Set `host`
  - Set `device`
  - Toggle data role
- **Preset role combinations**
  - Set `source + host`
  - Set `sink + device`
  - Toggle common role pair
- **Status display**
  - Current power role
  - Current data role
  - Preferred role
  - Power operation mode
  - Partner detection state
  - Available Type-C ports
- **Execution log**
- **MMRL action button support**
  - View current status
  - View recent logs

---

## Requirements

- Rooted Android device
- KernelSU-compatible module environment
- KernelSU WebUI support
- USB Type-C role control exposed by the kernel
- Writable sysfs role nodes on the target device

> [!IMPORTANT]
> This module cannot add USB role switching support to hardware, firmware, or kernels that do not already support it.

---

## Installation

1. Download the module ZIP from the release page.
2. Open KernelSU Manager or a compatible module manager.
3. Install the ZIP as a module.
4. Reboot the device.
5. Open the module WebUI from the module list.

---

## Usage

Open the module WebUI and use the buttons to switch roles.

### Power Role

| Button | Result |
|---|---|
| **Set source** | Sets the device as power source |
| **Set sink** | Sets the device as power sink |
| **Toggle power** | Switches between `source` and `sink` |

### Data Role

| Button | Result |
|---|---|
| **Set host** | Sets the device as USB host |
| **Set device** | Sets the device as USB device |
| **Toggle data** | Switches between `host` and `device` |

### Presets

| Button | Result |
|---|---|
| **Set source + host** | Sets power role to `source` and data role to `host` |
| **Set sink + device** | Sets power role to `sink` and data role to `device` |
| **Toggle pair** | Toggles between common role pairs |

---

## Command Line Usage

After installation, the main script is available at:

```sh
/data/adb/modules/usb_role_switch/bin/usb-role.sh
```

Examples:

```sh
su
/data/adb/modules/usb_role_switch/bin/usb-role.sh status
/data/adb/modules/usb_role_switch/bin/usb-role.sh power-source
/data/adb/modules/usb_role_switch/bin/usb-role.sh power-sink
/data/adb/modules/usb_role_switch/bin/usb-role.sh data-host
/data/adb/modules/usb_role_switch/bin/usb-role.sh data-device
/data/adb/modules/usb_role_switch/bin/usb-role.sh source-host
/data/adb/modules/usb_role_switch/bin/usb-role.sh sink-device
/data/adb/modules/usb_role_switch/bin/usb-role.sh toggle-power
/data/adb/modules/usb_role_switch/bin/usb-role.sh toggle-data
/data/adb/modules/usb_role_switch/bin/usb-role.sh toggle-pair
```

A compatibility wrapper is also provided:

```sh
/data/adb/modules/usb_role_switch/bin/usb-power.sh
```

---

## Logs

Logs are stored at:

```text
/data/adb/usb_role_switch/usb-role.log
```

The WebUI can display and clear logs directly.

---

## USB Role Notes

USB Type-C **power role** and **data role** are independent.

For example, the following combinations may be possible depending on the device and connected partner:

```text
source + host
sink   + device
sink   + host
source + device
```

The actual supported combinations depend on:

- Device hardware
- Kernel driver
- Firmware
- Cable
- Adapter
- Connected USB partner

> [!NOTE]
> Some devices only allow role switching when a USB partner is connected.
>
> If `partner: not present` is shown, role switching may fail or only partially apply.

---

## Troubleshooting

### Role Switching Fails

Check whether the role nodes are writable:

```sh
su
ls -l /sys/class/typec/port0/power_role
ls -l /sys/class/typec/port0/data_role
```

Check current role state:

```sh
su
cat /sys/class/typec/port0/power_role
cat /sys/class/typec/port0/data_role
cat /sys/class/typec/port0/power_operation_mode
```

Current active role is usually shown inside square brackets:

```text
[source] sink
host [device]
```

This means:

```text
power_role = source
data_role  = device
```

---

### `partner: not present`

No USB partner is currently detected.

Some devices do not allow power role or data role swapping unless a cable and partner device are already connected.

---

### `Permission denied`

The kernel driver may expose the node as read-only, or the current connection state may not allow role swapping.

Root permission alone does not guarantee role switching support.

---

### Charging Behaves Unexpectedly

Set the device back to the usual `sink + device` pair:

```sh
su
/data/adb/modules/usb_role_switch/bin/usb-role.sh sink-device
```

Then unplug and reconnect the charger.

---

## Safety

Changing USB roles may affect:

- Charging behavior
- USB data connection
- OTG behavior
- Connected USB devices

Use this module only if you understand the behavior of USB Type-C role switching on your device.

> [!WARNING]
> Incorrect role switching may cause unexpected charging or USB connection behavior.

The module does not apply automatic role changes on boot by default.

---

## Author

**GitHub:** [ciallothu](https://github.com/ciallothu)

---

## License

MIT License
