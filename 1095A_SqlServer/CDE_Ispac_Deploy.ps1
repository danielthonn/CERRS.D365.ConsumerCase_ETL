

$ServerName = $env:computername
$SSISCatalog = "SSISDB"
$CatalogPwd = "Cognos123"






$OutputFileLocation = "c:\temp\CDE.log"

Start-Transcript -path $OutputFileLocation -append


$uid = "Cognos"	
$pwd = "Cognos123"
$SQLServer = $env:computername





$FolderPath="C:\temp\ispacs"

#$Dir = Get-ChildItem -Path $FolderPath -Filter CDE_*.ispac

$array = @("CDE_FFM_Extract.ispac","CDE_Midas.ispac","CDE_PreAudit.ispac","CDE_RCNO.ispac","CDE_TerminationSource.ispac")

write-host "ispacs: $Dir"



Foreach ($ispac in $array)
{

############################
########## SET ENV ##########
############################

Write-host "ispac: $ispac"
$isname=[IO.Path]::GetFileNameWithoutExtension($ispac)

Write-host "isname: $isname"



#if ($SQLServer -eq "localhost")
#{
Write-host "isname: $isname"
$ProjectFilePath = "$FolderPath\$ispac"
$ProjectName = "$isname"
$FolderName = "CDE"
$EnvironmentName = "CDE"

write-host "EnvironmentName: $EnvironmentName"

#}

write-host "EnvironmentName: $EnvironmentName"

if($ispac -eq "CDE_RNCO")
{
$ProjectName="RNCO_StagingArea"
}

if ($ispac -eq "CDE_RNCO")
{
$ProjectName="RCNO_StagingArea"
}


############################
########## SERVER ##########
############################
# Load the Integration Services Assembly


# Load the IntegrationServices Assembly
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Management.IntegrationServices") | Out-Null;
 
# Store the IntegrationServices Assembly namespace to avoid typing it every time
$ISNamespace = "Microsoft.SqlServer.Management.IntegrationServices"
 
Write-Host "Connecting to server ...$SQLServer"

# Create a connection to the server

#Provider=SQLNCLI10.1;Persist Security Info=False;User ID=Cognos;Password=Cognos123;Initial Catalog=master;Data Source=$SQLServer
$sqlConnectionString = "Data Source=$SQLServer;Initial Catalog=master;Trusted_Connection=True;"
#$sqlConnectionString = "Provider=sqloledb;Persist Security Info=False;User ID=Cognos;Password=Cognos123;Initial Catalog=master;Data Source=localhost;"


 
# Create the Integration Services object



$sqlConnection = New-Object System.Data.SqlClient.SqlConnection $sqlConnectionString
 
# Create the Integration Services object
$integrationServices = New-Object $ISNamespace".IntegrationServices" $sqlConnection


# Check if connection succeeded
if (-not $IntegrationServices)
{
    Throw [System.Exception] "Failed to connect to server $SsisServer "
}
else
{
    Write-Host "Connected to server" $SsisServer
}
 


#############################
########## CATALOG ##########
#############################

$catalog = $integrationServices.Catalogs[$SSISCatalog]



 

# Create the Integration Services object if it does not exist
if (!$catalog) {
    # Provision a new SSIS Catalog
    Write-Host "Creating SSIS Catalog ..."
    $catalog = New-Object "$ISNamespace.Catalog" ($integrationServices, $SSISCatalog, $CatalogPwd)
    $catalog.Create()
}
else
{
Write-host "catalog: $catalog exists"
}



############################
########## FOLDER ##########
############################

$folder = $catalog.Folders[$FolderName]




if (!$folder)

{
    # Create object to the folder
   
       
        Write-Host "Folder" $folder "not found, creating it"
        
	#Create a folder in SSISDB
    Write-Host "Creating Folder ..."
    $folder = New-Object "$ISNamespace.CatalogFolder" ($catalog, $FolderName, $FolderName)            
    $folder.Create()  

    }
    else
    {
        Write-Host "Folder" $FolderName "found"
	
    }


 

#############################
########## Project ##########
#############################

 
Write-Host "Deploying $ProjectName " 

Write-Host "ProjectFilePath: $ProjectFilePath " 

 
# Read the project file, and deploy it to the folder
[byte[]] $projectFile = [System.IO.File]::ReadAllBytes($ProjectFilePath)
$folder.DeployProject($ProjectName, $projectFile)



#############################
########## Environment ######
#############################
 
 

$environment = $folder.Environments[$EnvironmentName]


Write-host "environment: $environment"

if (!$environment)

{
    Write-Host "Creating environment ...$EnvironmentName" 
    $environment = New-Object "$ISNamespace.EnvironmentInfo" ($folder, $EnvironmentName, $EnvironmentName)

    $environment.Create()            
}
else
{
Write-host "ENV: $EnvironmentName exists" 
}



Write-Host "Adding environment reference to project($ProjectName) ..."
 


 



}

$project = $folder.Projects[$ProjectName]
write-host "project: $project"
$ref = $project.References[$EnvironmentName, $folder.Name]

if (!$ref)
{
    # making project refer to this environment
    Write-Host "Adding environment reference to project ..."
    $project.References.Add($EnvironmentName, $folder.Name)
    $project.Alter() 
}


