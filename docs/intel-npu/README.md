# Intel NPU Acceleration for Handy

**Branch:** `feature/intel-npu`  
**Fork:** https://github.com/gkuhns/Handy  
**Upstream:** https://github.com/cjpais/Handy  
**Goal:** Run ONNX-based ASR models (Parakeet, Moonshine, SenseVoice, etc.) on Intel Neural Processing Units via OpenVINO, without burning CPU/GPU cycles.

## Why this exists

Handy already supports:

- **transcribe-cpp (GGML/GGUF Whisper-family):** Metal / Vulkan GPU backends
- **transcribe-rs (ONNX):** CPU today in shipped Windows builds; optional CUDA / DirectML / ROCm / CoreML / WebGPU via `ort` features (DirectML was deliberately dropped from Handy Windows builds for AVX2 baseline / crash reasons)

There is **no Intel NPU path** yet. Intel Core Ultra and similar chips expose an NPU that is ideal for low-power, always-on ASR. The maintainer has welcomed PRs and noted that bundling/CI—not the inference call itself—is the hard part.

## Recommended approach

Prefer a **unified interface** over vendor-specific kernels:

1. Primary target: **ONNX Runtime + OpenVINO Execution Provider** targeting device `NPU` (also works for Intel CPU/GPU via the same EP).
2. Secondary / longer-term: OpenVINO GenAI Whisper pipelines or Windows ML plugin EPs.
3. Avoid hard-coding a single NPU SKU; abstract behind accelerator selection already present in settings.

## Document map (read in order)

| File | Purpose |
|------|---------|
| [ARCHITECTURE.md](./ARCHITECTURE.md) | How acceleration works today; exact insertion points |
| [CONSTRAINTS.md](./CONSTRAINTS.md) | Why OpenVINO is not a one-line feature flag |
| [IMPLEMENTATION_PLAN.md](./IMPLEMENTATION_PLAN.md) | Ordered work items from scaffold → shippable |
| [BUILD_AND_TEST.md](./BUILD_AND_TEST.md) | Dev machine setup, env vars, verification |
| [APPLY.md](./APPLY.md) | How to apply / restore the remaining source edits |
| [CONTEXT.md](./CONTEXT.md) | Dense summary for AI agents / PR descriptions |

## Status (2026-08-03)

- [x] Fork + branch created (`gkuhns/Handy` @ `feature/intel-npu`)
- [x] Documentation and context packs
- [x] Forked `gkuhns/transcribe-rs` with `OrtAccelerator::{OpenVino, Npu}` + OpenVINO EP wiring (`device_type=NPU`)
- [x] Handy `src-tauri/Cargo.toml` points at the fork with `ort-openvino`
- [x] `OrtAcceleratorSetting::{OpenVino, Npu}` enum + mapping patches ready (see [APPLY.md](./APPLY.md))
- [ ] Apply the two source patches (run the restore workflow or local steps in APPLY.md)
- [ ] UI exposure / settings picker labels for the new accelerators (optional; values already serializable)
- [ ] Packaging / bundling of OpenVINO runtime + Intel NPU drivers (manual for now; see BUILD_AND_TEST.md)
- [ ] CI matrix entry for Intel NPU hardware (or documented manual test gate)

## Related upstream discussion

- Handy Discussion #726 (NPU request; maintainer: PRs welcome; bundling is the blocker)
- Handy PR #1058 (CPU/GPU accelerator selection + experimental DirectML era)
