# Downstream fork policy

`gkuhns/Handy` is a **downstream overlay fork** of `cjpais/Handy`.

- **Upstream (`cjpais/Handy`) is the complete source of truth.**
- This repo does **not** independently evolve Handy. It tracks upstream and reapplies a small Intel NPU / OpenVINO delta.
- Target upstream at the time of this note: **Handy 0.9.6** (`cjpais/Handy` default branch).

## What this repo owns

Only the overlay:

1. `transcribe-rs` git dep → `gkuhns/transcribe-rs` with `onnx` + `ort-openvino`
2. `OrtAcceleratorSetting::{OpenVino, Npu}` + mapping in the transcription manager
3. Immediate model unload when the ONNX accelerator changes
4. Windows unsigned installer path (`signCommand` stripped, no updater artifacts)
5. NSIS Intel NPU / OpenVINO driver install when PnP detects an NPU
6. Bundled OpenVINO Execution Provider plugin (required for graphs to leave GPU/CPU)
7. `docs/intel-npu/*` and NPU CI (`build-windows-npu.yml`)

Everything else must come from upstream unchanged.

## Refresh procedure

```text
1. Fetch cjpais/Handy main (authoritative tree).
2. Merge/reset feature/intel-npu onto that tree.
3. Re-apply only the overlay list above.
4. Do not hand-edit unrelated Handy source to "catch up".
5. Build Windows NPU installer from the overlay branch.
```

Workflow: `.github/workflows/merge-upstream-0.9.5.yml` (name will track current upstream; it uses `PUSH_TOKEN`).

## Why NPU still does not run on hardware

Settings can show `ort_accelerator = npu` while Task Manager GPU stays busy and NPU stays flat.

Root cause: CI / the app currently load **Microsoft ONNX Runtime** (`onnxruntime-win-x64`). That binary **does not ship the OpenVINO Execution Provider**. Without `onnxruntime_providers_openvino.dll` (plus Intel NPU + OpenVINO runtime), ORT silently falls back to CPU or GPU.

Drivers alone are not enough. The session must:

- register OpenVINO EP
- set `device_type=NPU`
- create a **new** session after the setting change (stale GPU sessions stay on GPU)

Until the OpenVINO EP is bundled next to `onnxruntime.dll` and loaded at session create, hardware NPU will not move.
