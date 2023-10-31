
param(
  [Parameter(Mandatory = $true)]
  [string]$branchName,
  [string]$gitDirPrefix = ""
)
  
Write-Host "Initializing ..."

# Get the directory path that the script is located in, then change directory to of its
# parent.
$scriptPath = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
$rootPath = "$scriptPath/../"
Set-Location -Path $rootPath

$tempDirPath = ".\temp"
New-Item -ItemType Directory -Path $tempDirPath


# If no argument was provided for a prefix, use the username. If the username is empty,
# which would be very weird, let the user know and exit the program. They can just provide
# something like "setup-local.ps1 my-branch-name my-username" to override the prefix.
if ([string]::IsNullOrEmpty($gitDirPrefix)) {
  if ([string]::IsNullOrEmpty($env:USERNAME)) {
    Write-Host "A prefix override was not provided, and your username could not be determined." -ForegroundColor Red
    Write-Host "Please re-run this script while providing a second argument."
    exit
  }

  $gitDirPrefix = $env:USERNAME
  Write-Host "`nA prefix override was not provided. I will use your username: $gitDirPrefix`n" -ForegroundColor Yellow
}


# Check if the PSYaml PowerShell module is installed. If it doesn't, install it. User
# will need to authorize admin mode.
if (-not (Get-Module -ListAvailable PSYaml)) {
  Write-Host "Module PSYaml not found in your current session. Installing ..."
  Start-Process powershell.exe -Wait -Verb RunAs -ArgumentList "$scriptPath\install-psyaml.ps1"
}

Import-Module PSYaml

# # Read the contents of the .env file
$envContents = Get-Content -Path ".env" -Raw

# # Convert the YAML contents to a PowerShell object
$envObject = ConvertFrom-Yaml $envContents

# # Access the values in the object
Write-Host "Connected to $($envObject.PAGES_SITE_GUID) on $($envObject.ENVIRONMENT_URL)"




# Confirm to the user of what they're about to do.

[string]$branchNameWorking = "$gitDirPrefix/$branchName-working"
[string]$branchNameOriginal = "$gitDirPrefix/$branchName-original"
[string]$currentBranch = git branch --show-current

Write-Host "Initialization success!

Do not continue if corrections to the below need to be made, or if you're unsure about your local changes."

Write-Host "`nPlease review the following information:

- Changes to be stashed on branch name: $currentBranch
- Branch name (working): $branchNameWorking
- Branch name (original/target): $branchNameOriginal
" -ForeGroundColor Blue

$confirmation = Read-Host "Are you sure you want to continue? (Y/N)"
if ($confirmation -ne "Y") {
  Write-Host "Exiting ..."
  Remove-Item -Path $tempDirPath -Recurse -Force
  exit
}


# Stash local changes.
Write-Host "Stashing your local changes ..."
git stash --include-untracked --quiet


Write-Host "Checking out and pulling updates from main ..."
git reset HEAD --hard
git checkout main
git fetch
git pull

if ($LASTEXITCODE -ne 0) {
  exit
}

# Log the user in.
# TODO - Detect if the user is already logged in. If they are, skip the login process.
# Run 'pac auth' for more information.
# NOTE - Duplicate login profiles are not made. pac auth is smart enough to overrite the
# last token.
Write-Host "Do not close/exit this process while logging in. Logging in ..."
pac auth create -u $envObject.ENVIRONMENT_URL

# Download the Power Pages site to local.
Write-Host "Pulling changes from Power Pages ..."
pac paportal download -p $rootPath/TIMSSolution/PowerPages -id $envObject.PAGES_SITE_GUID


# Create two new branches from the branch that the script was called on. This will create
# a new branch called "my-branch-name-original" and "my-branch-name-working".
# The original branch will be used in the pull requests as the comparison of changes. The 
# user/developer should make all changes in the working branch.

Write-Host "Creating new branches from $currentBranch ..."

git add --all
git commit -m "Auto script: pac pull and pac paportal download"
git checkout -b $branchNameOriginal -q
git push -u origin $branchNameOriginal -q
git checkout -b $branchNameWorking -q
git push -u origin $branchNameWorking -q

if ($LASTEXITCODE -ne 0) {
  exit
}



# End of script, report variables names for convenience.
Write-Host "Success!`nMake changes on your working branch, then in your pull request, use the original branch as the target branch for comparisson.`n"
Write-Host "Branch base: $currentBranch" -ForegroundColor Green
Write-Host "Branch name (working): $branchNameWorking" -ForegroundColor Green
Write-Host "Branch name (original): $branchNameOriginal`n" -ForegroundColor Green


Remove-Item -Path $tempDirPath -Recurse -Force
