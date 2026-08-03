; =============================================================================
; intel-npu-drivers.nsh
; Auto-detect Intel NPU hardware and install official (WHQL / Microsoft-accepted)
; Intel NPU driver + OpenVINO Runtime when the driver is missing.
;
; Policy:
;   - Only runs when an Intel NPU is detected on the machine.
;   - Only installs when the NPU driver is not already present.
;   - Uses official Intel packages (WHQL-signed) accepted by Microsoft.
;   - Prefers silent install; falls back to interactive if silent fails.
;   - Does NOT force a reboot (user can reboot later).
;
; Linux: see docs/intel-npu/DRIVERS.md for official packages / kernel modules.
; =============================================================================

!ifndef INTEL_NPU_DRIVERS_INCLUDED
!define INTEL_NPU_DRIVERS_INCLUDED

; Official download URLs (update when Intel releases newer builds)
; NPU driver page: https://www.intel.com/content/www/us/en/download/794734/intel-npu-driver-windows.html
!define INTEL_NPU_DRIVER_URL "https://downloadmirror.intel.com/859199/npu_win_32.0.100.4841.exe"
!define INTEL_NPU_DRIVER_LOCAL "$TEMP\Handy_Intel_NPU_Driver.exe"

; OpenVINO Runtime archive (Windows x86_64)
!define OPENVINO_ARCHIVE_URL "https://storage.openvinotoolkit.org/repositories/openvino/packages/2026.2.1/windows/openvino_toolkit_windows_2026.2.1.21919.ede283a88e3_x86_64.zip"
!define OPENVINO_ARCHIVE_LOCAL "$TEMP\Handy_OpenVINO_Runtime.zip"
!define OPENVINO_INSTALL_DIR "$PROGRAMFILES64\Intel\openvino_handy"

Var IntelNpuPresent
Var IntelNpuDriverInstalled
Var OpenVinoPresent

Function DetectIntelNpu
  StrCpy $IntelNpuPresent 0
  nsExec::ExecToStack 'powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$$d = Get-PnpDevice -ErrorAction SilentlyContinue | Where-Object { $$_.FriendlyName -match ''AI Boost|Neural Processing|NPU'' -or $$_.Class -match ''Neural|ComputeAccelerator'' }; if ($$d) { exit 0 } else { exit 1 }"'
  Pop $0
  Pop $1
  ${If} $0 = 0
    StrCpy $IntelNpuPresent 1
    DetailPrint "Intel NPU hardware detected."
    Return
  ${EndIf}
  EnumRegKey $0 HKLM "SYSTEM\CurrentControlSet\Control\Class\{f01a9d53-3ff6-48d2-9f97-c8a7004be10c}" 0
  ${If} $0 != ""
    StrCpy $IntelNpuPresent 1
    DetailPrint "Intel NPU hardware detected (registry class)."
    Return
  ${EndIf}
  DetailPrint "No Intel NPU hardware detected — skipping NPU driver install."
FunctionEnd

Function DetectIntelNpuDriver
  StrCpy $IntelNpuDriverInstalled 0
  nsExec::ExecToStack 'powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$$d = Get-PnpDevice -ErrorAction SilentlyContinue | Where-Object { ($$_.FriendlyName -match ''AI Boost|Neural Processing|NPU'') -and ($$_.Status -eq ''OK'') }; if ($$d) { exit 0 } else { exit 1 }"'
  Pop $0
  Pop $1
  ${If} $0 = 0
    StrCpy $IntelNpuDriverInstalled 1
    DetailPrint "Intel NPU driver already installed and healthy."
    Return
  ${EndIf}
  DetailPrint "Intel NPU driver not found or not healthy."
FunctionEnd

Function DetectOpenVino
  StrCpy $OpenVinoPresent 0
  ${If} ${FileExists} "$PROGRAMFILES64\Intel\openvino\runtime\bin\intel64\Release\openvino.dll"
  ${OrIf} ${FileExists} "$PROGRAMFILES64\Intel\openvino_2026.2.1\runtime\bin\intel64\Release\openvino.dll"
  ${OrIf} ${FileExists} "${OPENVINO_INSTALL_DIR}\runtime\bin\intel64\Release\openvino.dll"
  ${OrIf} ${FileExists} "$PROGRAMFILES\Intel\openvino\runtime\bin\intel64\Release\openvino.dll"
    StrCpy $OpenVinoPresent 1
    DetailPrint "OpenVINO Runtime already present."
    Return
  ${EndIf}
  nsExec::ExecToStack 'powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "if (Get-Command winget -ErrorAction SilentlyContinue) { $$r = winget list --id Intel.OpenVINOToolkit.2026.2.0 -e 2>$$null; if ($$LASTEXITCODE -eq 0) { exit 0 } }; exit 1"'
  Pop $0
  Pop $1
  ${If} $0 = 0
    StrCpy $OpenVinoPresent 1
    DetailPrint "OpenVINO Runtime found via winget."
    Return
  ${EndIf}
  DetailPrint "OpenVINO Runtime not detected."
