# Quick Reference: PowerShell to EXE Conversion Methods

## Summary for Decision Making

### When to Use What

```
DECISION TREE:

Is this for commercial product distribution?
├─ YES → Use Advanced Installer
│        (Professional, support, auto-update, MSIX)
│
└─ NO → How quickly do you need it?
        ├─ RIGHT NOW → Use Batch Wrapper
        │              (Edit .bat file, run immediately)
        │
        └─ CAN WAIT → How many features needed?
                      ├─ LOTS → Use Advanced Installer
                      │         (Professional results)
                      │
                      └─ BASIC → Use PS2EXE
                                 (Simple, single command, free)
```

---

## Installation Quick Start

### Option 1: PS2EXE (15 minutes to working installer)

**Install:**
```powershell
Install-Module ps2exe -Scope CurrentUser
```

**Use:**
```powershell
ps2exe -inputFile "install.ps1" `
  -outputFile "install.exe" `
  -requireAdmin `
  -version "1.0.0.0"
```

**Result:** Single .EXE file ready to distribute

---

### Option 2: Batch Wrapper (5 minutes, no installation)

**Create:** `launcher.bat` (copy code from Approach2 file)

**Run:** `launcher.bat` directly (no compilation)

**Result:** Single .BAT file ready to distribute

---

### Option 3: Advanced Installer (1-2 hours to professional result)

**Install:** Download 30-day trial from advancedinstaller.com

**Process:**
1. Open Advanced Installer
2. New Project → MSI
3. Drag files into installer
4. Configure system requirements in UI
5. Build → Build Solution
6. Result: Professional .MSI file

---

## Feature Comparison Quick Table

| Need | Solution | Effort | Cost | Quality |
|------|----------|--------|------|---------|
| Quick internal tool | PS2EXE | Low | Free | Medium |
| Deploy now | Batch | Minimal | Free | Low |
| Professional product | Adv Installer | Medium | $299 | High |
| Maximum compatibility | Batch | Minimal | Free | Low |
| Enterprise deployment | Adv Installer | Medium | $299 | High |
| Prototype/test | PS2EXE | Low | Free | Medium |

---

## Code Template Selection

### Template 1: PS2EXE Installer
**File:** `Approach1_PS2EXE_Installer.ps1`
- Full system requirement checking
- Registry management
- Shortcuts creation
- Uninstall script generation
- Logging

**How to use:**
```powershell
# Run the template directly in PS5.1
. .\Approach1_PS2EXE_Installer.ps1

# Then compile to EXE
ps2exe -inputFile "Approach1_PS2EXE_Installer.ps1" `
  -outputFile "MyApp-Installer.exe" -requireAdmin
```

---

### Template 2: Batch Wrapper Installer
**File:** `Approach2_Batch_Wrapper.bat`
- Elevation handling
- System requirement checking
- Embedded PowerShell integration
- Logging
- No compilation needed

**How to use:**
```powershell
# Just run it directly:
# launcher.bat

# Or customize it with your details and run
```

---

### Template 3: Advanced Installer Guide
**File:** `Approach3_Advanced_Installer_Guide.txt`
- Step-by-step GUI instructions
- System requirements configuration
- Custom action examples
- Professional workflow

**How to use:**
1. Follow the steps in the guide
2. Use the GUI-based builder
3. Import your PowerShell script as custom action
4. Build the MSI installer

---

## Common Requirements & Solutions

### Requirement: System Requirements Check

**PS2EXE Method:**
```powershell
function Test-SystemRequirements {
    if ([Environment]::OSVersion.Version.Major -lt 10) {
        Write-Error "Windows 10+ required"
        return $false
    }
    
    $ramGB = [math]::Round((Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
    if ($ramGB -lt 4) {
        Write-Error "4GB RAM required"
        return $false
    }
    
    return $true
}
```

**Batch Method:**
See Approach2_Batch_Wrapper.bat (integrated)

**Advanced Installer:**
Use GUI → System Requirements section

---

### Requirement: Elevated Execution

**PS2EXE:**
```powershell
ps2exe ... -requireAdmin  # Flag at compile time
```

**Batch:**
```batch
@echo off
openfiles >nul 2>&1
if errorlevel 1 (
    powershell -Command "Start-Process cmd.exe -Verb RunAs"
    exit /b
)
```

**Advanced Installer:**
GUI → Security → Run As Administrator

---

### Requirement: Custom Actions

**PS2EXE:**
All code is your PowerShell script directly

**Batch:**
Embed PowerShell after the batch section

**Advanced Installer:**
Custom Actions → New Custom Action (PowerShell)

---

### Requirement: File Embedding

**PS2EXE:**
```powershell
ps2exe -inputFile "script.ps1" `
  -outputFile "app.exe" `
  -embedFiles @{
    'C:\install\config.txt' = 'local_config.txt'
    'C:\install\data.json'  = 'template_data.json'
  }
```

**Batch:**
Include files in same folder with launcher

**Advanced Installer:**
Add files directly in UI

---

### Requirement: Uninstall Capability

**PS2EXE:**
Create uninstall script programmatically (see template)

**Batch:**
Same approach - create uninstall.ps1 file

**Advanced Installer:**
Automatic - Control Panel → Programs & Features

---

## Execution Commands

### PS2EXE Compilation Examples

```powershell
# Basic compilation
ps2exe -inputFile "script.ps1" -outputFile "app.exe"

# With metadata
ps2exe -inputFile "script.ps1" `
  -outputFile "MyApp.exe" `
  -title "My Application" `
  -version "1.0.0.0" `
  -company "MyCompany" `
  -copyright "(c) 2025" `
  -product "MyApp"

# With admin and icon
ps2exe -inputFile "script.ps1" `
  -outputFile "app.exe" `
  -requireAdmin `
  -iconFile "app.ico" `
  -x64

# With embedded files
ps2exe -inputFile "script.ps1" `
  -outputFile "app.exe" `
  -embedFiles @{'.\config.xml' = 'default_config.xml'} `
  -requireAdmin

