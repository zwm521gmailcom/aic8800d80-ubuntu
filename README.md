# AIC8800D80 Ubuntu Wi‑Fi 6 + Bluetooth 5.3

Ubuntu integration files for AIC8800D80 USB Wi‑Fi/Bluetooth adapters.
本项目为 AIC8800D80 USB 无线网卡及蓝牙组合设备提供 Ubuntu 集成文件。

This repository documents the USB-mode switch, pinned upstream DKMS driver,
udev binding, and Bluetooth compatibility path that were tested on Ubuntu
24.04.4 amd64.
本仓库记录已经测试的 USB 模式切换、固定版本上游 DKMS 驱动、udev 绑定规则和
蓝牙兼容方案，测试系统为 Ubuntu 24.04.4 amd64。

## Current status / 当前状态

- **Runtime validated / 已完成运行时验证:** Ubuntu kernel `7.0.0-30-generic`.
  The adapter auto-connected after reboot, Wi‑Fi and Bluetooth were present,
  and eight gateway pings completed with 0% packet loss.
  Ubuntu 内核 `7.0.0-30-generic` 已完成重启验证：网卡自动连接，Wi‑Fi 和蓝牙
  均正常，网关 8 次 Ping 丢包率为 0%。
- **Current DKMS / 当前 DKMS:** `aic8800/1.0.0` for the running `7.0.0-30`
  kernel, with `aic_zlp_quirk` loaded for the AIC Bluetooth ACL workaround.
  当前运行内核使用 `aic8800/1.0.0`，并加载了用于 AIC 蓝牙 ACL 兼容的
  `aic_zlp_quirk`。
- **Historical validation / 历史验证:** kernel `6.17.0-14-generic` was tested
  before the migration to the pinned `aic8800/1.0.0` package. Always validate
  again after a kernel or DKMS change.
  `6.17.0-14-generic` 是迁移到固定版本 `aic8800/1.0.0` 之前的历史测试路径；
  内核或 DKMS 变化后必须重新检测。

This is integration glue, not a replacement for the upstream driver project.
The repository does not include the Windows executable or redistribute binary
firmware files.
本项目是集成层，不替代上游驱动项目；仓库不包含 Windows 驱动 exe，也不重新
分发二进制固件。

## Hardware identification / 硬件识别

The adapter is sold under names such as “Wi‑Fi 6 USB adapter” and “AX5400 USB
adapter”. The chipset is AIC8800D80. One tested adapter changes USB IDs while
booting as follows.
市面上可能称为“Wi‑Fi 6 USB 网卡”或“AX5400 USB 网卡”，芯片本体为 AIC8800D80。
一只已测试设备在启动过程中会按下面顺序切换 USB ID。

| Stage / 阶段 | USB ID | Meaning / 含义 |
|---|---|---|
| Virtual driver disk / 虚拟驱动盘 | `a69c:5721` | 约 3.9 MB mass-storage mode / U 盘存储模式 |
| Firmware loader / 固件加载阶段 | `a69c:8d80` | AIC firmware-loader device / AIC 固件加载设备 |
| Operational combo device / 正常工作设备 | `368b:8d81` | Wi‑Fi + Bluetooth / Wi‑Fi + 蓝牙组合设备 |

The often-quoted `0bda:8800` ID is not universal. Run `lsusb` first and do
not send a modeswitch command intended for a different VID:PID.
网上常见的 `0bda:8800` 并不是所有贴牌设备都使用。请先运行 `lsusb`，不要把
其他设备的 modeswitch 命令直接套用过来。

## What this repository installs / 本仓库安装什么

- `install-aic8800d80-ubuntu.sh` — installs dependencies, checks for conflicting
  DKMS packages, clones a pinned upstream commit, runs the upstream DKMS
  installer, and installs the local integration rule.
  安装依赖、检查 DKMS 冲突、克隆固定的上游提交、运行上游 DKMS 安装器，并安装
  本仓库的集成规则。
- `verify-aic8800d80.sh` — read-only diagnostic report; it does not install,
  unload, or delete anything.
  只读检测报告脚本，不安装、卸载或删除任何内容。
- `udev/99-aic8800d80-ubuntu.rules` — binds operational USB interface 2 to
  `aic8800_fdrv`. The pinned upstream `aic.rules` owns virtual-disk ejection,
  so this repository does not duplicate that action.
  将工作状态 USB 接口 2 绑定到 `aic8800_fdrv`；虚拟磁盘弹出由固定版本上游的
  `aic.rules` 负责，本仓库不重复执行。
- `usb_modeswitch/a69c:5721` — tested modeswitch configuration for the
  `a69c:5721` disk stage.
  为已测试的 `a69c:5721` 虚拟磁盘阶段提供 modeswitch 配置。
- `CHANGELOG.md` — dated test results, kernel notes, and repair history.
  记录带日期的测试结果、内核说明和修复历史。

## Installation / 安装

### 1. Get the repository / 获取仓库

The installer needs temporary network access for Ubuntu packages and the pinned
upstream source. Use Ethernet, phone USB tethering, or another temporary link
if the adapter is not working yet.
安装器需要联网安装 Ubuntu 依赖并获取固定版本上游源码。如果无线网卡尚未工作，
请临时使用有线网、手机 USB 网络共享或其他网络。

