# Applying the remaining Intel NPU source edits

The functional changes for OpenVINO / NPU are two small, localized edits:

1. **`src-tauri/src/settings.rs`** — add `OpenVino` and `Npu` to `OrtAcceleratorSetting`.
2. **`src-tauri/src/managers/transcription.rs`** — map those settings to `transcribe_rs::accel::OrtAccelerator::{OpenVino, Npu}` in `apply_accelerator_settings`.

## Option A — GitHub Actions self-heal (recommended)

1. Open https://github.com/gkuhns/Handy/actions/workflows/restore-intel-npu-sources.yml
2. Click **Run workflow** → branch `main` (or the feature branch) → **Run workflow**.
3. The job checks out `feature/intel-npu`, restores full `settings.rs` + `transcription.rs` from known-good bases, applies the two patches above, and pushes back to `feature/intel-npu`.

## Option B — Local apply

```bash
git checkout feature/intel-npu
git pull

# If settings.rs is still the temporary stub, restore the full file first:
curl -fsSL "https://cdn.jsdelivr.net/gh/gkuhns/Handy@b1b2d9f9072e55902a46ca6cc655e5893ed7a91d/src-tauri/src/settings.rs" \
  -o src-tauri/src/settings.rs

# Apply the two patches
patch -p1 < docs/intel-npu/patches/settings.rs.patch
patch -p1 < docs/intel-npu/patches/transcription.rs.patch

# Or equivalently (manual):
# In settings.rs, after the Rocm variant, add:
#     /// Intel OpenVINO (CPU/GPU/NPU via OpenVINO EP).
#     OpenVino,
#     /// Intel NPU via OpenVINO (`device_type=NPU`).
#     Npu,
#
# In managers/transcription.rs, in apply_accelerator_settings match, after Rocm arm:
#         OrtAcceleratorSetting::OpenVino => accel::OrtAccelerator::OpenVino,
#         OrtAcceleratorSetting::Npu => accel::OrtAccelerator::Npu,

git add src-tauri/src/settings.rs src-tauri/src/managers/transcription.rs
git commit -m "feat(intel-npu): map OpenVino/Npu accelerators"
git push
```

After either path, `OrtAcceleratorSetting::{OpenVino, Npu}` is available and wired through to the OpenVINO EP in the `gkuhns/transcribe-rs` fork (feature `ort-openvino`).
