if (-not (test-path "C:\Program Files\7-Zip\7z.exe")) {throw "C:\Program Files\7-Zip\7z.exe needed"} 
set-alias sz "C:\Program Files\7-Zip\7z.exe"  

$Source = "c:\temp\ispacs\*.*" 
$Target = "c:\temp\ispacs.zip"
if (Test-Path $Target )
{
write-host "found $Target"
remove-item $Target
}
else
{
write-host "zip not found"
}

write-host "creating zip of $Target"

 sz a -r  $Target -xr!*git -xr!*vs  $Source

write-host "done zipping"

# upload to Azure Blob

write-host $env:computer
Import-Module AzureRM
Get-Module AzureRM -list | Select-Object Name,Version,Path
$StorageAccountName = "cerrsdevblob" 
$StorageAccountKey = "XfMOGZmh9aVjkYdB6KBV8nLZpUyr8Z28aibmrx/RYwp+frre0PzBrKaYNXC6xAx/q1BFZCn6mOE854yHZXYEhw=="

$ctx = New-AzureStorageContext -Environment AzureUSGovernment -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey
		 
	$ContainerName = "jenkins-artifacts"	

$ContainerName = "jenkins-artifacts"
#New-AzureStorageContainer -Name $ContainerName -Context $ctx -Permission Blob
$localFileDirectory = "c:\temp\"
$files = "ispacs.zip"

$localFile = $localFileDirectory+$files
write-host "local: $localFile"
      Set-AzureStorageBlobContent -File $localFile -Container $ContainerName -Blob $file -Context $ctx -force