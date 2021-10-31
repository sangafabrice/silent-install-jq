$JQ_LATEST_RELEASE = 'https://api.github.com/repos/stedolan/jq/releases/latest'
$JQ_VERSION_PATTERN = '(?<Version>\d+(\.\d+(\.\d+(\.\d+)?)?)?)'
$JQ_DEFAULT_PATH = "$Env:LocalAppData\Microsoft\WindowsApps\jq.exe"

function Get-JqDownloadInfo {
    try {
        (Invoke-WebRequest -Uri $JQ_LATEST_RELEASE -ErrorAction Stop).Content |
        ConvertFrom-Json |
        Select-Object -Property @{
            Name = 'Version';
            Expression = {
                $_.tag_name -match $JQ_VERSION_PATTERN | Out-Null
                $Matches.Version
            }
        },@{
            Name = 'Link';
            Expression = {
                $_.assets.browser_download_url |
                ForEach-Object {
                    if ($_ -like '*jq-win64.exe') {$_}
                }
            }
        } -Unique
    }
    catch {}
}

function Compare-JqDownloadInfo ($Version) {
    ($(try {jq --version} catch {}) ?? 'jq-0.0') -match $JQ_VERSION_PATTERN | Out-Null
    ([version] $Version) -gt ([version] $Matches.Version)
}

function Save-Jq ($Link) {
    try {
        $LocalName = ([uri] $Link).Segments[-1]
        Start-BitsTransfer -Source $Link -Destination $LocalName -ErrorAction Stop
        [PSCustomObject] @{
            ExePath = (Resolve-Path -Path $LocalName 2> $null)?.Path
        }
    }
    catch {}
}

function Install-Jq ($SaveCopyTo) {
    $SaveCopyToExist = ($null -ne $SaveCopyTo) -and (Test-Path -Path $SaveCopyTo)
    Get-JqDownloadInfo |
    ForEach-Object {
        if (Compare-JqDownloadInfo -Version $_.Version) {
            if ($SaveCopyToExist) {
                $DlLocalArchive = "$($SaveCopyTo -replace '\\$')\jq-$($_.Version).exe"
                if (Test-Path -Path $DlLocalArchive) {
                    $_.Link = (Resolve-Path -Path $DlLocalArchive).Path
                }
            }
            Save-Jq -Link $_.Link |
            ForEach-Object {
                Copy-Item -Path $_.ExePath -Destination $JQ_DEFAULT_PATH -Force
                if ($SaveCopyToExist -and !(Test-Path -Path $DlLocalArchive) -and ($null -ne $_.ExePath)) {
                    Remove-Item -Path "$SaveCopyTo\*" -Recurse -Force
                    Copy-Item -Path $_.ExePath -Destination $DlLocalArchive -Force
                }
                Remove-Item -Path $_.ExePath -Recurse -Force
            }
        }
    }
}

Export-ModuleMember -Function 'Install-Jq'