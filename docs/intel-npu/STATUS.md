# Status — Intel NPU path (no upstream cjpais push)

**Date:** 2026-08-10

## Critical finding (why NPU graph stays flat)

The ONNX Runtime binary downloaded by the `ort` crate (Microsoft prebuilts via the pyke CDN) **does not include the OpenVINO Execution Provider**.

- Enabling the Cargo feature `ort-openvino` only adds Rust bindings.
- There are **no** prebuilt distributions in ort’s `dist.tsv` that contain OpenVINO for Windows x64.
- When ONNX Acceleration is set to `npu`, code correctly requests `OpenVINO` with `device_type=NPU`, but EP registration fails.
- Inference falls back (CPU and/or other available paths). Task Manager NPU graph stays flat; GPU may still show activity from other work or partial paths.

`transcribe-rs` now calls `is_available()` and logs a clear error when the EP is missing so this is diagnosable in app logs.

### What is required for real NPU use

1. **Intel NPU driver** (installer already attempts this when NPU PnP is detected).
2. **OpenVINO Runtime** — e.g.
   ```
   winget install --id Intel.OpenVINOToolkit.2026.2.0 -e --source winget
   ```
3. An **ONNX Runtime build (or plugin EP)** that actually includes OpenVINO:
   - Intel’s OpenVINO EP plugin for ORT (NuGet `Intel.ML.OnnxRuntime.EP.OpenVINO` / Python `onnxruntime-ep-openvino`), **or**
   - A custom ORT built with OpenVINO, loaded via `load-dynamic` / `ORT_DYLIB_PATH`.

Until (3) is wired, selecting `npu` in Handy cannot light the NPU graph.

## Completed

| Item | Location |
|------|----------|
| Fork transcribe-rs | https://github.com/gkuhns/transcribe-rs |
| OpenVINO/NPU in OrtAccelerator + session EP | `src/accel.rs`, `src/onnx/session.rs` |
| Explicit `is_available()` + error log for missing EP | `session.rs` (2026-08-10) |
| `ort-openvino` feature | `Cargo.toml` |
| Handy depends on fork with openvino | `src-tauri/Cargo.toml` on `feature/intel-npu` |
| Settings `OpenVino` / `Npu` + mapping | `settings.rs`, `transcription.rs` |
| NSIS PnP detection + NPU driver install | `nsis/intel-npu-drivers.nsh` |
| Unsigned Windows NPU build workflow | `.github/workflows/build-windows-npu.yml` |
| Architecture / plan docs | `docs/intel-npu/` |

## Next (to make NPU actually run)

1. Switch ort to `load-dynamic` (or ship a custom ORT) and register Intel’s OpenVINO EP plugin at startup when NPU is selected.
2. Installer: winget install OpenVINO Toolkit when NPU is detected (in addition to the NPU driver).
3. Rebase / merge upstream Handy `main` (v0.9.5+) while preserving NPU wiring.
4. Rebuild and re-test; expect log line `OpenVINO EP available — targeting device_type=NPU` and non-zero NPU graph.

## How to build & run

```bash
git clone https://github.com/gkuhns/Handy.git
cd Handy && git checkout feature/intel-npu
# Install OpenVINO Runtime + NPU driver
winget install --id Intel.OpenVINOToolkit.2026.2.0 -e --source winget
bun install
bun tauri dev
# Set ort_accelerator to npu in app settings; fully quit and restart; unload model
```

## Explicitly not done

- No PR / push to cjpais/Handy or cjpais/transcribe-rs
- No CI NPU hardware
- OpenVINO EP not yet present inside the shipped ORT binary (see critical finding)
