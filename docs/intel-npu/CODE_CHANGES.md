# Applied code changes (feature/intel-npu)

## gkuhns/transcribe-rs (main)

- Feature `ort-openvino = ["onnx", "ort/openvino"]`
- `OrtAccelerator::OpenVino` and `OrtAccelerator::Npu`
- Session EP registration with OpenVINO; NPU forces `device_type=NPU`
- Env overrides: `HANDY_OPENVINO_DEVICE` / `OPENVINO_DEVICE`

## Handy Cargo.toml

```toml
transcribe-rs = { git = "https://github.com/gkuhns/transcribe-rs", default-features = false, features = ["onnx", "ort-openvino"] }
```

## settings.rs — extend enum

```rust
pub enum OrtAcceleratorSetting {
    #[default]
    Auto,
    Cpu,
    Cuda,
    #[serde(rename = "directml")]
    DirectMl,
    Rocm,
    OpenVino,
    Npu,
}
```

## transcription.rs — map in apply_accelerator_settings

```rust
OrtAcceleratorSetting::OpenVino => accel::OrtAccelerator::OpenVino,
OrtAcceleratorSetting::Npu => accel::OrtAccelerator::Npu,
```

## Runtime requirements

1. Intel NPU hardware + driver
2. OpenVINO runtime installed and on PATH / `OPENVINO_INSTALL_DIR`
3. ORT build with OpenVINO EP (via `ort` feature `openvino`)
4. In Handy settings store / UI: set `ort_accelerator` to `"npu"` or `"openvino"`
5. Reload ONNX model (Parakeet etc.)

Fallback: if OpenVINO EP fails to load, ORT falls through to CPU.
