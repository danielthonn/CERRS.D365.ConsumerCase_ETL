

$ServerName = $env:computername
$SSISCatalog = "SSISDB"
$CatalogPwd = "Cognos123"






$OutputFileLocation = "c:\temp\1095a.log"

Start-Transcript -path $OutputFileLocation -append


$uid = "Cognos"	
$pwd = "Cognos123"
$SQLServer = $env:computername





$FolderPath="C:\temp\ispacs"

$Dir = Get-ChildItem -Path $FolderPath -Filter *.ispac

write-host "ispacs: $Dir"



Foreach ($ispac in $Dir)
{

############################
########## SET ENV ##########
############################

Write-host "ispac: $ispac"
$isname=[IO.Path]::GetFileNameWithoutExtension($ispac)

Write-host "isname: $isname"
$ProjectFilePath = "$FolderPath\$ispac"
$ProjectName = "$isname"
$FolderName = "$isname"
$EnvironmentName = "$isname"


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
# Constructor args: variable name, type, default value, sensitivity, description
$environment.Variables.Add(“CustomerID”, [System.TypeCode]::String, "C111", "false", "Customer ID")
#$environment.Variables.Add(“FtpUser”, [System.TypeCode]::String, $EnvironmentName, "false", "FTP user")
#$environment.Variables.Add(“FtpPassword”, [System.TypeCode]::String, "Cognos123", "true", "FTP password")
$environment.Alter()
 
###########################
########## READY ##########
###########################
# Kill connection to SSIS
$IntegrationServices = $null
Write-Host "Finished"


}



Stop-Transcript
 
Write-Host "All done."

