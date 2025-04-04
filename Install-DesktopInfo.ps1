# Define the log file
$LogFile = "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\DesktopInfo.log"

# Set source and destination folders
$TargetFolder = "C:\Windows\IntuneFiles\DesktopInfo"
$SourceFolder = "$PSScriptRoot\DesktopInfo"

# Remove existing log file if it exists
If (Test-Path $LogFile) {
    Remove-Item $LogFile -Force -ErrorAction SilentlyContinue
}

# Function to write messages to the log
Function Write-Log {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message
    )
    $TimeGenerated = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $Line = "$TimeGenerated : $Message"
    Add-Content -Value $Line -Path $LogFile -Encoding Ascii
}

Write-Log "Starting DesktopInfo deployment script"

# Ensure target folder exists
If (!(Test-Path $TargetFolder)) {
    Write-Log "Target folder $TargetFolder does not exist. Creating it."
    New-Item -Path $TargetFolder -ItemType Directory -Force | Out-Null
}

# Copy files from source to destination
Write-Log "Copying files from $SourceFolder to $TargetFolder"
try {
    Copy-Item -Path "$SourceFolder\*" -Destination $TargetFolder -Recurse -Force -ErrorAction Stop
    Write-Log "Files successfully copied."
} catch {
    Write-Log "Error copying files: $($_.Exception.Message)"
}

# Define the scheduled task
$TaskName = "Run DesktopInfo"
$Action = New-ScheduledTaskAction -Execute "$TargetFolder\DesktopInfo.exe"
$Trigger = New-ScheduledTaskTrigger -AtLogOn
$Principal = New-ScheduledTaskPrincipal -UserId "NT AUTHORITY\Users" -LogonType Interactive -RunLevel Highest

# Remove existing task if present
$ExistingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($ExistingTask) {
    Write-Log "Existing scheduled task '$TaskName' found. Removing it."
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}

# Register the new task
try {
    Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Principal $Principal
    Write-Log "Scheduled task '$TaskName' successfully created."
} catch {
    Write-Log "Error creating scheduled task: $($_.Exception.Message)"
}

Write-Log "DesktopInfo deployment script completed."
