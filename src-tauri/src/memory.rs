//! glibc allocator tuning (Linux only).
//!
//! Each dictation allocates multi-megabyte transient buffers — the captured
//! 16 kHz PCM (~64 KB per second, held twice: once for transcription, once
//! for the history WAV) plus the transcription engine's per-run mel/FFT
//! scratch (~80 KB per second of audio). After a long recording those pages
//! sit in glibc's free lists instead of returning to the OS, so the process
//! RSS stays high until the next model unload. `malloc_trim(0)` hands free
//! pages back to the OS via madvise and is thread-safe.

#[cfg(all(target_os = "linux", target_env = "gnu"))]
pub fn trim_freed_memory() {
    // SAFETY: malloc_trim is part of glibc and documented as safe to call
    // from any thread; it walks free lists and returns free pages to the OS.
    unsafe {
        libc::malloc_trim(0);
    }
}

#[cfg(not(all(target_os = "linux", target_env = "gnu")))]
pub fn trim_freed_memory() {}
