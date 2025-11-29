# pipeline-gui.ps1
# Video Pipeline GUI using Windows Forms
# Provides interactive interface for video processing

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Video Pipeline - GUI Controller"
$form.Size = New-Object System.Drawing.Size(900, 700)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 240)

# Title Panel
$titlePanel = New-Object System.Windows.Forms.Panel
$titlePanel.Dock = "Top"
$titlePanel.Height = 60
$titlePanel.BackColor = [System.Drawing.Color]::FromArgb(33, 33, 33)

$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "Video Processing Pipeline"
$titleLabel.Font = New-Object System.Drawing.Font("Arial", 16, [System.Drawing.FontStyle]::Bold)
$titleLabel.ForeColor = [System.Drawing.Color]::White
$titleLabel.AutoSize = $false
$titleLabel.Dock = "Fill"
$titleLabel.TextAlign = "MiddleCenter"
$titlePanel.Controls.Add($titleLabel)

# Main Container
$mainContainer = New-Object System.Windows.Forms.TabControl
$mainContainer.Dock = "Fill"

# Tab 1: Process Video
$tab1 = New-Object System.Windows.Forms.TabPage
$tab1.Text = "Process Video"
$tab1.Padding = New-Object System.Windows.Forms.Padding(10)

# Input Folder Selection
$inputLabel = New-Object System.Windows.Forms.Label
$inputLabel.Text = "Input Video:"
$inputLabel.Location = New-Object System.Drawing.Point(10, 20)
$inputLabel.Size = New-Object System.Drawing.Size(100, 20)

$inputBox = New-Object System.Windows.Forms.TextBox
$inputBox.Location = New-Object System.Drawing.Point(120, 20)
$inputBox.Size = New-Object System.Drawing.Size(600, 25)

$inputButton = New-Object System.Windows.Forms.Button
$inputButton.Text = "Browse..."
$inputButton.Location = New-Object System.Drawing.Point(730, 20)
$inputButton.Size = New-Object System.Drawing.Size(80, 25)
$inputButton.Add_Click({
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Filter = "Video Files (*.mp4;*.mov;*.mkv)|*.mp4;*.mov;*.mkv"
    if ($dialog.ShowDialog() -eq "OK") {
        $inputBox.Text = $dialog.FileName
    }
})

# Output Folder
$outputLabel = New-Object System.Windows.Forms.Label
$outputLabel.Text = "Output Video:"
$outputLabel.Location = New-Object System.Drawing.Point(10, 60)
$outputLabel.Size = New-Object System.Drawing.Size(100, 20)

$outputBox = New-Object System.Windows.Forms.TextBox
$outputBox.Location = New-Object System.Drawing.Point(120, 60)
$outputBox.Size = New-Object System.Drawing.Size(600, 25)

$outputButton = New-Object System.Windows.Forms.Button
$outputButton.Text = "Browse..."
$outputButton.Location = New-Object System.Drawing.Point(730, 60)
$outputButton.Size = New-Object System.Drawing.Size(80, 25)
$outputButton.Add_Click({
    $dialog = New-Object System.Windows.Forms.SaveFileDialog
    $dialog.Filter = "MP4 Files (*.mp4)|*.mp4"
    $dialog.DefaultExt = "mp4"
    if ($dialog.ShowDialog() -eq "OK") {
        $outputBox.Text = $dialog.FileName
    }
})

# Provider Selection
$providerLabel = New-Object System.Windows.Forms.Label
$providerLabel.Text = "AI Provider:"
$providerLabel.Location = New-Object System.Drawing.Point(10, 100)
$providerLabel.Size = New-Object System.Drawing.Size(100, 20)

$providerCombo = New-Object System.Windows.Forms.ComboBox
$providerCombo.Location = New-Object System.Drawing.Point(120, 100)
$providerCombo.Size = New-Object System.Drawing.Size(200, 25)
$providerCombo.Items.AddRange(@("grok", "midjourney", "comfyui", "none"))
$providerCombo.SelectedIndex = 0

