# Changelog / 修改记录

## 2026-08-25 — Ubuntu 24.04.4, kernel 6.17 validation

- Confirmed the tested adapter enumerates as `a69c:5721`, then `a69c:8d80`, and
  finally `368b:8d81`.
- Selected the `legacy-mcu1` upstream branch after the loader reported
  `chip_id=7, chip_mcu_id=1`.
- Built the upstream Wi-Fi, firmware-loader, and `aic_zlp_quirk` modules against
  kernel `6.17.0-14-generic`.
- Disabled the obsolete custom `aic_btusb` path and used the standard kernel
  `btusb` driver for Bluetooth.
- Verified `hci0` in `UP RUNNING` state, HCI 5.4, and successful nearby-device
  scanning.
- Added a tested `a69c:5721` usb-modeswitch configuration and udev binding rule.

## Known limitations / 已知限制

- A physical unplug/replug is the reliable recovery after firmware or Wi-Fi
  reset; software-only rebind may leave the device in a partially initialized
  state.
- Firmware binaries are intentionally not copied into this repository.
- Kernel updates require DKMS rebuilds and a fresh validation pass.
