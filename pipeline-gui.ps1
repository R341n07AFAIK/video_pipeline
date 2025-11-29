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
$inputLabel.Text = "Input Folder:"
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
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = "Select Output Folder"
    $dialog.RootFolder = [System.Environment+SpecialFolder]::MyComputer
    if ($dialog.ShowDialog() -eq "OK") {
        $outputBox.Text = $dialog.SelectedPath
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
        [System.Windows.Forms.MessageBox]::Show("Please select an input folder", "Error")
        return
    }
    if ([string]::IsNullOrWhiteSpace($outputBox.Text)) {
        [System.Windows.Forms.MessageBox]::Show("Please select an output folder", "Error")
        return
    }

    $logBox.AppendText("Starting processing...`n")
    $logBox.AppendText("Input: $($inputBox.Text)`n")
    $logBox.AppendText("Output: $($outputBox.Text)`n")
    $logBox.AppendText("Provider: $($providerCombo.SelectedItem)`n")
    $logBox.AppendText("FPS: $($fpsSpinner.Value)`n")
    $logBox.AppendText("Codec: $($codecCombo.SelectedItem)`n")
})

# Tab 1 Controls
$tab1.Controls.Add($inputLabel)
$tab1.Controls.Add($inputBox)
$tab1.Controls.Add($inputButton)
$tab1.Controls.Add($outputLabel)
$tab1.Controls.Add($outputBox)
$tab1.Controls.Add($outputButton)
$tab1.Controls.Add($providerLabel)
$tab1.Controls.Add($providerCombo)
$tab1.Controls.Add($fpsLabel)
$tab1.Controls.Add($fpsSpinner)
$tab1.Controls.Add($codecLabel)
$tab1.Controls.Add($codecCombo)
$tab1.Controls.Add($logLabel)
$tab1.Controls.Add($logBox)
$tab1.Controls.Add($processButton)

# Tab 2: Batch Processing
$tab2 = New-Object System.Windows.Forms.TabPage
$tab2.Text = "Batch Processing"
$tab2.Padding = New-Object System.Windows.Forms.Padding(10)

$batchLabel = New-Object System.Windows.Forms.Label
$batchLabel.Text = "Batch Input Folder:"
$batchLabel.Location = New-Object System.Drawing.Point(10, 20)
$batchLabel.Size = New-Object System.Drawing.Size(100, 20)

$batchBox = New-Object System.Windows.Forms.TextBox
$batchBox.Location = New-Object System.Drawing.Point(120, 20)
$batchBox.Size = New-Object System.Drawing.Size(600, 25)

$batchButton = New-Object System.Windows.Forms.Button
$batchButton.Text = "Browse..."
$batchButton.Location = New-Object System.Drawing.Point(730, 20)
$batchButton.Size = New-Object System.Drawing.Size(80, 25)
$batchButton.Add_Click({
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = "Select Batch Input Folder"
    $dialog.RootFolder = [System.Environment+SpecialFolder]::MyComputer
    if ($dialog.ShowDialog() -eq "OK") {
        $batchBox.Text = $dialog.SelectedPath
    }
})

$batchOutputLabel = New-Object System.Windows.Forms.Label
$batchOutputLabel.Text = "Batch Output Folder:"
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
    $dialog.Description = "Select Batch Output Folder"
    $dialog.RootFolder = [System.Environment+SpecialFolder]::MyComputer
    if ($dialog.ShowDialog() -eq "OK") {
        $batchOutputBox.Text = $dialog.SelectedPath
    }
})

$batchLogBox = New-Object System.Windows.Forms.RichTextBox
$batchLogBox.Location = New-Object System.Drawing.Point(10, 100)
$batchLogBox.Size = New-Object System.Drawing.Size(800, 350)
$batchLogBox.ReadOnly = $true
$batchLogBox.BackColor = [System.Drawing.Color]::Black
$batchLogBox.ForeColor = [System.Drawing.Color]::LimeGreen

$batchButton2 = New-Object System.Windows.Forms.Button
$batchButton2.Text = "Start Batch"
$batchButton2.Location = New-Object System.Drawing.Point(10, 460)
$batchButton2.Size = New-Object System.Drawing.Size(150, 35)
$batchButton2.BackColor = [System.Drawing.Color]::Green
$batchButton2.ForeColor = [System.Drawing.Color]::White
$batchButton2.Font = New-Object System.Drawing.Font("Arial", 11, [System.Drawing.FontStyle]::Bold)
$batchButton2.Add_Click({
    if ([string]::IsNullOrWhiteSpace($batchBox.Text)) {
        [System.Windows.Forms.MessageBox]::Show("Please select a batch input folder", "Error")
        return
    }
    $batchLogBox.AppendText("Starting batch processing from: $($batchBox.Text)`n")
})

$tab2.Controls.Add($batchLabel)
$tab2.Controls.Add($batchBox)
$tab2.Controls.Add($batchButton)
$tab2.Controls.Add($batchOutputLabel)
$tab2.Controls.Add($batchOutputBox)
$tab2.Controls.Add($batchOutputButton)
$tab2.Controls.Add($batchLogBox)
$tab2.Controls.Add($batchButton2)

# Tab 3: Settings
$tab3 = New-Object System.Windows.Forms.TabPage
$tab3.Text = "Settings"
$tab3.Padding = New-Object System.Windows.Forms.Padding(10)

$apiKeyLabel = New-Object System.Windows.Forms.Label
$apiKeyLabel.Text = "Grok API Key:"
$apiKeyLabel.Location = New-Object System.Drawing.Point(10, 20)
$apiKeyLabel.Size = New-Object System.Drawing.Size(100, 20)

$apiKeyBox = New-Object System.Windows.Forms.TextBox
$apiKeyBox.Location = New-Object System.Drawing.Point(120, 20)
$apiKeyBox.Size = New-Object System.Drawing.Size(600, 25)
$apiKeyBox.PasswordChar = '*'

$saveButton = New-Object System.Windows.Forms.Button
$saveButton.Text = "Save Settings"
$saveButton.Location = New-Object System.Drawing.Point(10, 60)
$saveButton.Size = New-Object System.Drawing.Size(150, 35)
$saveButton.BackColor = [System.Drawing.Color]::Blue
$saveButton.ForeColor = [System.Drawing.Color]::White
$saveButton.Font = New-Object System.Drawing.Font("Arial", 11, [System.Drawing.FontStyle]::Bold)
$saveButton.Add_Click({
    if ($apiKeyBox.Text) {
        [Environment]::SetEnvironmentVariable("XAI_API_KEY", $apiKeyBox.Text, "User")
        [System.Windows.Forms.MessageBox]::Show("Settings saved!", "Success")
    }
})

$tab3.Controls.Add($apiKeyLabel)
$tab3.Controls.Add($apiKeyBox)
$tab3.Controls.Add($saveButton)

# Add tabs to container
$mainContainer.TabPages.Add($tab1)
$mainContainer.TabPages.Add($tab2)
$mainContainer.TabPages.Add($tab3)

# Add containers to form
$form.Controls.Add($titlePanel)
$form.Controls.Add($mainContainer)

# Show form
$form.ShowDialog() | Out-Null