# FPS Setting
$fpsLabel = New-Object System.Windows.Forms.Label
$fpsLabel.Text = "FPS:"
$fpsLabel.Location = New-Object System.Drawing.Point(10, 140)
$fpsLabel.Size = New-Object System.Drawing.Size(100, 20)

$fpsSpinner = New-Object System.Windows.Forms.NumericUpDown
$fpsSpinner.Location = New-Object System.Drawing.Point(120, 140)
$fpsSpinner.Size = New-Object System.Drawing.Size(100, 25)
$fpsSpinner.Minimum = 12
$fpsSpinner.Maximum = 120
$fpsSpinner.Value = 24

# Codec Selection
$codecLabel = New-Object System.Windows.Forms.Label
$codecLabel.Text = "Codec:"
$codecLabel.Location = New-Object System.Drawing.Point(10, 180)
$codecLabel.Size = New-Object System.Drawing.Size(100, 20)

$codecCombo = New-Object System.Windows.Forms.ComboBox
$codecCombo.Location = New-Object System.Drawing.Point(120, 180)
$codecCombo.Size = New-Object System.Drawing.Size(200, 25)
$codecCombo.Items.AddRange(@("libx264", "libx265", "libvpx"))
$codecCombo.SelectedIndex = 0

# Log Display
$logLabel = New-Object System.Windows.Forms.Label
$logLabel.Text = "Processing Log:"
$logLabel.Location = New-Object System.Drawing.Point(10, 220)
$logLabel.Size = New-Object System.Drawing.Size(100, 20)

$logBox = New-Object System.Windows.Forms.RichTextBox
$logBox.Location = New-Object System.Drawing.Point(10, 250)
$logBox.Size = New-Object System.Drawing.Size(800, 200)
$logBox.ReadOnly = $true
$logBox.BackColor = [System.Drawing.Color]::Black
$logBox.ForeColor = [System.Drawing.Color]::LimeGreen

# Process Button
$processButton = New-Object System.Windows.Forms.Button
$processButton.Text = "Process Video"
$processButton.Location = New-Object System.Drawing.Point(10, 460)
$processButton.Size = New-Object System.Drawing.Size(150, 35)
$processButton.BackColor = [System.Drawing.Color]::Green
$processButton.ForeColor = [System.Drawing.Color]::White
$processButton.Font = New-Object System.Drawing.Font("Arial", 11, [System.Drawing.FontStyle]::Bold)
$processButton.Add_Click({
    if ([string]::IsNullOrWhiteSpace($inputBox.Text)) {
        [System.Windows.Forms.MessageBox]::Show("Please select an input video", "Error")
        return
    }
    
    $logBox.AppendText("Starting processing...`n")
    $logBox.AppendText("Input: $($inputBox.Text)`n")
    $logBox.AppendText("Output: $($outputBox.Text)`n")
    $logBox.AppendText("Provider: $($providerCombo.SelectedItem)`n")
    $logBox.AppendText("FPS: $($fpsSpinner.Value)`n`n")
    
    # Call extraction script
    try {
        $logBox.AppendText("Extracting frames...`n")
        & ".\extract_frames.ps1" -VideoPath $inputBox.Text -OutputFolder "temp_frames" -FPS $fpsSpinner.Value
        $logBox.AppendText("Frames extracted successfully`n`n")
        
        $logBox.AppendText("Stitching frames to video...`n")
        & ".\composite_video_from_images.ps1" -FramesFolder "temp_frames" -OutputVideo $outputBox.Text -FPS $fpsSpinner.Value
        $logBox.AppendText("Processing complete!`n")
        
        [System.Windows.Forms.MessageBox]::Show("Processing complete!", "Success")
    } catch {
        $logBox.AppendText("Error: $_`n")
        [System.Windows.Forms.MessageBox]::Show("Processing failed: $_", "Error")
    }
})

# Add controls to tab1
$tab1.Controls.AddRange(@($inputLabel, $inputBox, $inputButton, $outputLabel, $outputBox, $outputButton,
    $providerLabel, $providerCombo, $fpsLabel, $fpsSpinner, $codecLabel, $codecCombo,
    $logLabel, $logBox, $processButton))

