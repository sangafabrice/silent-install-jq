Set-Location -Path ($MyInvocation.MyCommand.Path -replace '\\[^\\]+$')
# using module .\JqUpdater.psm1

Import-Module .\JqUpdater.psm1

Install-Jq H:\Software\Jq