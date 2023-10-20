
param(
  [Parameter(Mandatory = $true)]
  [string]$branchName,
  [string]$gitDirPrefix = ""
  )
  
Write-Host "Initializing ..."



# Get the directory path that the script is located in, then change directory to its
# location.
$scriptPath = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
Set-Location -Path $scriptPath



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
  Write-Host "A prefix override was not provided. I will use your username: $gitDirPrefix" -ForegroundColor Yellow
}



# Create two new branches from the branch that the script was called on. This will create
# a new branch called "my-branch-name-original" and "my-branch-name-working".
# The original branch will be used in the pull requests as the comparison of changes. The 
# user/developer should make all changes in the working branch.
[string]$branchNameWorking = "$gitDirPrefix/$branchName-working"
[string]$branchNameOriginal = "$gitDirPrefix/$branchName-original"
[string]$currentBranch = git branch --show-current

Write-Host "Creating new branches from $currentBranch ..."

git branch $branchNameOriginal -q
git checkout -b $branchNameWorking -q

if ($LASTEXITCODE -ne 0) {
  Write-Host "Git commands failed. There is likely additional output above." -ForegroundColor Red
  exit
}



# End of script, report variables names for convenience.
Write-Host "Success!`nMake changes on your working branch, then in your pull request, use the original branch as the target branch for comparisson.`n"
Write-Host "Branch base: $currentBranch" -ForegroundColor Green
Write-Host "Branch name (working): $branchNameWorking" -ForegroundColor Green
Write-Host "Branch name (original): $branchNameOriginal`n" -ForegroundColor Green