# Tab 2: Batch Processing
$tab2 = New-Object System.Windows.Forms.TabPage
$tab2.Text = "Batch Process"
$tab2.Padding = New-Object System.Drawing.Padding(10)

$batchInputLabel = New-Object System.Windows.Forms.Label
$batchInputLabel.Text = "Input Folder:"
$batchInputLabel.Location = New-Object System.Drawing.Point(10, 20)
$batchInputLabel.Size = New-Object System.Drawing.Size(100, 20)

$batchInputBox = New-Object System.Windows.Forms.TextBox
$batchInputBox.Location = New-Object System.Drawing.Point(120, 20)
$batchInputBox.Size = New-Object System.Drawing.Size(600, 25)

$batchInputButton = New-Object System.Windows.Forms.Button
$batchInputButton.Text = "Browse..."
$batchInputButton.Location = New-Object System.Drawing.Point(730, 20)
$batchInputButton.Size = New-Object System.Drawing.Size(80, 25)
$batchInputButton.Add_Click({
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($dialog.ShowDialog() -eq "OK") {
        $batchInputBox.Text = $dialog.SelectedPath
    }
})

$batchOutputLabel = New-Object System.Windows.Forms.Label
$batchOutputLabel.Text = "Output Folder:"
$batchOutputLabel.Location = New-Object System.Drawing.Point(10, 60)
$batchOutputLabel.Size = New-Object System.Drawing.Size(100, 20)

$batchOutputBox = New-Object System.Windows.Forms.TextBox
$batchOutputBox.Location = New-Object System.Drawing.Point(120, 60)
$batchOutputBox.Size = New-Object System.Drawing.Size(600, 25)

$batchOutputButton = New-Object System.Windows.Forms.Button
$batchOutputButton.Text = "Browse..."
$batchOutputButton.Location = New-Object System.Drawing.Point(730, 60)
$batchOutputButton.Size = New-Object System.Drawing.Size(80, 25)
$batchOutputButton.Add_Click({
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($dialog.ShowDialog() -eq "OK") {
        $batchOutputBox.Text = $dialog.SelectedPath
    }
})

$batchProviderLabel = New-Object System.Windows.Forms.Label
$batchProviderLabel.Text = "AI Provider:"
$batchProviderLabel.Location = New-Object System.Drawing.Point(10, 100)
$batchProviderLabel.Size = New-Object System.Drawing.Size(100, 20)

$batchProviderCombo = New-Object System.Windows.Forms.ComboBox
$batchProviderCombo.Location = New-Object System.Drawing.Point(120, 100)
$batchProviderCombo.Size = New-Object System.Drawing.Size(200, 25)
$batchProviderCombo.Items.AddRange(@("grok", "midjourney", "comfyui"))
$batchProviderCombo.SelectedIndex = 0

$batchLogBox = New-Object System.Windows.Forms.RichTextBox
$batchLogBox.Location = New-Object System.Drawing.Point(10, 150)
$batchLogBox.Size = New-Object System.Drawing.Size(800, 300)
$batchLogBox.ReadOnly = $true
$batchLogBox.BackColor = [System.Drawing.Color]::Black
$batchLogBox.ForeColor = [System.Drawing.Color]::LimeGreen

$batchProcessButton = New-Object System.Windows.Forms.Button
$batchProcessButton.Text = "Process Batch"
$batchProcessButton.Location = New-Object System.Drawing.Point(10, 460)
$batchProcessButton.Size = New-Object System.Drawing.Size(150, 35)
$batchProcessButton.BackColor = [System.Drawing.Color]::Green
$batchProcessButton.ForeColor = [System.Drawing.Color]::White
$batchProcessButton.Font = New-Object System.Drawing.Font("Arial", 11, [System.Drawing.FontStyle]::Bold)
$batchProcessButton.Add_Click({
    if ([string]::IsNullOrWhiteSpace($batchInputBox.Text)) {
        [System.Windows.Forms.MessageBox]::Show("Please select input folder", "Error")
        return
    }
    
    $batchLogBox.AppendText("Starting batch processing...`n")
    $batchLogBox.AppendText("Input: $($batchInputBox.Text)`n")
    $batchLogBox.AppendText("Output: $($batchOutputBox.Text)`n`n")
    
    try {
        & ".\orchestrator.ps1" -InputFolder $batchInputBox.Text -OutputFolder $batchOutputBox.Text -Providers @($batchProviderCombo.SelectedItem)
        $batchLogBox.AppendText("Batch processing complete!`n")
        [System.Windows.Forms.MessageBox]::Show("Batch processing complete!", "Success")
    } catch {
        $batchLogBox.AppendText("Error: $_`n")
    }
})

