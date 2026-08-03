# Architecture: Acceleration Paths in Handy

## High-level pipeline

```
Microphone (cpal)
  → VAD (vad-rs / Silero ONNX)
  → ASR engine
       ├─ transcribe-cpp  → Whisper-family GGUF/GGML  (Metal / Vulkan / CPU)
       └─ transcribe-rs   → ONNX models               (Parakeet, Moonshine, …)
  → Post-process / paste
```

Intel NPU work targets the **ONNX path** first. GGML NPU support is a separate, harder problem.

## Settings surface (Handy)

Defined in `src-tauri/src/settings.rs`:

```rust
pub enum TranscribeAcceleratorSetting {
    Auto,  // default — whisper.cpp path
    Cpu,
    Gpu,
}

pub enum OrtAcceleratorSetting {
    Auto,     // default — ONNX path
    Cpu,
    Cuda,
    DirectMl, // serde rename "directml"
    Rocm,
}
```

Stored fields on `AppSettings`:

- `transcribe_accelerator: TranscribeAcceleratorSetting`
- `ort_accelerator: OrtAcceleratorSetting`
- `transcribe_gpu_device: i32` (whisper device index; `-1` / `0` = auto)

## Application point

`src-tauri/src/managers/transcription.rs`:

```rust
pub fn apply_accelerator_settings(app: &tauri::AppHandle) {
    use transcribe_rs::accel;

    let settings = get_settings(app);
    // ... log transcribe.cpp preference ...

    let ort_pref = match settings.ort_accelerator {
        OrtAcceleratorSetting::Auto => accel::OrtAccelerator::Auto,
        OrtAcceleratorSetting::Cpu => accel::OrtAccelerator::CpuOnly,
        OrtAcceleratorSetting::Cuda => accel::OrtAccelerator::Cuda,
        OrtAcceleratorSetting::DirectMl => accel::OrtAccelerator::DirectMl,
        OrtAcceleratorSetting::Rocm => accel::OrtAccelerator::Rocm,
    };
    accel::set_ort_accelerator(ort_pref);
}
```

Called from model load paths (`load_model_with_device`). Changing accelerator requires model unload/reload (already handled for GPU toggles).

## Downstream: transcribe-rs

`transcribe_rs::accel::OrtAccelerator` (non-exhaustive) currently includes:

| Variant   | Feature flag   | Notes |
|-----------|----------------|-------|
| Auto      | —              | Best available; **excludes** DirectML/WebGPU |
| CpuOnly   | onnx           | Default safe path |
| Cuda      | ort-cuda       | Large binary |
| TensorRt  | ort-tensorrt   | |
| DirectMl  | ort-directml   | Windows; sequential mode quirks |
| Rocm      | ort-rocm       | |
| CoreMl    | ort-coreml     | Apple |
| WebGpu    | ort-webgpu     | |
| Xnnpack   | ort-xnnpack    | CPU kernels |

**There is no `OpenVino` / `Npu` variant today.** Session creation maps the preference to ONNX Runtime execution providers inside `transcribe-rs` / `ort`.

## Downstream: ort (pykeio)

Handy depends on `transcribe-rs` which depends on `ort = "=2.0.0-rc.12"` (optional, onnx feature).

`ort` cargo features include CUDA, TensorRT, DirectML, ROCm, CoreML, WebGPU, XNNPACK — **not OpenVINO** as a first-class feature in the versions Handy uses.

OpenVINO EP support in the broader ONNX Runtime ecosystem is mature (device types `CPU`, `GPU`, `NPU`, `AUTO`), but the Rust `ort` crate must expose it (or sessions must be built against an OpenVINO-enabled ORT binary and configured via EP registration).

## Cargo posture in Handy (Windows)

From `src-tauri/Cargo.toml`:

- ONNX on Windows is intentionally **CPU-only** in the default product build.
- DirectML was removed because pyke prebuilt ORT with a global `/arch:AVX2` baseline crashed on pre-Haswell CPUs.
- Whisper GPU uses Vulkan (`transcribe-cpp` features `dynamic-backends`, `vulkan`) on x86_64 Windows.

Any NPU/OpenVINO integration must respect the same distribution constraints: no forced AVX2-only ORT, graceful fallback to CPU, optional or dynamically loaded EP libraries where possible.

## Insertion points for Intel NPU

1. **transcribe-rs `OrtAccelerator`** — add `OpenVino` (and optionally device hint `NPU` / `GPU` / `CPU`).
2. **ort crate** — OpenVINO EP feature + session provider registration with `device_type` = `NPU`.
3. **Handy `OrtAcceleratorSetting`** — add `OpenVino` / `Npu`; map in `apply_accelerator_settings`.
4. **UI** — settings dropdown / auto-detect status (reuse GPU device listing patterns).
5. **Packaging** — ship or document OpenVINO runtime + NPU drivers; CI/manual test matrix.

## What NPU does *not* use

- `TranscribeAcceleratorSetting` / `transcribe-cpp` Vulkan path — different stack.
- Apple CoreML / Neural Engine — different platform.
- DirectML alone — can hit NPU on some Copilot+ PCs, but is not the Intel OpenVINO NPU path and was removed from default Windows builds.
