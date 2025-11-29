# pipeline-gui.ps1
# Video Pipeline GUI using Windows Forms
# Provides interactive interface for video processing

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Video Pipeline - GUI Controller"
$form.Size = New-Object System.Drawing.Size(900, 750)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 240)

# Title Panel
$titlePanel = New-Object System.Windows.Forms.Panel
$titlePanel.Dock = "Top"
$titlePanel.Height = 70
$titlePanel.BackColor = [System.Drawing.Color]::FromArgb(33, 33, 33)

$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "Video Processing Pipeline"
$titleLabel.Font = New-Object System.Drawing.Font("Arial", 16, [System.Drawing.FontStyle]::Bold)
$titleLabel.ForeColor = [System.Drawing.Color]::White
$titleLabel.AutoSize = $false
$titleLabel.Dock = "Fill"

# Main Container (fills form directly; banner removed)
$inputLabel = New-Object System.Windows.Forms.Label
$inputLabel.Text = "Input Folder:"
$inputLabel.Location = New-Object System.Drawing.Point(15, 15)
$inputLabel.Size = New-Object System.Drawing.Size(100, 20)

$inputBox = New-Object System.Windows.Forms.TextBox
$inputBox.Location = New-Object System.Drawing.Point(135, 15)
$inputBox.Size = New-Object System.Drawing.Size(580, 25)
$inputBox.ReadOnly = $true

$inputButton = New-Object System.Windows.Forms.Button
$inputButton.Text = "Browse..."
$inputButton.Location = New-Object System.Drawing.Point(725, 15)
$inputButton.Size = New-Object System.Drawing.Size(80, 25)
$inputButton.Add_Click({
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = "Select Input Folder"
    $dialog.RootFolder = [System.Environment+SpecialFolder]::MyComputer
    if ($dialog.ShowDialog() -eq "OK") {
        $inputBox.Text = $dialog.SelectedPath
    }
})

# Output Folder
$outputLabel = New-Object System.Windows.Forms.Label
$outputLabel.Text = "Output Folder:"
# Video Pipeline GUI using Windows Forms
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Video Pipeline - GUI Controller"
$form.Size = New-Object System.Drawing.Size(900, 700)
$form.StartPosition = 'CenterScreen'
$form.BackColor = [System.Drawing.Color]::FromArgb(240,240,240)

# Tab control fills the form
$mainContainer = New-Object System.Windows.Forms.TabControl
$mainContainer.Dock = 'Fill'

# --- Tab 1: Process Video ---
$tab1 = New-Object System.Windows.Forms.TabPage('Process Video')
$tab1.Padding = New-Object System.Windows.Forms.Padding(12)

# Input Folder
$inputLabel = New-Object System.Windows.Forms.Label
$inputLabel.Text = 'Input Folder:'
$inputLabel.Location = New-Object System.Drawing.Point(12,12)
$inputLabel.Size = New-Object System.Drawing.Size(100,20)

$inputBox = New-Object System.Windows.Forms.TextBox
$inputBox.Location = New-Object System.Drawing.Point(120,12)
$inputBox.Size = New-Object System.Drawing.Size(580,24)
$inputBox.ReadOnly = $true

$inputButton = New-Object System.Windows.Forms.Button
$inputButton.Text = 'Browse...'
$inputButton.Location = New-Object System.Drawing.Point(710,12)
$inputButton.Size = New-Object System.Drawing.Size(80,24)
$inputButton.Add_Click({
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    $dlg.Description = 'Select input folder'
    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $inputBox.Text = $dlg.SelectedPath
    }
})

# Output Folder
$outputLabel = New-Object System.Windows.Forms.Label
$outputLabel.Text = 'Output Folder:'
$outputLabel.Location = New-Object System.Drawing.Point(12,46)
$outputLabel.Size = New-Object System.Drawing.Size(100,20)

$outputBox = New-Object System.Windows.Forms.TextBox
$outputBox.Location = New-Object System.Drawing.Point(120,46)
$outputBox.Size = New-Object System.Drawing.Size(580,24)
$outputBox.ReadOnly = $true

$outputButton = New-Object System.Windows.Forms.Button
$outputButton.Text = 'Browse...'
$outputButton.Location = New-Object System.Drawing.Point(710,46)
$outputButton.Size = New-Object System.Drawing.Size(80,24)
$outputButton.Add_Click({
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    $dlg.Description = 'Select output folder'
    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $outputBox.Text = $dlg.SelectedPath
    }
})

# Provider
$providerLabel = New-Object System.Windows.Forms.Label
$providerLabel.Text = 'AI Provider:'
$providerLabel.Location = New-Object System.Drawing.Point(12,82)
$providerLabel.Size = New-Object System.Drawing.Size(100,20)

