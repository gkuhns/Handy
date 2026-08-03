# Hardware drivers for Intel NPU (Microsoft-accepted + Linux official)

Handy’s OpenVINO / NPU path needs two layers:

1. **Device driver** — makes the NPU visible to the OS.
2. **OpenVINO Runtime** — provides the Execution Provider used by ONNX Runtime.

This document lists **officially accepted** sources only (Microsoft WHQL / Windows Update catalog side, and Intel’s documented Linux packages).

---

## Windows

### Detection (installer)

The NSIS installer (`src-tauri/nsis/intel-npu-drivers.nsh`) on `feature/intel-npu`:

- Detects Intel NPU / “AI Boost” / Neural processors via PnP.
- Checks whether a healthy driver is already present.
- **Only if NPU is present and the driver is missing** does it download and install:
  - Official **WHQL-signed** Intel NPU driver.
  - OpenVINO Runtime (prefers **winget** from the Microsoft package source; falls back to the official archive).

No user checkbox — install is automatic under those conditions. A reboot may still be required after the driver package finishes.

### Official packages

| Component | Official source | Notes |
|-----------|-----------------|-------|
| **Intel NPU Driver** | [Intel Download Center – NPU Driver Windows](https://www.intel.com/content/www/us/en/download/794734/intel-npu-driver-windows.html) | WHQL-signed. Supports Core Ultra (Meteor / Lunar / Arrow / Panther Lake generations). |
| **OpenVINO Runtime** | [OpenVINO Windows install docs](https://docs.openvino.ai/2026/get-started/install-openvino/install-openvino-windows.html) · WinGet: `Intel.OpenVINOToolkit.2026.2.0` | WinGet uses Microsoft’s package source. Archive install is also supported. |

Manual install (if the automatic step is skipped or fails):

1. Install the NPU driver from the Intel link above.
2. Install OpenVINO Runtime (WinGet preferred):
   ```powershell
   winget install --id Intel.OpenVINOToolkit.2026.2.0 -e --source winget
   ```
3. Reboot if the driver installer requests it.
4. In Handy, set **ORT accelerator** to `Npu` or `OpenVino`.

### Microsoft-accepted status

- The Intel NPU driver published on the Intel Download Center is **WHQL-signed** and is the same class of driver Microsoft accepts for Windows Update / Device Manager updates.
- OpenVINO Runtime via **winget** is distributed through Microsoft’s package infrastructure.
- Windows ML also ships an OpenVINO Execution Provider package through Windows Update on supported builds; Handy’s path uses the classic ONNX Runtime + OpenVINO EP, which still relies on the runtime + NPU driver above.

---

## Linux

Linux does not use the NSIS installer. Use distro / Intel packages.

### NPU device driver

- Kernel support and user-space Level Zero / NPU stacks evolve with kernel version and Intel’s out-of-tree modules.
- Follow Intel’s current **OpenVINO + NPU** Linux guide for your distro (Ubuntu is the best-documented target).
- Prefer packages or modules published by Intel or your distribution — avoid unsigned third-party blobs.

### OpenVINO Runtime

Official options:

```bash
# Archive method (works on most distros):
# https://docs.openvino.ai/2026/get-started/install-openvino/install-openvino-archive-linux.html

source /opt/intel/openvino/setupvars.sh   # after install
```

Or use the distribution packages / Intel’s APT repository when available for your Ubuntu version.

After install, verify device visibility and launch Handy with the OpenVINO environment sourced (or set `OPENVINO_INSTALL_DIR` / library path as required by the linked ORT build).

---

## What Handy does *not* do

- Does not ship unsigned or reverse-engineered drivers.
- Does not install GPU drivers (NVIDIA/AMD) or non-Intel NPUs in this path.
- Does not force a reboot; if the Intel package requires one, the user completes it.
- Does not claim Windows Update exclusivity — it uses the same official WHQL package Microsoft would accept.

---

## Updating the bundled download URLs

When Intel ships a newer NPU driver or OpenVINO toolkit, update the defines at the top of:

`src-tauri/nsis/intel-npu-drivers.nsh`

```
!define INTEL_NPU_DRIVER_URL "..."
!define OPENVINO_ARCHIVE_URL "..."
```

Keep versions aligned with the OpenVINO EP expected by the `ort-openvino` feature in the `gkuhns/transcribe-rs` fork.
