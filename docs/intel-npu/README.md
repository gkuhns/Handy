# Intel NPU Acceleration for Handy (gkuhns fork only)

**No changes pushed to cjpais.**

## What works

1. **transcribe-rs fork** — https://github.com/gkuhns/transcribe-rs  
   - `ort-openvino` feature  
   - `OrtAccelerator::OpenVino` and `OrtAccelerator::Npu`  
   - OpenVINO EP registration; NPU uses `device_type=NPU`  
   - Optional env: `HANDY_OPENVINO_DEVICE` / `OPENVINO_DEVICE`

2. **Handy `feature/intel-npu`** — https://github.com/gkuhns/Handy/tree/feature/intel-npu  
   - `src-tauri/Cargo.toml` depends on the fork with `ort-openvino`  
   - Docs + apply patches under `docs/intel-npu/`

## One-time source finish (two tiny edits)

```bash
git clone https://github.com/gkuhns/Handy.git && cd Handy
git checkout feature/intel-npu
patch -p1 < docs/intel-npu/patches/settings.rs.patch
patch -p1 < docs/intel-npu/patches/transcription.rs.patch
```

Or hand-edit:

- `OrtAcceleratorSetting`: add `OpenVino` and `Npu`
- `apply_accelerator_settings`: map those to `accel::OrtAccelerator::{OpenVino,Npu}`

## Run

1. Install **OpenVINO** + **Intel NPU driver**.
2. `source` OpenVINO `setupvars` (or set `OPENVINO_INSTALL_DIR`).
3. `bun install && bun tauri dev`
4. Set ONNX accelerator to **npu** (or store key `ort_accelerator` = `"npu"`).
5. Load an ONNX model (e.g. Parakeet) and transcribe.

If the OpenVINO EP is missing, ORT falls back to CPU.

## Docs map

| File | Purpose |
|------|---------|
| [ARCHITECTURE.md](./ARCHITECTURE.md) | Insertion points |
| [CONSTRAINTS.md](./CONSTRAINTS.md) | Packaging / AVX / ops |
| [IMPLEMENTATION_PLAN.md](./IMPLEMENTATION_PLAN.md) | Phases |
| [BUILD_AND_TEST.md](./BUILD_AND_TEST.md) | Build/test |
| [APPLY.md](./APPLY.md) | Patch commands |
| [STATUS.md](./STATUS.md) | Snapshot |
| [CONTEXT.md](./CONTEXT.md) | AI context pack |