$providerCombo = New-Object System.Windows.Forms.ComboBox
$providerCombo.Location = New-Object System.Drawing.Point(120,82)
$providerCombo.Size = New-Object System.Drawing.Size(200,24)
$providerCombo.Items.AddRange(@('grok','midjourney','comfyui','none'))
$providerCombo.SelectedIndex = 0

# FPS
$fpsLabel = New-Object System.Windows.Forms.Label
$fpsLabel.Text = 'FPS:'
$fpsLabel.Location = New-Object System.Drawing.Point(340,82)
$fpsLabel.Size = New-Object System.Drawing.Size(40,20)

$fpsSpinner = New-Object System.Windows.Forms.NumericUpDown
$fpsSpinner.Location = New-Object System.Drawing.Point(380,82)
$fpsSpinner.Size = New-Object System.Drawing.Size(80,24)
$fpsSpinner.Minimum = 12
$fpsSpinner.Maximum = 120
$fpsSpinner.Value = 24

# Codec
$codecLabel = New-Object System.Windows.Forms.Label
$codecLabel.Text = 'Codec:'
$codecLabel.Location = New-Object System.Drawing.Point(480,82)
$codecLabel.Size = New-Object System.Drawing.Size(50,20)

$codecCombo = New-Object System.Windows.Forms.ComboBox
$codecCombo.Location = New-Object System.Drawing.Point(530,82)
$codecCombo.Size = New-Object System.Drawing.Size(170,24)
$codecCombo.Items.AddRange(@('libx264','libx265','libvpx'))
$codecCombo.SelectedIndex = 0

# Log box
$logLabel = New-Object System.Windows.Forms.Label
$logLabel.Text = 'Processing Log:'
$logLabel.Location = New-Object System.Drawing.Point(12,116)
$logLabel.Size = New-Object System.Drawing.Size(120,20)

$logBox = New-Object System.Windows.Forms.RichTextBox
$logBox.Location = New-Object System.Drawing.Point(12,140)
$logBox.Size = New-Object System.Drawing.Size(780,360)
$logBox.ReadOnly = $true
$logBox.BackColor = [System.Drawing.Color]::Black
$logBox.ForeColor = [System.Drawing.Color]::LimeGreen

# Process button
$processButton = New-Object System.Windows.Forms.Button
$processButton.Text = 'Process Video'
$processButton.Location = New-Object System.Drawing.Point(12,510)
$processButton.Size = New-Object System.Drawing.Size(140,34)
$processButton.BackColor = [System.Drawing.Color]::Green
$processButton.ForeColor = [System.Drawing.Color]::White
$processButton.Font = New-Object System.Drawing.Font('Arial',10,[System.Drawing.FontStyle]::Bold)
$processButton.Add_Click({
    if ([string]::IsNullOrWhiteSpace($inputBox.Text)) { [System.Windows.Forms.MessageBox]::Show('Please select an input folder','Error'); return }
    if ([string]::IsNullOrWhiteSpace($outputBox.Text)) { [System.Windows.Forms.MessageBox]::Show('Please select an output folder','Error'); return }
    $logBox.AppendText("Starting processing...`n")
    $logBox.AppendText("Input: $($inputBox.Text)`n")
    $logBox.AppendText("Output: $($outputBox.Text)`n")
    $logBox.AppendText("Provider: $($providerCombo.SelectedItem)`n")
    $logBox.AppendText("FPS: $($fpsSpinner.Value)`n")
    $logBox.AppendText("Codec: $($codecCombo.SelectedItem)`n")
})

# Add controls to tab1
$tab1.Controls.AddRange(@($inputLabel,$inputBox,$inputButton,$outputLabel,$outputBox,$outputButton,$providerLabel,$providerCombo,$fpsLabel,$fpsSpinner,$codecLabel,$codecCombo,$logLabel,$logBox,$processButton))

# --- Tab 2: Batch Processing ---
$tab2 = New-Object System.Windows.Forms.TabPage('Batch Processing')
$tab2.Padding = New-Object System.Windows.Forms.Padding(12)

$batchLabel = New-Object System.Windows.Forms.Label
$batchLabel.Text = 'Batch Input Folder:'
$batchLabel.Location = New-Object System.Drawing.Point(12,12)
$batchLabel.Size = New-Object System.Drawing.Size(120,20)

$batchBox = New-Object System.Windows.Forms.TextBox
$batchBox.Location = New-Object System.Drawing.Point(140,12)
$batchBox.Size = New-Object System.Drawing.Size(550,24)
$batchBox.ReadOnly = $true

$batchButton = New-Object System.Windows.Forms.Button
$batchButton.Text = 'Browse...'
$batchButton.Location = New-Object System.Drawing.Point(700,12)
$batchButton.Size = New-Object System.Drawing.Size(80,24)
$batchButton.Add_Click({
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { $batchBox.Text = $dlg.SelectedPath }
})

