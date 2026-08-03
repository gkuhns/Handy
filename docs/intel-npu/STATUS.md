# Status — Intel NPU path (no upstream cjpais push)

**Date:** 2026-08-03

## Completed

| Item | Location |
|------|----------|
| Fork transcribe-rs | https://github.com/gkuhns/transcribe-rs |
| OpenVINO/NPU in OrtAccelerator + session EP | `src/accel.rs`, `src/onnx/session.rs` |
| `ort-openvino` feature | `Cargo.toml` |
| Handy depends on fork with openvino | `src-tauri/Cargo.toml` on `feature/intel-npu` |
| Architecture / plan docs | `docs/intel-npu/` |

## Must finish on Handy branch (if not already merged in same series)

1. `OrtAcceleratorSetting::{OpenVino,Npu}` in `src-tauri/src/settings.rs`
2. Mapping arms in `apply_accelerator_settings` in `transcription.rs`
3. Optional UI dropdown values for openvino/npu
4. `cargo update` / lockfile refresh after first successful local build

## How to build & run

```bash
git clone https://github.com/gkuhns/Handy.git
cd Handy && git checkout feature/intel-npu
# Install OpenVINO; source setupvars
bun install
bun tauri dev
# Set ort_accelerator to npu in app settings (or store JSON)
```

## Explicitly not done

- No PR / push to cjpais/Handy or cjpais/transcribe-rs
- No CI NPU hardware
- No installer bundling of OpenVINO redistributables yet
