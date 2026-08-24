# AIC8800D80 Ubuntu Wi-Fi 6 + Bluetooth 5.3

Ubuntu integration files for AIC8800D80 USB adapters. This repository records the
working USB-mode switch, DKMS/udev integration, and Bluetooth compatibility path
validated on an Ubuntu 24.04.4 amd64 system with kernel 6.17.0-14-generic.

本项目为 AIC8800D80 USB 网卡提供 Ubuntu 集成文件，记录已验证的 USB 模式切换、
DKMS/udev 集成和蓝牙兼容方案。测试环境为 Ubuntu 24.04.4 amd64、
`6.17.0-14-generic` 内核。

## Hardware / 硬件识别

The adapter is sold under many names such as “Wi-Fi 6 USB adapter” or “AX5400
USB adapter”. The chipset is AIC8800D80. USB IDs can change during startup:

| Stage | USB ID | Meaning |
|---|---|---|
| Virtual driver disk seen on the tested adapter | `a69c:5721` | 3.9 MB mass-storage mode |
| Firmware-loader stage | `a69c:8d80` | AIC firmware loader |
| Operational combo device | `368b:8d81` | Wi-Fi + Bluetooth interface |

The commonly quoted `0bda:8800` ID is not universal; do not send a modeswitch
command to an unconfirmed device. Run `lsusb` first.

这个型号会在启动过程中切换 USB ID。`0bda:8800` 并不是所有贴牌设备都使用，
不要对未确认的设备发送厂商专用切换命令。

## What this repository changes / 本仓库包含的内容

- `install-aic8800d80-ubuntu.sh` — installs dependencies, the upstream driver
  branch, the tested modeswitch rule, and udev binding rule.
- `verify-aic8800d80.sh` — read-only post-install diagnostic report.
- `udev/99-aic8800d80-ubuntu.rules` — ejects the virtual disk and binds the Wi-Fi
  interface after the device reaches `368b:8d81`.
- `usb_modeswitch/a69c:5721` — switches the tested `a69c:5721` disk stage to
  `a69c:8d80`.
- `CHANGELOG.md` — kernel and Bluetooth fixes found during testing.

The driver and firmware remain upstream components. This repository does not
include the Windows executable or redistribute firmware binaries.

## Install / 安装

On Ubuntu, connect Ethernet temporarily if the machine has no working network:

```bash
git clone https://github.com/zwm521gmailcom/aic8800d80-ubuntu.git
cd aic8800d80-ubuntu
sudo bash install-aic8800d80-ubuntu.sh
```

The default upstream branch is `legacy-mcu1`, selected for devices that report
`chip_id=7, chip_mcu_id=1`. For a device with `chip_mcu_id=0`, use:

```bash
sudo AIC8800_BRANCH=main bash install-aic8800d80-ubuntu.sh
```

拔掉网卡，等待约 5 秒，再插回。切换完成后，检查：

```bash
lsusb
lsusb -t
iw dev
bluetoothctl list
```

## Bluetooth / 蓝牙

Combo adapters should use the distribution `btusb` driver after `aic_load_fw`
initializes the device. The `aic_zlp_quirk` module is scoped to `368b:8d81` and
works around the AIC ACL bulk-transfer zero-length-packet behavior. If HCI
reports `Opcode 0x0c03 failed: -110`, completely unplug and reinsert the adapter
after confirming that generic `btusb` owns interfaces 0 and 1.

组合网卡的蓝牙应由系统自带 `btusb` 处理；`aic_zlp_quirk` 只针对 `368b:8d81`
启用 AIC ACL bulk 传输兼容。若出现 HCI `-110` 超时，先确认接口 0/1 使用
`btusb`，然后完整拔插一次网卡。

Verify a working controller:

```bash
hciconfig -a
bluetoothctl show
bluetoothctl
power on
scan on
```

## Troubleshooting / 排错

1. **Only a 3.9 MB disk appears** — confirm `usb-modeswitch` is installed and
   the device is really `a69c:5721`; unplug/reinsert once.
2. **No Wi-Fi interface** — check `lsusb -t`, `dmesg | grep -Ei 'aic|firmware'`,
   Secure Boot, and the udev rule. The tested interface name was
   `wlx90de800c7bdb`; names vary by MAC address.
3. **Bluetooth HCI timeout** — remove any old custom `aic_btusb` rule/module,
   keep standard `btusb` plus `aic_zlp_quirk`, and physically replug.
4. **Kernel update** — rebuild/reinstall DKMS modules for the new kernel.

Generate a report without changing the system:

```bash
sudo bash verify-aic8800d80.sh
```

## USB port guidance / USB 接口建议

The adapter negotiated USB 2.0 high-speed (480 Mbps) on the tested machine, so
USB 2.0 and USB 3.x data ports are compatible. Prefer a rear motherboard port on
desktops and avoid unpowered hubs. If 2.4 GHz Wi-Fi is noisy on a USB 3.x port,
use a short extension cable or a USB 2.0 port. USB-C requires a data-capable
adapter, not a charge-only adapter.

## Attribution / 致谢

This repository integrates, rather than replaces, community work:

- [shenmintao/aic8800d80](https://github.com/shenmintao/aic8800d80)
- [olamellberg/AIC8800D80](https://github.com/olamellberg/AIC8800D80)

Please follow the upstream licenses and review firmware redistribution terms
before publishing binary firmware files.
