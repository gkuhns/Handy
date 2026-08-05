; Custom NSIS template for Handy with portable mode support.
; Based on tauri-apps/tauri@tauri-v2.9.1 crates/tauri-bundler/src/bundle/windows/nsis/installer.nsi
; Portable changes are marked with "; --- PORTABLE MODE ---" comments.
;
; When upgrading Tauri, diff this file against the new upstream template and
; merge changes while preserving the portable sections.

Unicode true
ManifestDPIAware true
; Add in `dpiAwareness` `PerMonitorV2` to manifest for Windows 10 1607+ (note this should not affect lower versions since they should be able to ignore this and pick up `dpiAware` `true` set by `ManifestDPIAware true`)
; Currently undocumented on NSIS's website but is in the Docs folder of source tree, see
; https://github.com/kichik/nsis/blob/5fc0b87b819a9eec006df4967d08e522ddd651c9/Docs/src/attributes.but#L286-L300
; https://github.com/tauri-apps/tauri/pull/10106
ManifestDPIAwareness PerMonitorV2

!if "{{compression}}" == "none"
  SetCompress off
!else
  ; Set the compression algorithm. We default to LZMA.
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

; Intel NPU auto-driver support (feature/intel-npu)
; Path is relative to Tauri's NSIS workdir: target/release/nsis/x64/
!include "..\..\..\..\nsis\intel-npu-drivers.nsh"

{{#if installer_hooks}}
!include "{{installer_hooks}}"
{{/if}}

!define WEBVIEW2APPGUID "{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}"

!define MANUFACTURER "{{manufacturer}}"
!define PRODUCTNAME "{{product_name}}"
!define VERSION "{{version}}"
!define VERSIONWITHBUILD "{{version_with_build}}"
!define HOMEPAGE "{{homepage}}"
!define INSTALLMODE "{{install_mode}}"
!define LICENSE "{{license}}"
!define INSTALLERICON "{{installer_icon}}"
!define SIDEBARIMAGE "{{sidebar_image}}"
!define HEADERIMAGE "{{header_image}}"
!define MAINBINARYNAME "{{main_binary_name}}"
!define MAINBINARYSRCPATH "{{main_binary_path}}"
!define BUNDLEID "{{bundle_id}}"
!define COPYRIGHT "{{copyright}}"
!define OUTFILE "{{out_file}}"
!define ARCH "{{arch}}"
!define ADDITIONALFILES "{{additional_files}}"
!define ADDITIONALPLUGINSDIR "{{additional_plugins_dir}}"
!define RESOURCES "{{resources}}"
!define BINARIES "{{binaries}}"
!define NATIVE_LIBS "{{native_libs}}"
!define ALLOWDOWNGRADES "{{allow_downgrades}}"
!define DISPLAYLANGUAGESELECTOR "{{display_language_selector}}"
!define INSTALLWEBVIEW2MODE "{{install_webview2_mode}}"
!define WEBVIEW2INSTALLERARGS "{{webview2_installer_args}}"
!define WEBVIEW2BOOTSTRAPPERPATH "{{webview2_bootstrapper_path}}"
!define WEBVIEW2INSTALLERPATH "{{webview2_installer_path}}"
!define MINIMUMWEBVIEW2VERSION "{{minimum_webview2_version}}"
!define ADDITIONAL_PLUGIN_DIRS "{{additional_plugin_dirs}}"
!define UNINSTKEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCTNAME}"
!define MANUPRODUCTKEY "Software\${MANUFACTURER}\${PRODUCTNAME}"
!define UNINSTALLERSIGNCOMMAND "{{uninstaller_sign_command}}"
!define ESTIMATEDSIZE "{{estimated_size}}"

Var ReinstallMode
Var WixMode
Var PassiveMode
Var UpdateMode
Var NoShortcutMode
Var OldMainBinaryName

Name "${PRODUCTNAME}"
BrandingText "${COPYRIGHT}"
OutFile "${OUTFILE}"

VIProductVersion "${VERSIONWITHBUILD}"
VIAddVersionKey "ProductName" "${PRODUCTNAME}"
VIAddVersionKey "FileDescription" "${PRODUCTNAME}"
VIAddVersionKey "LegalCopyright" "${COPYRIGHT}"
VIAddVersionKey "FileVersion" "${VERSION}"
VIAddVersionKey "ProductVersion" "${VERSION}"

; Plugins
!addplugindir "${ADDITIONALPLUGINSDIR}"
!if "${ADDITIONAL_PLUGIN_DIRS}" != ""
  !addplugindir "${ADDITIONAL_PLUGIN_DIRS}"
!endif

; --- PORTABLE MODE ---
; Check for portable mode via command line or presence of portable.txt next to the installer
Var PortableMode
Var InstallDirRegKey

Function .onInit
  ; Default to non-portable
  StrCpy $PortableMode 0

  ; Check command line for /PORTABLE
  ${GetParameters} $R0
  ${GetOptions} $R0 "/PORTABLE" $R1
  IfErrors +2 0
    StrCpy $PortableMode 1

  ; Check for portable.txt next to the installer
  IfFileExists "$EXEDIR\portable.txt" 0 +2
    StrCpy $PortableMode 1

  ${If} $PortableMode == 1
    ; Portable: install next to the installer
    StrCpy $INSTDIR "$EXEDIR\${PRODUCTNAME}"
    SetShellVarContext current
  ${Else}
    ; Normal install logic (from upstream template)
    !insertmacro MUI_LANGDLL_DISPLAY

    ${If} ${RunningX64}
      SetRegView 64
    ${EndIf}

    ; Check if already installed
    ReadRegStr $R0 HKLM "${UNINSTKEY}" "UninstallString"
    ${If} $R0 != ""
      ; Already installed - handle reinstall/update
      StrCpy $ReinstallMode 1
    ${EndIf}
  ${EndIf}
FunctionEnd

; PLACEHOLDER - FULL CONTENT TO BE REPLACED IN NEXT CALL IF NEEDED
