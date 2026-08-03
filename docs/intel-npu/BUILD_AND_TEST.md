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

## Current Handy build (no OpenVINO yet)

```bash
git clone https://github.com/gkuhns/Handy.git
cd Handy
git checkout feature/intel-npu
bun install
bun tauri dev
```

ONNX models will use CPU. Whisper-family models can still use GPU via transcribe-cpp where available.

## After upstream OpenVINO support exists

Expected pattern (illustrative — exact feature names may differ):

```toml
# src-tauri/Cargo.toml (Windows x86_64 example)
transcribe-rs = { version = "…", features = ["onnx", "ort-openvino"] }
```

Then:

```bash
bun tauri dev
# In app: set ort_accelerator to openvino / npu, reload model
```

## Verification checklist

1. OpenVINO device query lists `NPU` (via OpenVINO hello_query_device or ORT provider options).
2. Handy logs show selected ORT accelerator after `apply_accelerator_settings`.
3. Load Parakeet (or other ONNX model); confirm no silent CPU fallback unless NPU fails.
4. Measure RTF vs CPU-only on the same utterance.
5. Toggle back to CPU; confirm model reload and stable transcription.
6. Run on a machine **without** NPU: app starts; NPU option disabled or falls back.

## Debug

- Enable Handy debug mode / verbose logging (`LogLevel::Debug`).
- Check Windows Event Viewer / Intel NPU driver status if session creation fails.
- Confirm OpenVINO and ORT major versions are a supported pair (see ONNX Runtime OpenVINO EP docs).

## Non-goals for local testing

- Do not require AVX2-only ORT builds.
- Do not block app launch on missing OpenVINO.
