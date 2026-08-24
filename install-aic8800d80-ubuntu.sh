#!/usr/bin/env bash

set -Eeuo pipefail

readonly UPSTREAM_REPO="${AIC8800_REPO_URL:-https://github.com/shenmintao/aic8800d80.git}"
readonly UPSTREAM_BRANCH="${AIC8800_BRANCH:-legacy-mcu1}"
readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly LOG_FILE="${PWD}/aic8800d80-install-$(date +%Y%m%d-%H%M%S).log"
TEMP_DIR=""

cleanup() {
  if [[ -n "${TEMP_DIR}" && -d "${TEMP_DIR}" ]]; then rm -rf -- "${TEMP_DIR}"; fi
}
trap cleanup EXIT

if [[ "$(uname -s)" != Linux ]]; then
  echo '错误 / Error: this installer must run on Ubuntu/Linux.' >&2
  exit 1
fi

if [[ ! -r /etc/os-release ]]; then
  echo '无法读取 /etc/os-release / Cannot identify the distribution.' >&2
  exit 1
fi
# shellcheck disable=SC1091
source /etc/os-release
if [[ "${ID:-}" != ubuntu && "${ID_LIKE:-}" != *debian* ]]; then
  echo "不支持的系统 / Unsupported distribution: ${PRETTY_NAME:-unknown}" >&2
  exit 1
fi

if [[ ${EUID} -eq 0 ]]; then SUDO=(); else SUDO=(sudo); fi
exec > >(tee -a "${LOG_FILE}") 2>&1

echo '=== AIC8800D80 Ubuntu installer / Ubuntu 安装器 ==='
echo "Upstream / 上游: ${UPSTREAM_REPO} (${UPSTREAM_BRANCH})"
echo "Kernel / 内核: $(uname -r)"
echo "Log / 日志: ${LOG_FILE}"

has_id() { lsusb -d "$1" >/dev/null 2>&1; }

echo
echo 'USB devices before install / 安装前 USB 设备：'
lsusb || true
recognized=false
for id in a69c:5721 a69c:8d80 a69c:8d81 a69c:8d83 368b:8d81; do
  if has_id "$id"; then echo "Detected / 检测到: ${id}"; recognized=true; fi
done
if [[ ${recognized} != true ]]; then
  echo '未检测到已知 AIC 阶段；请插入网卡后重试。'
  echo 'No known AIC stage detected; plug in the adapter and retry.'
  exit 2
fi

echo 'Installing packages / 安装依赖……'
"${SUDO[@]}" apt-get update
"${SUDO[@]}" apt-get install -y git dkms build-essential "linux-headers-$(uname -r)" \
  usb-modeswitch usb-modeswitch-data sg3-utils bluez usbutils rfkill network-manager

TEMP_DIR="$(mktemp -d -t aic8800d80.XXXXXX)"
git clone --depth 1 --branch "${UPSTREAM_BRANCH}" "${UPSTREAM_REPO}" "${TEMP_DIR}/aic8800d80"

echo 'Running upstream installer / 运行上游安装器……'
"${SUDO[@]}" bash "${TEMP_DIR}/aic8800d80/install.sh"

echo 'Installing tested integration rules / 安装已验证的集成规则……'
"${SUDO[@]}" install -D -m 0644 "${SCRIPT_DIR}/udev/99-aic8800d80-ubuntu.rules" \
  /etc/udev/rules.d/99-aic8800d80-ubuntu.rules
"${SUDO[@]}" install -D -m 0644 "${SCRIPT_DIR}/usb_modeswitch/a69c:5721" \
  /etc/usb_modeswitch.d/a69c:5721
"${SUDO[@]}" udevadm control --reload-rules
"${SUDO[@]}" depmod -a
"${SUDO[@]}" modprobe btusb || true
"${SUDO[@]}" modprobe aic_zlp_quirk || true

echo
echo 'Installation complete / 安装完成。'
echo 'Unplug the adapter, wait 5 seconds, and plug it back in before validation.'
echo '请拔出网卡，等待 5 秒，再插回，然后运行：'
echo "  sudo bash ${SCRIPT_DIR}/verify-aic8800d80.sh"
