# CONTEXT PACK — Intel NPU for Handy

Copy this file (or the whole `docs/intel-npu/` directory) into agent context when working on this feature.

## One-paragraph summary

Handy is a Tauri (Rust + React) offline speech-to-text app. Whisper-family models run via `transcribe-cpp` (GPU: Metal/Vulkan). Parakeet and other ONNX models run via `transcribe-rs` + `ort`. Intel NPU support should use **ONNX Runtime’s OpenVINO Execution Provider** with device `NPU`. The Rust stack (`ort` / `transcribe-rs`) does **not** yet expose OpenVINO; that is the primary blocker. Handy already has `OrtAcceleratorSetting` and `apply_accelerator_settings` in `transcription.rs` — extend those once upstream exists. Packaging and CI are harder than the inference call. This fork: `gkuhns/Handy`, branch `feature/intel-npu`.

## Key paths

| Path | Role |
|------|------|
| `src-tauri/src/settings.rs` | `OrtAcceleratorSetting`, `TranscribeAcceleratorSetting` |
| `src-tauri/src/managers/transcription.rs` | `apply_accelerator_settings`, model load |
| `src-tauri/Cargo.toml` | Feature matrix; Windows ONNX is CPU-only by policy |
| `docs/intel-npu/*` | This documentation set |

## Current OrtAcceleratorSetting variants

`Auto`, `Cpu`, `Cuda`, `DirectMl`, `Rocm` — **add** `OpenVino`/`Npu` after upstream support.

## Current transcribe-rs OrtAccelerator variants

`Auto`, `CpuOnly`, `Cuda`, `TensorRt`, `DirectMl`, `Rocm`, `CoreMl`, `WebGpu`, `Xnnpack` — **no OpenVINO**.

## Policy reminders

- Do not reintroduce AVX2-only ORT process crashes on older CPUs.
- Prefer graceful CPU fallback.
- Prefer optional/dynamic OpenVINO redistribution over mandatory installer bloat.
- Validate at least one ONNX model end-to-end on real NPU hardware before claiming support.

## Upstream links

- https://github.com/cjpais/Handy
- https://github.com/cjpais/transcribe-rs
- https://github.com/pykeio/ort
- ONNX Runtime OpenVINO EP documentation (device types include NPU)
- Handy Discussion #726 (NPU)

## Suggested next coding task

1. Prototype OpenVINO EP in a minimal `ort` session outside Handy.
2. Patch or PR `transcribe-rs` with `OrtAccelerator::OpenVino`.
3. Wire Handy enum + UI behind a cargo feature.
4. Document install steps for end users.
