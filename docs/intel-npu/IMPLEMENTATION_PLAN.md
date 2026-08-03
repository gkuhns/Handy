# Implementation Plan

Ordered so each step is independently reviewable. Stop and document when blocked on upstream.

## Phase 0 — Context and branch (done)

- [x] Fork `cjpais/Handy` → `gkuhns/Handy`
- [x] Branch `feature/intel-npu`
- [x] Docs under `docs/intel-npu/`

## Phase 1 — Upstream capability (blocker)

### 1a. `ort` (pykeio)

- Add OpenVINO execution provider feature (or document how to use a system OpenVINO-enabled ORT with dynamic EP plugins).
- Allow session options / provider options: `device_type` = `NPU` | `GPU` | `CPU` | `AUTO`.
- Ensure prebuilt or documented linkage does not force AVX2-only process init.

### 1b. `transcribe-rs`

- Extend `OrtAccelerator` with `OpenVino` (serde-friendly name).
- Map to ort OpenVINO EP; pass device preference (default `NPU` when user selects NPU, or `AUTO`).
- Include in `OrtAccelerator::available()` only when the feature is compiled / library present.
- Feature flag e.g. `ort-openvino` mirroring `ort-cuda` / `ort-directml`.

Deliverable: unit or integration test that loads a small ONNX model with provider list including OpenVINO when hardware is present.

## Phase 2 — Handy wiring

### 2a. Settings

File: `src-tauri/src/settings.rs`

- Add to `OrtAcceleratorSetting`:
  - `OpenVino` and/or `Npu` (prefer one public variant; map device internally).
- Keep serde rename stable; add migrations only if old values need remapping.
- Specta/`Type` already derives from the enum — regenerate TS bindings if required by project process.

### 2b. Apply settings

File: `src-tauri/src/managers/transcription.rs` → `apply_accelerator_settings`

```rust
OrtAcceleratorSetting::OpenVino | OrtAcceleratorSetting::Npu => {
    accel::OrtAccelerator::OpenVino // once upstream exists
}
```

Log the effective provider and device after session create when debug logging is on.

### 2c. UI

- Extend accelerator dropdown / help text for ONNX models.
- Show detection: OpenVINO present? NPU device listed?
- On failure to load with NPU, fall back to CPU and surface a non-fatal message (match existing GPU fallback tone).

### 2d. Cargo features

- Optional Windows (and Linux) feature path: `ort-openvino` via `transcribe-rs`.
- Default product builds stay CPU-safe for ONNX unless explicitly opted in.
- Document env vars: `OPENVINO_INSTALL_DIR`, OpenVINO `setupvars`, ORT library path if dynamic.

## Phase 3 — Packaging and CI

- Decide: ship OpenVINO redistributable vs require user install (Intel toolkit / runtime).
- Prefer optional download or installer component for NPU users.
- CI: compile with feature enabled on a standard runner; hardware test gate manual or self-hosted Intel NPU machine.
- Add troubleshooting section to main README linking here.

## Phase 4 — Validation matrix

| Model        | CPU | OpenVINO CPU | OpenVINO NPU | Notes |
|--------------|-----|--------------|--------------|-------|
| Parakeet V3  | baseline | | | First target |
| Moonshine    | | | | |
| SenseVoice   | | | | |
| Canary       | | | | |

Record latency, RTF, and any op fallback warnings.

## Phase 5 — Upstream PR strategy

1. Land `ort` + `transcribe-rs` changes (or depend on published versions).
2. Open Handy PR against `cjpais/Handy` with feature-gated support + docs.
3. Keep this fork branch for experimentation and Intel-specific packaging notes.

## Definition of done

- User with Intel NPU + OpenVINO runtime can select NPU/OpenVINO in settings.
- Parakeet (or chosen default ONNX model) transcribes successfully on NPU.
- Machines without NPU still install and run; selection falls back cleanly.
- Docs describe install, build flags, and failure modes.