$tab2.Controls.AddRange(@($batchInputLabel, $batchInputBox, $batchInputButton,
    $batchOutputLabel, $batchOutputBox, $batchOutputButton,
    $batchProviderLabel, $batchProviderCombo,
    $batchLogBox, $batchProcessButton))

# Tab 3: Settings
$tab3 = New-Object System.Windows.Forms.TabPage
$tab3.Text = "Settings"
$tab3.Padding = New-Object System.Windows.Forms.Padding(10)

$apiLabel = New-Object System.Windows.Forms.Label
$apiLabel.Text = "API Configuration"
$apiLabel.Font = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
$apiLabel.Location = New-Object System.Drawing.Point(10, 10)
$apiLabel.Size = New-Object System.Drawing.Size(300, 25)

$grokLabel = New-Object System.Windows.Forms.Label
$grokLabel.Text = "Grok API Key:"
$grokLabel.Location = New-Object System.Drawing.Point(10, 50)
$grokLabel.Size = New-Object System.Drawing.Size(100, 20)

$grokBox = New-Object System.Windows.Forms.TextBox
$grokBox.Location = New-Object System.Drawing.Point(120, 50)
$grokBox.Size = New-Object System.Drawing.Size(400, 25)
$grokBox.PasswordChar = '*'
$grokBox.Text = $env:XAI_API_KEY

$grokSaveButton = New-Object System.Windows.Forms.Button
$grokSaveButton.Text = "Save"
$grokSaveButton.Location = New-Object System.Drawing.Point(530, 50)
$grokSaveButton.Size = New-Object System.Drawing.Size(80, 25)
$grokSaveButton.Add_Click({
    [Environment]::SetEnvironmentVariable("XAI_API_KEY", $grokBox.Text, "User")
    [System.Windows.Forms.MessageBox]::Show("Grok API Key saved (restart PowerShell to apply)", "Success")
})

$mjLabel = New-Object System.Windows.Forms.Label
$mjLabel.Text = "Midjourney API Key:"
$mjLabel.Location = New-Object System.Drawing.Point(10, 90)
$mjLabel.Size = New-Object System.Drawing.Size(100, 20)

$mjBox = New-Object System.Windows.Forms.TextBox
$mjBox.Location = New-Object System.Drawing.Point(120, 90)
$mjBox.Size = New-Object System.Drawing.Size(400, 25)
$mjBox.PasswordChar = '*'
$mjBox.Text = $env:MIDJOURNEY_API_KEY

$mjSaveButton = New-Object System.Windows.Forms.Button
$mjSaveButton.Text = "Save"
$mjSaveButton.Location = New-Object System.Drawing.Point(530, 90)
$mjSaveButton.Size = New-Object System.Drawing.Size(80, 25)
$mjSaveButton.Add_Click({
    [Environment]::SetEnvironmentVariable("MIDJOURNEY_API_KEY", $mjBox.Text, "User")
    [System.Windows.Forms.MessageBox]::Show("Midjourney API Key saved (restart PowerShell to apply)", "Success")
})

$tab3.Controls.AddRange(@($apiLabel, $grokLabel, $grokBox, $grokSaveButton, $mjLabel, $mjBox, $mjSaveButton))

# Add tabs to main container
$mainContainer.TabPages.Add($tab1)
$mainContainer.TabPages.Add($tab2)
$mainContainer.TabPages.Add($tab3)

# Add components to form
$form.Controls.Add($titlePanel)
$form.Controls.Add($mainContainer)

# Show form
$form.ShowDialog() | Out-Null