# GUI application (no console)
ps2exe -inputFile "gui.ps1" `
  -outputFile "gui.exe" `
  -noConsole `
  -DPIAware
```

---

## Testing Checklist

### Before Distributing Your Installer

- [ ] Test on Windows 10
- [ ] Test on Windows 11
- [ ] Test with admin privileges required
- [ ] Test without admin privileges (should prompt)
- [ ] Test system requirement checks work
- [ ] Test installation creates all files/shortcuts
- [ ] Test registry entries created correctly
- [ ] Test uninstall removes all files
- [ ] Test registry cleanup
- [ ] Test shortcut functionality
- [ ] Test with antivirus enabled
- [ ] Test file permissions are correct
- [ ] Test on minimal system specs
- [ ] Document any prerequisites
- [ ] Verify no sensitive data in code
- [ ] Sign executable (if distribution)

---

## Security Checklist

- [ ] No hardcoded passwords in code
- [ ] No API keys in source
- [ ] Input validation on all parameters
- [ ] Error messages don't expose system paths
- [ ] Installer runs elevated only when needed
- [ ] Registry modifications are secure
- [ ] File permissions are restrictive
- [ ] Code is signed with certificate
- [ ] Tested for code injection vulnerabilities
- [ ] No script extractable (if using PS2EXE, document risk)

---

## File Organization

```
MyApp-Setup/
├── Approach1_PS2EXE_Installer.ps1      (← Template for simple solutions)
├── Approach2_Batch_Wrapper.bat          (← Template for immediate needs)
├── Approach3_Advanced_Installer_Guide.txt (← Guide for professional solutions)
├── icon.ico                             (Optional - for branding)
├── app.ps1                              (Your main application)
└── config.xml                           (Optional - config template)
```

---

## Deployment Scenarios

### Scenario 1: Internal IT Tool
**Best Approach:** PS2EXE or Batch
**Steps:**
1. Write PowerShell script
2. Compile with PS2EXE or wrap with Batch
3. Test on target systems
4. Distribute via email/network share
5. Users run locally

**Time to Deploy:** 1-2 hours

---

### Scenario 2: Small Business Application
**Best Approach:** PS2EXE + GUI
**Steps:**
1. Write PowerShell GUI application
2. Compile with PS2EXE -noConsole
3. Package with installer batch script
4. Host on company website
5. Direct users to download

**Time to Deploy:** 2-4 hours

---

### Scenario 3: Commercial Product
**Best Approach:** Advanced Installer
**Steps:**
1. Create project in Advanced Installer
2. Add application files
3. Configure system requirements
4. Add custom actions for setup
5. Code sign the MSI
6. Distribute through store/website
7. Set up auto-update system

**Time to Deploy:** 4-8 hours

---

### Scenario 4: Enterprise Deployment
**Best Approach:** Advanced Installer + Group Policy
**Steps:**
1. Create MSI installer
2. Deploy via WSUS/Intune
3. Track deployment status
4. Automatic updates
5. Centralized management
6. Audit trail

**Time to Setup:** 1-2 days

---

## Resource Requirements

| Method | Disk Space | Memory | Skills | Time |
|--------|-----------|--------|--------|------|
| PS2EXE | ~500MB (PowerShell gallery) | 512MB | Basic PS | 30 min |
| Batch | None | 256MB | Basic Batch | 10 min |
| Adv Installer | 150MB | 1GB | Medium | 1-2 hours |
| WiX MSI | 8GB (VS Build Tools) | 2GB | Advanced | 4+ hours |

---

## Support Resources

### PS2EXE
- GitHub: https://github.com/MScholtes/PS2EXE
- PowerShell Gallery: https://www.powershellgallery.com/packages/ps2exe/
- Documentation: Included in module

### Advanced Installer
- Website: https://www.advancedinstaller.com
- Support: https://www.advancedinstaller.com/support.html
- Documentation: https://www.advancedinstaller.com/user-guide/

### Batch & PowerShell
- Microsoft Docs: https://learn.microsoft.com/en-us/powershell/
- Stack Overflow: [powershell] tag
- TechNet: https://technet.microsoft.com

---

## Final Decision Matrix

```
Need                          Solution             Difficulty    Cost
────────────────────────────────────────────────────────────────────
Quick internal tool           PS2EXE + Batch       ✓ Easy        Free
Professional installer        Advanced Installer   Medium         $299
Enterprise deployment         Advanced Installer   Medium         $299
Maximum compatibility         Batch wrapper        ✓ Very Easy    Free
Commercial software           Advanced Installer   Medium         $299
Legacy system support         Batch wrapper        ✓ Very Easy    Free
Prototype/testing             PS2EXE               ✓ Easy         Free
Windows Service               Advanced Installer   ✓ Medium       $299
────────────────────────────────────────────────────────────────────
```

---

## Next Steps

1. **Read** `PowerShell_to_EXE_Research.md` for complete information
2. **Choose** approach based on your needs (use decision tree above)
3. **Copy** template from Approach1, 2, or 3 files
4. **Customize** with your application details
5. **Test** on target systems using testing checklist
6. **Deploy** with appropriate distribution method

---

**Last Updated:** November 2025
**PS2EXE Version:** 1.0.17 (Latest)
**Compatible:** Windows 10, Windows 11, Windows Server 2019+
