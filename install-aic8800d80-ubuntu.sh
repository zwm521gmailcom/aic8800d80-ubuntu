#!/usr/bin/env bash

set -Eeuo pipefail

readonly UPSTREAM_REPO="${AIC8800_REPO_URL:-https://github.com/shenmintao/aic8800d80.git}"
readonly UPSTREAM_BRANCH="${AIC8800_BRANCH:-legacy-mcu1}"
UPSTREAM_REF="${AIC8800_REF:-}"
if [[ -z "${UPSTREAM_REF}" ]]; then
  case "${UPSTREAM_BRANCH}" in
    legacy-mcu1) UPSTREAM_REF="4b717f40489f94988713474eb3bd7d75ba83b292" ;;
    main) UPSTREAM_REF="2895da26d8fe35bcec7483705d44c02c39e018fe" ;;
    *)
      echo '未知上游分支；请同时设置 AIC8800_REF 固定提交。' >&2
      echo 'Unknown upstream branch; set AIC8800_REF to a pinned commit.' >&2
      exit 1
      ;;
  esac
fi
readonly UPSTREAM_REF
readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly LOG_FILE="${PWD}/aic8800d80-install-$(date +%Y%m%d-%H%M%S).log"
readonly UPSTREAM_DKMS_NAME="aic8800"
readonly UPSTREAM_DKMS_VERSION="1.0.0"
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
echo "Upstream / 上游: ${UPSTREAM_REPO} (${UPSTREAM_BRANCH} @ ${UPSTREAM_REF})"
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

legacy_dkms_versions=()
declare -A legacy_dkms_seen=()
while IFS= read -r dkms_line; do
  if [[ "${dkms_line}" =~ ^${UPSTREAM_DKMS_NAME}/([^,]+), ]]; then
    dkms_version="${BASH_REMATCH[1]}"
    if [[ "${dkms_version}" != "${UPSTREAM_DKMS_VERSION}" && -z "${legacy_dkms_seen[${dkms_version}]+seen}" ]]; then
      legacy_dkms_seen["${dkms_version}"]=1
      legacy_dkms_versions+=("${dkms_version}")
    fi
  fi
done < <("${SUDO[@]}" dkms status -m "${UPSTREAM_DKMS_NAME}" 2>/dev/null || true)

if ((${#legacy_dkms_versions[@]} > 0)); then
  echo "检测到旧 AIC DKMS 版本 / Older AIC DKMS versions detected: ${legacy_dkms_versions[*]}"
  if [[ "${AIC8800_REMOVE_LEGACY_DKMS:-0}" != 1 ]]; then
    echo '为避免同名内核模块覆盖，安装已停止。' >&2
    echo 'Installation stopped to avoid conflicting kernel-module ownership.' >&2
    echo '确认旧版本无须保留后，使用：' >&2
    echo "  sudo env AIC8800_REMOVE_LEGACY_DKMS=1 bash ${SCRIPT_DIR}/install-aic8800d80-ubuntu.sh" >&2
    exit 3
  fi
  for dkms_version in "${legacy_dkms_versions[@]}"; do
    echo "移除旧 DKMS / Removing old DKMS: ${UPSTREAM_DKMS_NAME}/${dkms_version}"
    "${SUDO[@]}" dkms remove -m "${UPSTREAM_DKMS_NAME}" -v "${dkms_version}" --all
  done
fi

TEMP_DIR="$(mktemp -d -t aic8800d80.XXXXXX)"
git clone --depth 1 --branch "${UPSTREAM_BRANCH}" "${UPSTREAM_REPO}" "${TEMP_DIR}/aic8800d80"
if ! git -C "${TEMP_DIR}/aic8800d80" cat-file -e "${UPSTREAM_REF}^{commit}" 2>/dev/null; then
  git -C "${TEMP_DIR}/aic8800d80" fetch --depth 1 origin "${UPSTREAM_REF}"
fi
git -C "${TEMP_DIR}/aic8800d80" checkout --detach "${UPSTREAM_REF}"
echo "Pinned upstream commit / 已固定上游提交: ${UPSTREAM_REF}"

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
