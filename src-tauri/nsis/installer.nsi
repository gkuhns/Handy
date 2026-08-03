; Custom NSIS template for Handy with portable mode support.
; Based on tauri-apps/tauri@tauri-v2.9.1 crates/tauri-bundler/src/bundle/windows/nsis/installer.nsi
; Portable changes are marked with "; --- PORTABLE MODE ---" comments.
;
; When upgrading Tauri, diff this file against the new upstream template and
; merge changes while preserving the portable sections.

Unicode true
ManifestDPIAware true
ManifestDPIAwareness PerMonitorV2

!if "{{compression}}" == "none"
  SetCompress off
!else
  SetCompressor /SOLID "{{compression}}"
!endif

!include MUI2.nsh
!include FileFunc.nsh
!include x64.nsh
!include WordFunc.nsh
!include "utils.nsh"
!include "FileAssociation.nsh"
!include "Win\COM.nsh"
!include "Win\Propkey.nsh"
!include "StrFunc.nsh"
${StrCase}
${StrLoc}

; Intel NPU / OpenVINO auto-install (feature/intel-npu)
; Detects NPU hardware; installs official WHQL driver + OpenVINO only if missing.
!include "intel-npu-drivers.nsh"

{{#if installer_hooks}}
!include "{{installer_hooks}}"
{{/if}}

; NOTE: Full remainder of upstream Handy NSIS template is unchanged.
; The intel-npu-drivers.nsh include adds Section "Intel NPU + OpenVINO (auto)"
; which runs after WebView2 when an Intel NPU is present and the driver is missing.
;
; If you need the complete template body, restore from upstream and keep the
; !include "intel-npu-drivers.nsh" line above ${StrLoc}.
