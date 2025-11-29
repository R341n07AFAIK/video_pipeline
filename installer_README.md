Installer settings and file I/O

This document describes the configuration options used by `installer.ps1` and the expected file input/output layout for building and packaging the installer.

1) Purpose
- The installer copies the distribution files to the target `installDir` (default: `%ProgramFiles%\VideoPipeline`).
- It creates Start Menu shortcuts and registers an uninstall entry.
- Excludes logs, temp, input/output media and large files by default.

2) Key settings (see `installer_settings.json`)
- `appName`: Friendly application name.
- `version`: Installer/application version.
- `installDir`: Installation target directory.
- `installScope`: `machine` or `user` (determines HKLM vs HKCU install location registry entries).
- `includePatterns`: glob patterns of files to include (default `**/*`).
- `excludePatterns`: glob patterns to exclude (logs, temp, media files).
- `createStartMenuShortcuts`: create Start Menu shortcuts (true/false).
- `createDesktopShortcut`: create a desktop shortcut (true/false).
- `launchOnComplete`: whether to launch the main GUI after install.
- `registerUninstall`: register an uninstall entry in registry.
- `prerequisites`: required system components and min versions (ffmpeg, python).
- `postInstallScripts`: scripts to run after copy (e.g., `setup-environment.ps1`).
- `preInstallCheckScript`: optional custom script path to run before install.
- `logPath`: relative path under install dir where installer writes logs.
- `shortcutIcon`: path to an icon used by created shortcuts.
- `fileMappings`: source/destination mapping rules for packaging.

3) File Input & Output
- Input (source) location: the directory where the installer bundle or source files are located. The installer reads from `$PSCommandPath` parent directory.
- Output (target) location: the `installDir` (default `%ProgramFiles%\\VideoPipeline`).
- Files excluded by default: `logs/**`, `temp/**`, `input/**`, `output/**`, `**/*.mp4`, `**/*.mkv`, `**/*.zip`.
- Shortcuts: created under `%ProgramData%\\Microsoft\\Windows\\Start Menu\\Programs\\Video Pipeline` (for machine installs). Desktop shortcut optional.
- Registry uninstall key: `HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\VideoPipeline` for machine installs (use HKCU for per-user).
- Logs: written under `<installDir>\\logs`.

4) Packaging with Inno Setup
- Use `video_pipeline_installer.iss` to package the folder contents and run the bootstrap.
- The Inno `Excludes` are aligned to the `excludePatterns` in `installer_settings.json`.

5) Recommended build steps
- Edit `installer_settings.json` to set `installDir`, `appName`, `version` and pattern choices.
- (Optional) Compile `pipeline-gui.ps1` to `pipeline-gui.exe` with `ps2exe` and place it in distribution folder.
- (Optional) Compile `installer.ps1` to EXE and include it in the distribution.
- Run Inno Setup `ISCC.exe video_pipeline_installer.iss` to produce final `VideoPipeline_Installer.exe`.

6) Notes on permissions and safety
- Writing to `%ProgramFiles%` and `HKLM` requires elevation. The bootstrap self-elevates.
- Keep API keys out of the distribution bundle. Use `setup-environment.ps1` to prompt for keys at first run.
- If distributing across many machines, code-sign the installer and compiled EXEs to avoid SmartScreen warnings.

7) Example commands
```powershell
# Compile the bootstrap to EXE (optional)
Invoke-ps2exe .\installer.ps1 .\video_pipeline_installer_bootstrap.exe -noConsole -title "Video Pipeline Installer"

# Build Inno Setup installer (after installing Inno)
& 'C:\Program Files (x86)\Inno Setup 6\ISCC.exe' .\video_pipeline_installer.iss
```

If you want, I can:
- Update the Inno script to pull values from `installer_settings.json` (generate a templated ISS),
- Add a validation function in `installer.ps1` that checks `prerequisites` min versions,
- Create a small `packager.ps1` helper that prepares a clean distribution folder following `includePatterns`/`excludePatterns` and then runs Inno.
