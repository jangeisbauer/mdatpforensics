# __  __ ____    _  _____ ____    _____ ___  ____  _____ _   _ ____ ___ ____ ____  
# |  \/  |  _ \  / \|_   _|  _ \  |  ___/ _ \|  _ \| ____| \ | / ___|_ _/ ___/ ___| 
# | |\/| | | | |/ _ \ | | | |_) | | |_ | | | | |_) |  _| |  \| \___ \| | |   \___ \ 
# | |  | | |_| / ___ \| | |  __/  |  _|| |_| |  _ <| |___| |\  |___) | | |___ ___) |
# |_|  |_|____/_/   \_|_| |_|     |_|   \___/|_| \_|_____|_| \_|____|___\____|____/ 
#
# @janvonkirchheim | Blog: https://emptydc.com | Podcast: https://hairlessinthecloud.com 
#
# Upload start-MdatpForensics.ps1 and this file (get-MdatpForensics.ps1) here to the library
# Put this ps1 to the target machine (put get-MdatpForensics.ps1) --> C:\ProgramData\Microsoft\Windows Defender Advanced Threat Protection\Downloads\
# Also put ShadowSpawn.exe to the target machine
# Enable the features as needed in the feature section (don't do to much at once - since the script will timeout otherwise)
# Adjust $user, $pathsToCopy and $fileNamesForRecovery accordingly in the "variables to change section"
# Then run "start-MdatpForensics.ps1"
# After it ran, run fileinfo C:\MdatpForensics.zip and then getfile C:\MdatpForensics.zip

#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Variables to change:
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

# Enable Features
$RegistryExport=$false 
$FileRecovery=$true
$FileCopy=$true
$HostsExport=$true

# MODIFY: Username
$user="jangeisbauer" #according to the foldername in c:\users\...

# MODIFY: Pathes you like to copy from the target computer to our forensic folder (which will be compressed afterwards) --> need a comma after each line except for the last line
$pathsToCopy=@(

    ("C:\Users\$user\AppData\Local\Microsoft\Windows\WebCache","IEWebCache")
)

# MODIFY: Filenames to recover by powerforensics
$fileNamesForRecovery=@(
"DocToRecover.docx"
)

#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# End of variables section
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

# FileCopies
if($FileCopy)
{
    foreach($pathToCopy in $pathsToCopy)
    {
        $target=$pathToCopy[1]
        & "C:\ProgramData\Microsoft\Windows Defender Advanced Threat Protection\Downloads\ShadowSpawn.exe" $pathToCopy[0] Q: robocopy Q:\ "c:\MdatpForensics\$target" /s
    }
}

# hosts
if($HostsExport)
{
    Get-Content "C:\Windows\System32\drivers\etc\hosts" >c:\MdatpForensics\hosts.txt
}

# RegExport
if($RegistryExport)
{
    regedit /e c:\MdatpForensics\reg-backup\reg-backup.reg
}

# File Recovery
if($FileRecovery)
{
    Install-PackageProvider Nuget -force
    Install-Module powerforensics -force
    Import-module -name PowerForensics

    foreach($fileName in $fileNamesForRecovery)
    {
        $file1=Get-ForensicFileRecord | Where {$_.Name -eq $fileName}
        New-Item -ItemType "directory" -Path "c:\MdatpForensics\DeletedFiles"
        $file1.CopyFile("c:\MdatpForensics\DeletedFiles\$fileName")
    }
}

# put it all together into a zip
Compress-Archive -Path (get-childitem -path "c:\MdatpForensics" -force | select-object -expandProperty 'FullName') -DestinationPath "C:\MdatpForensics.zip"