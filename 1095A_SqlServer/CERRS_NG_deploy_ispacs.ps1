

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

$array = @("1095A_SqlServer.ispac","CDE_TerminationSource.ispac")

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
$FolderName = "CERRS_NG"
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

$CRMDBConnectionString = $environment.Variables["CRMDBConnectionString"];

if (!$CRMDBConnectionString)
{
    Write-Host "Adding environment variables ..." 
  $environment.Variables.Add("CRMDBConnectionString", [System.TypeCode]::String, "Data Source=$CRMServer;Initial Catalog=CERRSNG_MSCRM;Provider=SQLNCLI11.1;Integrated Security=SSPI;Auto Translate=False;", $false, "CRMDBConnectionString")
 
 
    $environment.Alter()
    $CRMDBConnectionString = $environment.Variables["CRMDBConnectionString"];
}
else
{
write-host "CRMDBConnectionString: $CRMDBConnectionString exists"
}





$FileFolder = $environment.Variables["FileFolder"];

if (!$FileFolder)
{
    Write-Host "Adding environment variables ..." 
   $environment.Variables.Add("FileFolder", [System.TypeCode]::String, "E:\Data\Files", $false, "FileFolder")
 
    $environment.Alter()
    $FileFolder = $environment.Variables["FileFolder"];
}

else
{
write-host "FileFolder: $FileFolder exists"
}

$HICSDestinationFolder = $environment.Variables["HICSDestinationFolder"];

if (!$HICSDestinationFolder)
{
    Write-Host "Adding environment variables ..." 
   $environment.Variables.Add("FileFolders", [System.TypeCode]::String, "E:\DataTeam\HICS_Extract\SSIS HICS LOAD\", $false, "FileFolders")
 
    $environment.Alter()
    $HICSDestinationFolder = $environment.Variables["HICSDestinationFolder"];
}

else
{
write-host "HICSDestinationFolder: $HICSDestinationFolder exists"
}

$HICSFolder = $environment.Variables["HICSFolder"];

if (!$HICSFolder)
{
    Write-Host "Adding environment variables ..." 
   $environment.Variables.Add("FileFolders", [System.TypeCode]::String, "E:\DataTeam\HICS_Extract\", $false, "FileFolders")
 
    $environment.Alter()
    $HICSFolder = $environment.Variables["HICSFolder"];
}

else
{
write-host "HICSFolder: $HICSFolder exists"
}

$SSISFolder = $environment.Variables["SSISFolder"];

if (!$SSISFolder)
{
    Write-Host "Adding environment variables ..." 
   $environment.Variables.Add("SSISFolder", [System.TypeCode]::String, "E:\Data\Files\IN", $false, "SSISFolder")
 
    $environment.Alter()
    $SSISFolders = $environment.Variables["SSISFolder"];
}
else
{
write-host "SSISFolder: $SSISFolder exists"
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

# Adding variable to our environment
# Constructor args: variable name, type, default value, sensitivity, description

#$environment.Variables.Add(“CRMDBConnectionString”, [System.TypeCode]::String, "Data Source=$CRMServer;Initial Catalog=CERRSNG_MSCRM;Provider=SQLNCLI11.1;Integrated Security=SSPI;Auto Translate=False;", $false, "CRMDBConnectionString")
#$environment.Variables.Add(“FilesFolder”, [System.TypeCode]::String, "E:\Data\Files\", $false, "FilesFolder")
#$environment.Variables.Add(“HICSDestinationFolder”, [System.TypeCode]::String, "E:\DataTeam\HICS_Extract\SSIS HICS LOAD\", $false, "HICSDestinationFolder")
#$environment.Variables.Add(“HICSFolder”, [System.TypeCode]::String, "E:\DataTeam\HICS_Extract\", $false, "HICSFolder")
#$environment.Variables.Add("SSISFolder", [System.TypeCode]::String, "E:\Data\files\in\", $false, "SSISFolder")
#$environment.Alter()

 


 
 
 
  #Step3. Add environment variables reference to projects

	#$projectrefSource = $SSISFolder.Projects[$SourceToLoad]  
	# Adding environment references,only if reference not exists
	#if ($projectrefSource.References.Item($SSISEnvironmentName, $SSISFolder.Name) -eq $null) 
	#{
		#Write-Host "Adding environment reference to $SSISEnvironmentName to $SourceProjectName Project"		
		#$projectrefSource.References.Add($SSISEnvironmentName, $SSISFolder.Name)            
		#$projectrefSource.Alter()
	#}
		
	#Write-Host "Mapping environment variables in $SSISEnvironmentName to $SourceProjectName Project"
	#$projectrefSource.Parameters["v_ServerName"].Set([Microsoft.SqlServer.Management.IntegrationServices.ParameterInfo+ParameterValueType]::Referenced, "v_ServerName")
    #$projectrefSource.Parameters["v_DataWarehouse_DBName"].Set([Microsoft.SqlServer.Management.IntegrationServices.ParameterInfo+ParameterValueType]::Referenced, "v_DataWarehouse_DBName")	
	#$projectrefSource.Alter()
 
###########################
########## READY ##########
###########################
# Kill connection to SSIS
$IntegrationServices = $null
Write-Host "Finished"






Stop-Transcript
 
Write-Host "All done."

