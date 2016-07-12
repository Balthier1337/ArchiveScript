# 
# Author: Joseph McConville
# Website: http://www.lionheartservices.co.uk
# Created: 2014-01-21
# Modified: 2014-10-30
# Script: Recursive Folder Backup
# Version: 2.1
# Description: A quick PowerShell script for the backup of an entire directory, to another directory
# Change log:
# 

# 
# DEFINE ALL NECESSARY VARIABLES
# 

[CmdletBinding()]
Param(
[switch]$WhatIf
)

# Current Date
$Date = Get-Date
# Timespan used for ShowOldFiles
$Timespan = new-timespan -days 30
# Define service(s) to be cycled
# NOTE: Must be the "Service Name", not the "Display Name" of the service
$Services = "",""
# Original file location, without trailing \
$OrigPath = ""
# Backup folder location, without trailing \
$BackupPath = ""
# Define today's backup folder
$BackupDir = "{0}-{1:d2}-{2:d2}" -f $date.year, $date.month, $date.day
# Log folder location
$BackupErrorLogDir = "$BackupPath\logs"
# Define today's log file
$BackupErrorLogFile = "{0}-{1:d2}-{2:d2}.log" -f $date.year, $date.month, $date.day

# 
# BEGIN LOGGING PROCESS
# 

# Action to take on errors - "SilentyContinue": Continue on error, don't display errors
$ErrorActionPreference="SilentlyContinue"
# Stop any previous logging
Stop-Transcript | out-null
# Action to take on errors - "Continue": Continue on error, display errors
$ErrorActionPreference = "Continue"
# Create log folder
New-Item $BackupErrorLogDir -Type Directory -Force
# Begin logging to log file
Start-Transcript -Path "$BackupErrorLogDir\$BackupErrorLogFile" -Append

# 
# DEFINE ALL NECESSARY FUNCTIONS
# 

# Deletes files older than the given timespan, from the specified folder
function RemoveOldFiles($Path, $Timespan)
{
    # Create an array with files in the folder
    $Files = get-childitem $Path
    # Start the loop of the array
	Foreach ($File in $Files) {
        # Define the full file location
	    $Loc = "$BackupPath\$file"
        # Get the age of the file
		$LastWrite = (get-item $Loc).LastWriteTime
        # Check if the file is older than the timespan
		if (((get-date) - $LastWrite) -gt $Timespan) {
			# Delete the file, if it is older
			Remove-Item -path $Loc -Force -Recurse -Verbose -WhatIf:$WhatIf
		}
        # Only runs when -WhatIf is specified
        elseif ($WhatIf) {
            # prints "Newer : " followed by the filename
		    echo "Newer : $File"
		}
	}
}

# Starts/Stops all services in $Services
function ToggleServices($ServicesArray, $Toggle) {
    # Build the correct toggle command
    $ToggleService = "$Toggle`-Service"
    # Check if we are stopping the service
    if ($Toggle -eq "Stop") { 
        # Set the ForceFlag to make sure our service is stopped
        $ForceFlag = "True" 
    }
    # Loop through items in $ServicesArray
    Foreach ($Service in $ServicesArray) {
        # Get the details of the currently loaded service
        $ServiceStatus = Get-Service $Service
        # Check if the ForceFlag variable is set
        if ($ForceFlag) {
            # Force the service to stop
            & $ToggleService $Service -Force -Verbose -WhatIf:$WhatIf
            # Check to make sure we don't wait for the service to start while using -WhatIf
            if ($WhatIf -eq "True") {
                # Wait until the service has been stopped
                $ServiceStatus.WaitForStatus('Stopped')
            }
        }
        else {
            # Start the service
            & $ToggleService $Service -Verbose -WhatIf:$WhatIf
            # Check to make sure we don't wait for the service to start while using -WhatIf
            if ($WhatIf -eq "True") {
                # Wait until the service has been started
                $ServiceStatus.WaitForStatus('Running')
            }
        }
	}
}

# 
# BEGIN BACKUP PROCESS
# 

# Stop the associated services
ToggleServices $Services "Stop"
# Create today's backup folder
New-Item $BackupPath\$BackupDir -type directory -Force -Verbose -WhatIf:$WhatIf
# Copy all files from the original location
Copy-Item $OrigPath\* $BackupPath\$BackupDir -Force -Verbose -WhatIf:$WhatIf

# 
# BEGIN CLEAN UP PROCESS
# 

# Start the associated service
ToggleServices $Services "Start"
# Checks backup files 
RemoveOldFiles $BackupPath $Timespan
# Stops logging process
Stop-Transcript 