$batchOutputLabel = New-Object System.Windows.Forms.Label
$batchOutputLabel.Text = 'Batch Output Folder:'
$batchOutputLabel.Location = New-Object System.Drawing.Point(12,46)
$batchOutputLabel.Size = New-Object System.Drawing.Size(120,20)

$batchOutputBox = New-Object System.Windows.Forms.TextBox
$batchOutputBox.Location = New-Object System.Drawing.Point(140,46)
$batchOutputBox.Size = New-Object System.Drawing.Size(550,24)
$batchOutputBox.ReadOnly = $true

$batchOutputButton = New-Object System.Windows.Forms.Button
$batchOutputButton.Text = 'Browse...'
$batchOutputButton.Location = New-Object System.Drawing.Point(700,46)
$batchOutputButton.Size = New-Object System.Drawing.Size(80,24)
$batchOutputButton.Add_Click({
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { $batchOutputBox.Text = $dlg.SelectedPath }
})

$batchLogBox = New-Object System.Windows.Forms.RichTextBox
$batchLogBox.Location = New-Object System.Drawing.Point(12,90)
$batchLogBox.Size = New-Object System.Drawing.Size(780,360)
$batchLogBox.ReadOnly = $true
$batchLogBox.BackColor = [System.Drawing.Color]::Black
$batchLogBox.ForeColor = [System.Drawing.Color]::LimeGreen

$batchStart = New-Object System.Windows.Forms.Button
$batchStart.Text = 'Start Batch'
$batchStart.Location = New-Object System.Drawing.Point(12,460)
$batchStart.Size = New-Object System.Drawing.Size(140,34)
$batchStart.BackColor = [System.Drawing.Color]::Green
$batchStart.ForeColor = [System.Drawing.Color]::White
$batchStart.Add_Click({ if ([string]::IsNullOrWhiteSpace($batchBox.Text)) { [System.Windows.Forms.MessageBox]::Show('Please select a batch input folder','Error'); return } $batchLogBox.AppendText("Starting batch from: $($batchBox.Text)`n") })

$tab2.Controls.AddRange(@($batchLabel,$batchBox,$batchButton,$batchOutputLabel,$batchOutputBox,$batchOutputButton,$batchLogBox,$batchStart))

# --- Tab 3: Settings ---
$tab3 = New-Object System.Windows.Forms.TabPage('Settings')
$tab3.Padding = New-Object System.Windows.Forms.Padding(12)

$apiKeyLabel = New-Object System.Windows.Forms.Label
$apiKeyLabel.Text = 'Grok API Key:'
$apiKeyLabel.Location = New-Object System.Drawing.Point(12,12)
$apiKeyLabel.Size = New-Object System.Drawing.Size(120,20)

$apiKeyBox = New-Object System.Windows.Forms.TextBox
$apiKeyBox.Location = New-Object System.Drawing.Point(140,12)
$apiKeyBox.Size = New-Object System.Drawing.Size(540,24)
$apiKeyBox.PasswordChar = '*'

$midLabel = New-Object System.Windows.Forms.Label
$midLabel.Text = 'Midjourney Key:'
$midLabel.Location = New-Object System.Drawing.Point(12,46)
$midLabel.Size = New-Object System.Drawing.Size(120,20)

$midBox = New-Object System.Windows.Forms.TextBox
$midBox.Location = New-Object System.Drawing.Point(140,46)
$midBox.Size = New-Object System.Drawing.Size(540,24)
$midBox.PasswordChar = '*'

$saveBtn = New-Object System.Windows.Forms.Button
$saveBtn.Text = 'Save Settings'
$saveBtn.Location = New-Object System.Drawing.Point(12,86)
$saveBtn.Size = New-Object System.Drawing.Size(140,34)
$saveBtn.Add_Click({ if ($apiKeyBox.Text) { [Environment]::SetEnvironmentVariable('XAI_API_KEY',$apiKeyBox.Text,'User') } if ($midBox.Text) { [Environment]::SetEnvironmentVariable('MIDJOURNEY_API_KEY',$midBox.Text,'User') } [System.Windows.Forms.MessageBox]::Show('Settings saved','Success') })

$tab3.Controls.AddRange(@($apiKeyLabel,$apiKeyBox,$midLabel,$midBox,$saveBtn))

# Add tabs to container and show form
$mainContainer.TabPages.Add($tab1)
$mainContainer.TabPages.Add($tab2)
$mainContainer.TabPages.Add($tab3)

$form.Controls.Add($mainContainer)
$form.ShowDialog() | Out-Null
    if ($apiKeyBox.Text) {
