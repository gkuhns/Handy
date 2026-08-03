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
| [CONTEXT.md](./CONTEXT.md) | Dense summary for AI agents / PR descriptions |

## Status (2026-08-03)

- [x] Fork + branch created
- [x] Documentation and context packs
- [ ] Upstream `ort` / `transcribe-rs` OpenVINO EP support (blocker for clean integration)
- [ ] Handy settings + UI + packaging for OpenVINO/NPU
- [ ] CI matrix entry for Intel NPU hardware (or documented manual test gate)

## Related upstream discussion

- Handy Discussion #726 (NPU request; maintainer: PRs welcome; bundling is the blocker)
- Handy PR #1058 (CPU/GPU accelerator selection + experimental DirectML era)
