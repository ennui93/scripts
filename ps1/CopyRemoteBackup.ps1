# SCP a TGZ backup from a remote machine to a local folder, or send an e-mail if this fails.
# Makes use of PSCP.exe command from PuTTY, see:
# http://www.chiark.greenend.org.uk/~sgtatham/putty/

﻿$backupTargetDirectory = "C:\Backups\"
$backupTargetFilenamePrefix = "backup-"

$pscpLocation = "“C:\Program Files\PuTTY\pscp.exe"
$keyFile = "C:\backup.ppk"
$backupSource = "backup@example.com:/home/backup/backup.list"

$failureMessageSubject = "example.com Backup Failure"
$smtpServer = New-Object System.Net.Mail.SMTPClient –ArgumentList "example.com"

### Configuration section ends

if(!(Test-Path $backupTargetDirectory -PathType Container))
{
    $message = New-Object System.Net.Mail.MailMessage –ArgumentList root@example.com, logs@example.com, $failureMessageSubject, "Failed to open backup directory: " + $backupTargetDirectory
    $smtpServer.Send($message)
    exit 1
}

if(!(Test-Path $pscpLocation -PathType Leaf))
{
    $message = New-Object System.Net.Mail.MailMessage –ArgumentList root@example.com, logs@example.com, $failureMessageSubject, "Failed to locate pscp at: " + $pscpLocation
    $smtpServer.Send($message)
    exit 1
}

if(!(Test-Path $keyFile -PathType Leaf))
{
    $message = New-Object System.Net.Mail.MailMessage –ArgumentList root@example.com, logs@example.com, $failureMessageSubject, "Failed to locate SSH key: " + $keyFile
    $smtpServer.Send($message)
    exit 1
}

$dateStamp = Get-Date -Format MMdd
$error.Clear()
$backupCmd = $pscpLocation + " -q -i " + $keyFile + " -batch " + $backupSource + " " + $backupTargetDirectory + $backupTargetFilenamePrefix + $dateStamp + ".tgz"
Invoke-Expression $backupCmd

if(!($error.Count -eq 0))
{
    $message = New-Object System.Net.Mail.MailMessage –ArgumentList root@example.com, logs@example.com, $failureMessageSubject, ("Failed to retrieve backup: " + $error)
    $smtpServer.Send($message)
    exit 1
}
