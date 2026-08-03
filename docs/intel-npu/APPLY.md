# Apply remaining Handy source patches

`src-tauri/Cargo.toml` already points at `gkuhns/transcribe-rs` with `ort-openvino`.

Apply the two small source patches (or edit by hand):

```bash
cd Handy
git checkout feature/intel-npu
patch -p1 < docs/intel-npu/patches/settings.rs.patch
patch -p1 < docs/intel-npu/patches/transcription.rs.patch
```

Then build:

```bash
bun install
bun tauri dev
```

Set `ort_accelerator` to `npu` in app settings (or edit the store JSON).

OpenVINO runtime must be installed; optional `HANDY_OPENVINO_DEVICE=NPU`.