```bash
git clone https://github.com/zwm521gmailcom/aic8800d80-ubuntu.git
cd aic8800d80-ubuntu
sudo bash install-aic8800d80-ubuntu.sh
```

### 2. Default chip path / 默认芯片路径

The default upstream branch is `legacy-mcu1`, selected for the tested device
reporting `chip_id=7, chip_mcu_id=1`. The installer pins commit
`4b717f40489f94988713474eb3bd7d75ba83b292`; it does not follow a moving branch
head.
默认上游分支为 `legacy-mcu1`，适用于已测试的 `chip_id=7, chip_mcu_id=1` 设备。
安装器固定使用提交
`4b717f40489f94988713474eb3bd7d75ba83b292`，不会随分支最新代码自动漂移。

### 3. Alternate MCU path / 另一 MCU 路径

For a device that reports `chip_mcu_id=0`, use the pinned current `main` commit.
该设备若报告 `chip_mcu_id=0`，可以使用固定的 `main` 提交：

```bash
sudo env AIC8800_BRANCH=main \
  AIC8800_REF=2895da26d8fe35bcec7483705d44c02c39e018fe \
  bash install-aic8800d80-ubuntu.sh
```

The `main` path is not covered by the `chip_mcu_id=1` runtime validation above.
Do not select it only because a product listing says “AX5400”.
`main` 路径没有纳入上面 `chip_mcu_id=1` 的运行时验证；不要仅因为商品写着
“AX5400”就选择该路径。

### 4. Existing DKMS migration / 已有 DKMS 迁移

If `dkms status` shows an older package such as `aic8800/radxa`, the installer
stops instead of silently letting two packages own the same kernel module. First
review the output. Only when the old package is no longer needed, explicitly
opt in to removing its DKMS registrations:
如果 `dkms status` 显示旧包，例如 `aic8800/radxa`，安装器会停止，避免两个包
同时管理同名内核模块。请先检查输出；确认旧包不再需要后，再显式允许删除其
DKMS 注册：

```bash
dkms status
sudo env AIC8800_REMOVE_LEGACY_DKMS=1 bash install-aic8800d80-ubuntu.sh
```

This removes the old DKMS registration for installed kernels; it does not format
disks or delete personal files. Keep the old kernel only if you have separately
rebuilt a compatible AIC module for it.
该操作会移除旧 DKMS 在已安装内核中的注册，不会格式化磁盘或删除个人文件。
如果还要保留旧内核，请先为旧内核单独编译兼容的 AIC 模块。

### 5. Replug and validate / 拔插并验证

After installation, unplug the adapter, wait about five seconds, and plug it
back into the same stable USB port. Then run:
安装完成后，请拔出网卡，等待约 5 秒，再插回同一个稳定 USB 口，然后运行：

```bash
uname -r
lsusb
lsusb -t
dkms status
nmcli -f DEVICE,TYPE,STATE,CONNECTION device
iw dev
bluetoothctl list
sudo bash verify-aic8800d80.sh
```

Expected signs of success / 成功时通常应看到：

- `368b:8d81` in `lsusb` / `lsusb` 中出现 `368b:8d81`；
- USB interface 2 uses `aic8800_fdrv`, interfaces 0 and 1 use `btusb`;
  USB 接口 2 使用 `aic8800_fdrv`，接口 0/1 使用 `btusb`；
- a `wlx...` Wi‑Fi interface and a controller from `bluetoothctl list`;
  出现 `wlx...` 无线接口，并且 `bluetoothctl list` 能看到蓝牙控制器；
- `dkms status` reports the running kernel as `installed`;
  `dkms status` 显示当前运行内核为 `installed`。

## Bluetooth compatibility / 蓝牙兼容

Combo adapters use the distribution `btusb` driver after `aic_load_fw`
initializes the device. `aic_zlp_quirk` is scoped to `368b:8d81` and works
around the AIC ACL bulk-transfer zero-length-packet behavior.
组合网卡在 `aic_load_fw` 初始化设备后使用系统自带的 `btusb` 驱动。
`aic_zlp_quirk` 仅针对 `368b:8d81`，用于解决 AIC ACL bulk 传输的零长度包兼容问题。

If HCI reports `Opcode 0x0c03 failed: -110`, confirm interfaces 0 and 1 are
owned by `btusb`, confirm `aic_zlp_quirk` is loaded, then physically unplug and
reinsert the adapter.
如果 HCI 报告 `Opcode 0x0c03 failed: -110`，请确认接口 0/1 由 `btusb` 接管、
确认 `aic_zlp_quirk` 已加载，然后完整拔插网卡。

```bash
lsusb -t
lsmod | grep -E 'aic|btusb|bluetooth'
bluetoothctl list
```

## Troubleshooting / 排错

### Only a 3.9 MB disk appears / 只看到 3.9 MB 虚拟磁盘

