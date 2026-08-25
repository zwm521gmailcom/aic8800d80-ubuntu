# Changelog / 修改记录

## 2026-08-25 — Ubuntu software upgrade note

- Ubuntu reported no remaining package updates and requested a reboot.
- Kernel `7.0.0-30-generic` is installed, and DKMS reports the AIC module built
  for it.
- The machine was still running `6.17.0-14-generic` during the initial
  inspection; the reboot validation is recorded in the entry below.

## 2026-08-25 — Ubuntu 7.0 runtime validation

- Rebooted into `7.0.0-30-generic` and confirmed DKMS `aic8800/1.0.0` is
  installed for the running kernel.
- The adapter enumerated as `368b:8d81`; USB interface 2 bound to
  `aic8800_fdrv`, while Bluetooth interfaces used `btusb`.
- `aic_zlp_quirk` loaded successfully and a Bluetooth controller was present.
- Wi-Fi auto-connected to the saved `ChinaNet-QCgn-5G` profile at approximately
  567/600 Mbps negotiated rate; eight gateway pings completed with 0% loss.

## 2026-08-25 — Ubuntu 7.0 重启实测

- 已重启进入 `7.0.0-30-generic`，确认运行内核对应的 DKMS `aic8800/1.0.0` 已安装。
- 网卡识别为 `368b:8d81`，USB 接口 2 使用 `aic8800_fdrv`，蓝牙接口使用 `btusb`。
- `aic_zlp_quirk` 加载成功，蓝牙控制器存在。
- Wi‑Fi 自动连接已保存的 `ChinaNet-QCgn-5G`，协商速率约 567/600 Mbps；网关 8 次 Ping 丢包 0%。

## 2026-08-25 — Ubuntu 软件升级记录

- Ubuntu 已完成软件升级，并提示需要重启。
- `7.0.0-30-generic` 已安装，DKMS 已为该内核编译 AIC 模块。
- 上游 `drivers/aic8800` 已针对 `7.0.0-30-generic` 完成编译；构建时的 GCC
  版本提示属于编译器差异警告，不等于编译失败。
- 初次检查时系统仍运行 `6.17.0-14-generic`；重启实测记录见下方条目。

## 2026-08-25 — Installer hardening / 安装器加固

- Pinned the default `legacy-mcu1` source to the tested upstream commit
  `4b717f40489f94988713474eb3bd7d75ba83b292`; the `main` path also requires an
  explicit pinned ref.
- Added a guarded migration check for older `aic8800/*` DKMS packages. The
  installer now stops and explains the explicit `AIC8800_REMOVE_LEGACY_DKMS=1`
  opt-in instead of silently creating competing module ownership.
- Removed the duplicate `a69c:5721` eject action from the local udev rule; the
  pinned upstream `aic.rules` already owns that action.

## 2026-08-25 — 安装器加固

- 默认 `legacy-mcu1` 源已固定到经过测试的上游提交；`main` 路径也要求明确的固定提交。
- 检测旧 `aic8800/*` DKMS 包；发现冲突时停止并提示显式迁移，不再静默覆盖模块。
- 移除本地 udev 规则中重复的 `a69c:5721` 弹出动作，由固定版本上游规则负责。

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
