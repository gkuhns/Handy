# Constraints and Blockers

## 1. No OpenVINO EP in the current Rust stack

- `transcribe-rs` `OrtAccelerator` has no OpenVINO variant.
- `ort` features used by Handy do not include OpenVINO.
- Enabling Intel NPU cleanly requires **upstream work** (or a fork of `ort` / `transcribe-rs`) before Handy can flip a settings enum and ship.

Workarounds that avoid waiting:

- Link against a custom ONNX Runtime build that includes OpenVINO EP and register the provider via lower-level `ort` APIs if exposed.
- Add a parallel engine path using `openvino` / `openvino-genai` Rust crates (Whisper-oriented; does not automatically cover Parakeet ONNX models).

## 2. Bundling and distribution (maintainer-stated blocker)

From upstream discussion: getting code working on a developer machine is relatively easy; **shipping and CI** are hard.

Implications:

- OpenVINO redistributables are large and version-coupled to the EP.
- NPU drivers and Windows/Linux packaging differ.
- Prefer dynamic loading / optional install of OpenVINO over statically embedding everything in the Handy installer.
- Document minimum driver / OpenVINO versions explicitly.

## 3. Windows ORT baseline CPU safety

Handy dropped DirectML-linked pyke ORT because AVX2-only static initializers crashed older CPUs. Any new ORT binary must:

- Use runtime CPU dispatch (or a portable baseline).
- Fail soft to CPU if NPU/OpenVINO is unavailable.
- Avoid expanding the crash surface for users without Intel NPU hardware.

## 4. Model operator coverage

Not every ONNX op used by Parakeet / Moonshine / SenseVoice is guaranteed on NPU. Expect:

- Partial graph offload (EP may fall back subgraphs to CPU).
- Possible need for quantized (INT8/FP16) model variants tuned for NPU.
- Per-model validation matrix (start with one recommended model, e.g. Parakeet).

## 5. Hardware fragmentation

"Intel NPU" spans multiple generations (Meteor Lake, Lunar Lake, Arrow Lake, etc.). Device string is typically `NPU` via OpenVINO, but performance and op support vary. Auto device selection (`AUTO`) can prefer NPU when beneficial; explicit `NPU` should remain available for testing.

## 6. Scope boundary

In-scope for this branch:

- ONNX engines via OpenVINO → NPU
- Settings, docs, packaging plan, detection UX

Out of scope (initially):

- GGML/whisper.cpp native NPU backend
- AMD Ryzen AI / Qualcomm QNN (same architectural pattern, different EPs)
- Guaranteeing real-time streaming on NPU for all models
