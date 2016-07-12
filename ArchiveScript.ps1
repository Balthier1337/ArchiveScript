# 
# Author: Joseph McConville
# Website: http://www.lionheartservices.co.uk
# Created: 2014-01-21
# Modified: 2014-10-30
# Script: Recursive Folder Backup
# Version: 2.0
# Description: A quick PowerShell script for the backup of an entire directory, to another directory
#

# 
# DEFINE ALL NECESSARY VARIABLES
# 

# Current Date
$Date = Get-Date
# Timespan used for ShowOldFiles
$Timespan = new-timespan -days 30
# Define service(s) to be stopped
# NOTE: Must be the "Service Name", not the "Display Name" of the service
$Service_1 = ""
# Original file location
$OrigPath = ""
# Backup folder location
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
New-Item $BackupErrorLogDir -type directory -force
# Begin logging to log file
Start-Transcript -path "$BackupErrorLogDir\$BackupErrorLogFile" -append

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
             # NOTE: Add -WhatIf to the command, to perform a "Test Run"
			 Remove-Item -path $Loc -Force -Recurse -Verbose -WhatIf
		}
        # Uncomment this statement while using -WhatIf for better debugging
        # Runs if the file is newer than the timespan
        #else {
            # prints "Newer : " followed by the filename
		#	echo "Newer : $File"
		#}
	}
}

# 
# BEGIN BACKUP PROCESS
# 

# Stop the associated service
Stop-Service $Service_1 -WhatIf
# Create today's backup folder
New-Item $BackupPath\$BackupDir -type directory -Force -WhatIf
# Copy all files from the original location
Copy-Item $OrigPath\* $BackupPath\$BackupDir -Force -WhatIf

# 
# BEGIN CLEAN UP PROCESS
# 

# Start the associated service
Start-Service $Service_1 -WhatIf
# Checks backup files 
RemoveOldFiles $BackupPath $Timespan
# Stops logging process
Stop-Transcript 