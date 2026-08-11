# Status — Intel NPU path (no upstream cjpais push)

**Date:** 2026-08-11

## Critical finding (why NPU graph stayed flat)

Microsoft/pyke prebuilt ONNX Runtime **does not include the OpenVINO Execution Provider**.
Enabling `ort-openvino` only adds Rust bindings. Selecting `npu` requested `device_type=NPU`,
but registration failed and inference fell back (GPU/CPU activity, NPU graph flat).

## Fix in progress (2026-08-11)

`gkuhns/transcribe-rs` now:

1. Calls `OpenVINO::is_available()` and logs a clear error when the EP is missing.
2. Attempts to **register Intel’s OpenVINO EP plugin** at runtime via
   `Environment::register_ep_library` (`onnxruntime_providers_openvino.dll`).
3. Selects NPU hardware devices with `SessionBuilder::with_devices` (ORT V2 API).
4. Falls back to the classic EP list with explicit warnings if the plugin is absent.

### Plugin search order

1. `HANDY_OPENVINO_EP_LIBRARY` or `ORT_OPENVINO_EP_LIBRARY` env vars
2. Common install paths under `C:\Program Files\Intel\...`
3. `onnxruntime_providers_openvino.dll` next to the Handy executable or in `plugins\`

### What you need on the machine

```powershell
# 1) OpenVINO Runtime (required for the plugin’s native deps)
winget install --id Intel.OpenVINOToolkit.2026.2.0 -e --source winget

# 2) Place the OpenVINO EP plugin DLL where Handy can find it, e.g.:
#    - Next to Handy.exe as onnxruntime_providers_openvino.dll
#    - Or set:
# $env:HANDY_OPENVINO_EP_LIBRARY = "C:\path\to\onnxruntime_providers_openvino.dll"

# Plugin packages:
# - NuGet: Intel.ML.OnnxRuntime.EP.OpenVINO
# - PyPI: onnxruntime-ep-openvino (extract the .dll from the wheel)
```

### Expected log lines when it works

- `Registered OpenVINO EP plugin from ...`
- `Selecting OpenVINO device: ep=... hw=NPU ...`
- `Session using OpenVINO EP via plugin device selection`
- Task Manager **NPU** graph should move during Parakeet/Moonshine/Canary transcription

### Expected log lines when plugin is still missing

- `OpenVINO EP plugin not registered (...)`
- `OpenVINO plugin devices unavailable; falling back to classic EP list`
- `OpenVINO EP is NOT available in this ONNX Runtime binary`

## Completed

| Item | Location |
|------|----------|
| Fork transcribe-rs | https://github.com/gkuhns/transcribe-rs |
| OpenVINO/NPU accelerator enums | `src/accel.rs` |
| Plugin registration + NPU device select | `src/onnx/openvino_plugin.rs` |
| Session path uses plugin then fallback | `src/onnx/session.rs` |
| Handy settings OpenVino/Npu | `settings.rs`, `transcription.rs` |
| NSIS NPU driver install | `nsis/intel-npu-drivers.nsh` |
| Unsigned Windows NPU build workflow | `build-windows-npu.yml` |

## Still todo

1. Installer: winget-install OpenVINO Toolkit when NPU is detected; optionally ship or download the EP plugin DLL.
2. Rebase Handy `feature/intel-npu` onto upstream v0.9.5+.
3. Rebuild installer and re-test with plugin DLL present.
4. (Optional) Bundle `onnxruntime_providers_openvino.dll` + OpenVINO runtime redistributables in the installer.

## Explicitly not done

- No PR to cjpais/Handy or cjpais/transcribe-rs
- Plugin DLL not yet bundled in the installer artifact