else
{
Write-host "$ref for $ProjectName exists"
}






 
Write-Host "Adding server variables ..."

# Adding variable to our environment
#

$ERR_Import_ConnectionString = $environment.Variables["ERR_Import_ConnectionString"];

if (!$ERR_Import_ConnectionString)
{
    Write-Host "Adding environment variables ..." 
   $environment.Variables.Add("ERR_Import_ConnectionString", [System.TypeCode]::String, "Data Source=localhost;Initial Catalog=ERR_Import;Provider=SQLNCLI11.1;Integrated Security=SSPI;Auto Translate=$false;", $false, "ERR_Import_ConnectionString")
 
 
    $environment.Alter()
    $ERR_Import_ConnectionString = $environment.Variables["ERR_Import_ConnectionString"];
}
else
{
write-host "ERR_Import_ConnectionString: $ERR_Import_ConnectionString exists"
}





$FileFolders = $environment.Variables["FileFolders"];

if (!$FileFolders)
{
    Write-Host "Adding environment variables ..." 
   $environment.Variables.Add("FileFolders", [System.TypeCode]::String, "e:\Data\Files", $false, "FileFolders")
 
    $environment.Alter()
    $FileFolders = $environment.Variables["FileFolders"];
}

else
{
write-host "FileFolders: $FileFolders exists"
}

$SSISFolders = $environment.Variables["SSISFolders"];

if (!$SSISFolders)
{
    Write-Host "Adding environment variables ..." 
   $environment.Variables.Add("SSISFolders", [System.TypeCode]::String, "e:\Data\Files\IN", $false, "SSISFolders")
 
    $environment.Alter()
    $SSISFolders = $environment.Variables["SSISFolders"];
}
else
{
write-host "SSISFolders: $SSISFolders exists"
}

$PA1_ArchiveFolderPath = $environment.Variables["PA1_ArchiveFolderPath"];

if (!$PA1_ArchiveFolderPath)
{
    Write-Host "Adding environment variables ..." 
   $environment.Variables.Add("PA1_ArchiveFolderPath", [System.TypeCode]::String, "E:\Data\files\in\PREAUDIT\archive\", $false, "PA1_ArchiveFolderPath")
 
    $environment.Alter()
    $SSISFolders = $environment.Variables["PA1_ArchiveFolderPath"];
}
else
{
write-host "PA1_ArchiveFolderPath: $PA1_ArchiveFolderPath exists"
}

$PA1_ErrorFilePath = $environment.Variables["PA1_ErrorFilePath"];

if (!$PA1_ErrorFilePath)
{
    Write-Host "Adding environment variables ..." 
   $environment.Variables.Add("PA1_ErrorFilePath", [System.TypeCode]::String, "E:\Data\files\in\PREAUDIT\error\", $false, "PA1_ErrorFilePath")
    $environment.Alter()
    $SSISFolders = $environment.Variables["PA1_ErrorFilePath"];
}
else
{
write-host "PA1_ErrorFilePath: $PA1_ErrorFilePath exists"
}

$PA1_SourceFilePath = $environment.Variables["PA1_SourceFilePath"];

if (!$PA1_SourceFilePath)
{
    Write-Host "Adding environment variables ..." 
  $environment.Variables.Add("PA1_SourceFilePath", [System.TypeCode]::String, "E:\Data\files\in\PREAUDIT\new\", $false, "PA1_SourceFilePath")
    $environment.Alter()
    $SSISFolders = $environment.Variables["PA1_SourceFilePath"];
}
else
{
write-host "PA1_SourceFilePath: $PA1_SourceFilePath exists"
}


  #$environment.Variables.Add("ERR_Import_ConnectionString", [System.TypeCode]::String, "Data Source=localhost;Initial Catalog=ERR_Import;Provider=SQLNCLI11.1;Integrated Security=SSPI;Auto Translate=$false;", $false, "ERR_Import_ConnectionString")
 
   #$environment.Variables.Add("FileFolders", [System.TypeCode]::String, "e:\Data\Files", $false, "FileFolders")
  # $environment.Variables.Add("SSISFolders", [System.TypeCode]::String, "e:\Data\Files\IN", $false, "SSISFolders")
# $environment.Variables.Add("PA1_ArchiveFolderPath", [System.TypeCode]::String, "E:\Data\files\in\PREAUDIT\archive\", $false, "PA1_ArchiveFolderPath")
# $environment.Variables.Add("PA1_ErrorFilePath", [System.TypeCode]::String, "E:\Data\files\in\PREAUDIT\error\", $false, "PA1_ErrorFilePath")
   # $environment.Variables.Add("PA1_SourceFilePath", [System.TypeCode]::String, "E:\Data\files\in\PREAUDIT\new\", $false, "PA1_SourceFilePath")
 
 #$environment.Alter()

 






 
# making project refer to this environment
#$project = $folder.Projects[$ProjectName]
#$project.References.Add($EnvironmentName, $folder.Name)
#$project.Alter() 


###########################
########## READY ##########
###########################
# Kill connection to SSIS
$IntegrationServices = $null
Write-Host "Finished"
Stop-Transcript
 
Write-Host "All done."

