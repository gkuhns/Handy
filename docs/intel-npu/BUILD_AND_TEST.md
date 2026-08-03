# Build and Test — Intel NPU / OpenVINO

## Prerequisites (developer machine)

1. **Intel NPU hardware** — e.g. Core Ultra with NPU enabled in BIOS/OS.
2. **NPU driver** — current Intel NPU driver for Windows or Linux.
3. **OpenVINO runtime** — matching a version supported by the ONNX Runtime OpenVINO EP you link against. Typical install:
   - Windows: Intel OpenVINO toolkit or runtime redistributable
   - Linux: OpenVINO packages or archive; `source /opt/intel/openvino/setupvars.sh`
4. **Handy build deps** — see repo root `BUILD.md` (Rust, Bun, Tauri, platform toolchains).

Environment variables commonly required:

```bash
# Example — adjust to your install layout
export OPENVINO_INSTALL_DIR=/opt/intel/openvino
# Windows: set OPENVINO_INSTALL_DIR and ensure PATH includes OpenVINO binaries
```

If using a custom ONNX Runtime build with OpenVINO EP:

```bash
export ORT_LIB_LOCATION=/path/to/onnxruntime/lib
export ORT_PREFER_DYNAMIC_LINK=1
```

## Current Handy build

```bash
git clone https://github.com/gkuhns/Handy.git
cd Handy
git checkout feature/intel-npu
bun install
bun tauri dev
```

ONNX models will use CPU until OpenVINO EP is active. Whisper-family models can still use GPU via transcribe-cpp where available.

## Drivers (installer)

On Windows, the NSIS package auto-installs the official WHQL Intel NPU driver and OpenVINO Runtime **only when**:

1. An Intel NPU is detected, and
2. The NPU driver is not already installed/healthy.

See [DRIVERS.md](./DRIVERS.md) for Microsoft-accepted and Linux official sources.
