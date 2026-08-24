#!/usr/bin/env bash

# Read-only AIC8800D80 report. It does not install packages or modify settings.
set -u

section() {
  printf '\n===== %s =====\n' "$1"
}

run() {
  printf '\n$'
  printf ' %q' "$@"
  printf '\n'
  "$@" 2>&1 || printf '[exit=%s]\n' "$?"
}

section 'OS and kernel / 系统与内核'
run uname -a
if [[ -r /etc/os-release ]]; then run cat /etc/os-release; fi

section 'USB IDs / USB 设备'
run lsusb
run lsusb -t

section 'Network / 网络'
run ip -brief link
if command -v nmcli >/dev/null 2>&1; then run nmcli -f DEVICE,TYPE,STATE,CONNECTION device; fi
if command -v iw >/dev/null 2>&1; then run iw dev; fi

section 'Bluetooth / 蓝牙'
if command -v bluetoothctl >/dev/null 2>&1; then run bluetoothctl list; run bluetoothctl show; fi
if command -v hciconfig >/dev/null 2>&1; then run hciconfig -a; fi
if command -v rfkill >/dev/null 2>&1; then run rfkill list; fi

section 'Modules and DKMS / 模块与 DKMS'
run bash -c "lsmod | grep -Ei 'aic|btusb|bluetooth|cfg80211' || true"
if command -v dkms >/dev/null 2>&1; then run dkms status; fi

section 'Relevant kernel log / 相关内核日志'
if [[ ${EUID} -eq 0 ]]; then
  dmesg --ctime 2>/dev/null | grep -Ei 'aic|8800|usb|firmware|bluetooth|btusb|hci' | tail -200 || true
else
  echo 'Run with sudo for kernel logs / 使用 sudo 可读取完整内核日志。'
fi

section 'Expected working state / 预期正常状态'
echo 'USB operational ID: 368b:8d81'
echo 'Wi-Fi: aic8800_fdrv bound to interface 2'
echo 'Bluetooth: btusb bound to interfaces 0 and 1; hci0 is present'