Confirm that the device is really `a69c:5721`, that `usb-modeswitch` is installed,
and that the USB port is a data-capable port. Unplug/reinsert once after the
check. Do not use the `0bda:8800` command unless `lsusb` proves that ID.
确认设备确实是 `a69c:5721`、已经安装 `usb-modeswitch`，并且 USB 口支持数据传输。
检查后拔插一次。除非 `lsusb` 明确显示该 ID，否则不要使用 `0bda:8800` 的命令。

### `368b:8d81` exists but Wi‑Fi is missing / 已有 `368b:8d81` 但没有 Wi‑Fi

Check `lsusb -t` for `Driver=[none]` on interface 2 and inspect the kernel log:
如果 `lsusb -t` 显示接口 2 为 `Driver=[none]`，请先检查：

```bash
lsusb -t
modinfo aic8800_fdrv | grep -E '^(filename|version|vermagic):'
journalctl -k -b --no-pager | grep -Ei 'aic|firmware|usb|error|fail'
```

The following is a temporary manual bind for the tested ID. Prefer rerunning
the pinned installer and physically replugging afterward so the rule is fixed
for future boots:
下面是针对已测试 ID 的临时手动绑定。建议之后重新运行固定版本安装器并拔插网卡，
让规则在以后开机自动生效：

```bash
sudo modprobe aic8800_fdrv
printf '368b 8d81\n' | sudo tee /sys/bus/usb/drivers/aic8800_fdrv/new_id
```

### DKMS conflict or new kernel / DKMS 冲突或升级内核

```bash
uname -r
dkms status
```

If an older `aic8800/*` package owns the same module, follow the migration
prompt and use `AIC8800_REMOVE_LEGACY_DKMS=1` only after reviewing it. After a
kernel update, reboot and rerun the read-only verification report.
如果旧的 `aic8800/*` 包管理同名模块，请按迁移提示处理，确认后再使用
`AIC8800_REMOVE_LEGACY_DKMS=1`。内核升级后请重启，再运行只读检测报告。

### Wi‑Fi is present but not connected / 有无线接口但没有连接

```bash
nmcli device wifi list
nmcli connection show
iw dev wlx90de800c7bdb link
```

Interface names vary with the adapter MAC address. Use the name shown by
`iw dev`; do not hard-code `wlx90de800c7bdb` on another adapter.
接口名会随网卡 MAC 地址变化。请使用 `iw dev` 显示的实际名称，不要在另一只网卡
上硬编码 `wlx90de800c7bdb`。

### USB instability / USB 口不稳定

The tested adapter negotiated USB 2.0 high-speed at 480 Mbps. Prefer a rear
motherboard data port, avoid an unpowered hub, and try a short USB extension
cable if a USB 3.x port causes 2.4 GHz interference.
已测试设备协商为 USB 2.0 High-Speed 480 Mbps。台式机优先使用主板后置数据口，
避免无源 HUB；如果 USB 3.x 口导致 2.4 GHz 干扰，可使用短 USB 延长线。

USB-C adapters must support data, not charging only. USB 2.0 and USB 3.x data
ports are both electrically compatible, but individual ports can differ in
power delivery and signal quality.
USB-C 转接头必须支持数据，不能只是充电转接头。USB 2.0 和 USB 3.x 数据口理论上
都兼容，但不同接口的供电和信号质量可能不同。

### Secure Boot / 安全启动

Third-party DKMS modules may not load when Secure Boot is enabled. Check the
firmware setting and the `dmesg`/`journalctl` output before changing drivers.
启用 Secure Boot 时第三方 DKMS 模块可能无法加载。修改驱动前，请先检查固件设置
以及 `dmesg`/`journalctl` 日志。

## Read-only diagnostic report / 只读检测报告

The report script collects kernel, USB, DKMS, udev, Wi‑Fi, Bluetooth, and recent
log information without installing or removing software:
检测脚本会收集内核、USB、DKMS、udev、Wi‑Fi、蓝牙和近期日志信息，不会安装或删除软件：

```bash
sudo bash verify-aic8800d80.sh
```

When asking for help, include the report together with `uname -r`, `lsusb`, and
`lsusb -t`, but remove Wi‑Fi passwords, tokens, and unrelated private data.
寻求帮助时，请连同 `uname -r`、`lsusb`、`lsusb -t` 一起提供报告，但请删除 Wi‑Fi
密码、令牌和无关的私人信息。

## Upstream and licensing / 上游与许可证

This repository integrates, rather than replaces, community work:
本仓库整合而不是替代以下社区项目：

- [shenmintao/aic8800d80](https://github.com/shenmintao/aic8800d80)
- [olamellberg/AIC8800D80](https://github.com/olamellberg/AIC8800D80)

The default installer executes the pinned upstream installer as root after
printing the commit. Review the pinned source and follow the upstream licenses.
默认安装器会打印固定提交，然后以 root 执行固定版本的上游安装器。使用前请审阅
固定版本源码，并遵守上游许可证和固件分发条款。

## Change history / 更新记录

See [CHANGELOG.md](CHANGELOG.md) for dated installation, kernel, DKMS, udev,
and reboot-validation records.
带日期的安装、内核、DKMS、udev 和重启验证记录请查看
[CHANGELOG.md](CHANGELOG.md)。