FunctionEnd

Function InstallIntelNpuDriver
  DetailPrint "Downloading official Intel NPU driver (WHQL / Microsoft-accepted)..."
  Delete "${INTEL_NPU_DRIVER_LOCAL}"
  NSISdl::download "${INTEL_NPU_DRIVER_URL}" "${INTEL_NPU_DRIVER_LOCAL}"
  Pop $0
  ${If} $0 != "success"
    DetailPrint "Failed to download Intel NPU driver: $0"
    MessageBox MB_ICONEXCLAMATION|MB_OK "Could not download the Intel NPU driver.$\r$\n$\r$\nPlease install it manually from:$\r$\nhttps://www.intel.com/content/www/us/en/download/794734/intel-npu-driver-windows.html"
    Return
  ${EndIf}
  DetailPrint "Installing Intel NPU driver (may request elevation)..."
  ExecWait '"${INTEL_NPU_DRIVER_LOCAL}" -s' $1
  ${If} $1 <> 0
    DetailPrint "Silent install returned $1 — retrying with default UI..."
    ExecWait '"${INTEL_NPU_DRIVER_LOCAL}"' $1
  ${EndIf}
  ${If} $1 = 0
    DetailPrint "Intel NPU driver install finished successfully."
  ${Else}
    DetailPrint "Intel NPU driver install exited with code $1. You may need to finish installation manually or reboot."
  ${EndIf}
  Delete "${INTEL_NPU_DRIVER_LOCAL}"
FunctionEnd

Function InstallOpenVinoRuntime
  nsExec::ExecToStack 'powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "if (Get-Command winget -ErrorAction SilentlyContinue) { winget install --id Intel.OpenVINOToolkit.2026.2.0 -e --source winget --accept-package-agreements --accept-source-agreements; exit $$LASTEXITCODE } else { exit 2 }"'
  Pop $0
  Pop $1
  ${If} $0 = 0
    DetailPrint "OpenVINO Runtime installed via winget."
    StrCpy $OpenVinoPresent 1
    Return
  ${EndIf}
  DetailPrint "winget not available or package missing — downloading OpenVINO Runtime archive..."
  Delete "${OPENVINO_ARCHIVE_LOCAL}"
  NSISdl::download "${OPENVINO_ARCHIVE_URL}" "${OPENVINO_ARCHIVE_LOCAL}"
  Pop $0
  ${If} $0 != "success"
    DetailPrint "Failed to download OpenVINO Runtime: $0"
    MessageBox MB_ICONEXCLAMATION|MB_OK "Could not download OpenVINO Runtime.$\r$\n$\r$\nInstall manually:$\r$\nhttps://docs.openvino.ai/2026/get-started/install-openvino/install-openvino-windows.html"
    Return
  ${EndIf}
  DetailPrint "Extracting OpenVINO Runtime to ${OPENVINO_INSTALL_DIR}..."
  CreateDirectory "${OPENVINO_INSTALL_DIR}"
  nsExec::ExecToLog 'powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "Expand-Archive -Path ''${OPENVINO_ARCHIVE_LOCAL}'' -DestinationPath ''$TEMP\ov_extract'' -Force; $$src = Get-ChildItem ''$TEMP\ov_extract'' -Directory | Select-Object -First 1; if ($$src) { Copy-Item -Path (Join-Path $$src.FullName ''*'') -Destination ''${OPENVINO_INSTALL_DIR}'' -Recurse -Force }"'
  Pop $0
  ${If} $0 = 0
    DetailPrint "OpenVINO Runtime extracted."
    StrCpy $OpenVinoPresent 1
    WriteRegStr HKLM "Software\Handy\OpenVINO" "InstallDir" "${OPENVINO_INSTALL_DIR}"
  ${Else}
    DetailPrint "OpenVINO extraction failed (exit $0)."
  ${EndIf}
  Delete "${OPENVINO_ARCHIVE_LOCAL}"
FunctionEnd

Section "Intel NPU + OpenVINO (auto)" SecIntelNpu
  ${IfNot} ${RunningX64}
    DetailPrint "Skipping NPU driver logic on non-x64."
    Goto npu_done
  ${EndIf}
  Call DetectIntelNpu
  ${If} $IntelNpuPresent <> 1
    Goto npu_done
  ${EndIf}
  Call DetectIntelNpuDriver
  ${If} $IntelNpuDriverInstalled <> 1
    Call InstallIntelNpuDriver
  ${EndIf}
  Call DetectOpenVino
  ${If} $OpenVinoPresent <> 1
    Call InstallOpenVinoRuntime
  ${EndIf}
  npu_done:
SectionEnd

!endif
