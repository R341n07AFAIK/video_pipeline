; Inno Setup Script for Video Pipeline
; Save as video_pipeline_installer.iss and compile with Inno Setup (ISCC.exe)

[Setup]
AppName=Video Pipeline
AppVersion=1.0.0
DefaultDirName={pf}\VideoPipeline
DefaultGroupName=Video Pipeline
Compression=lzma
SolidCompression=yes
OutputBaseFilename=VideoPipeline_Installer
CompressionThreads=2

[Files]
; Include all files from distribution folder except logs, temp, input, output, large media
Source: "*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs; Excludes: "logs\*;temp\*;input\*;output\*;*.mp4;*.mkv;*.zip"

[Icons]
Name: "{group}\Video Pipeline"; Filename: "{app}\pipeline-gui.exe"; WorkingDir: "{app}"
Name: "{group}\Uninstall Video Pipeline"; Filename: "{uninstallexe}"; WorkingDir: "{app}"

[Run]
; Option A: Run compiled bootstrap EXE (if you compiled installer.ps1 to EXE)
; Filename: "{app}\video_pipeline_installer_bootstrap.exe"; Description: "Run installer"; Flags: nowait postinstall skipifsilent

; Option B: Run PowerShell bootstrap directly (requires ExecutionPolicy Bypass)
Filename: "powershell.exe"; Parameters: "-ExecutionPolicy Bypass -NoProfile -File \"{app}\\installer.ps1\""; Flags: runhidden

[UninstallDelete]
Type: filesandordirs; Name: "{app}"

; Notes:
; - To build: install Inno Setup (https://jrsoftware.org/isinfo.php) and run:
;     ISCC.exe video_pipeline_installer.iss
; - For a nicer UX, compile installer.ps1 to an EXE (ps2exe) and use Option A in the [Run] section.
