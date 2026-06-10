#requires -Version 5.1

$ErrorActionPreference = 'Stop'

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$ScriptPath = Join-Path $Root 'scripts\Copy-SelectedItemText.ps1'
$LauncherPath = Join-Path $Root 'scripts\Run-Hidden.vbs'
$WScriptExe = Join-Path $env:SystemRoot 'System32\wscript.exe'

if (-not (Test-Path -LiteralPath $ScriptPath)) {
    throw "Core script was not found: $ScriptPath"
}

if (-not (Test-Path -LiteralPath $LauncherPath)) {
    throw "Hidden launcher was not found: $LauncherPath"
}

if (-not (Test-Path -LiteralPath $WScriptExe)) {
    throw "Windows Script Host was not found: $WScriptExe"
}

function New-UnicodeString {
    param(
        [Parameter(Mandatory = $true)]
        [int[]]$CodePoints
    )

    return -join ($CodePoints | ForEach-Object { [char]$_ })
}

function Set-RegistryStringValue {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    New-ItemProperty -LiteralPath $Path -Name $Name -Value $Value -PropertyType String -Force | Out-Null
}

$copyFileNameLabel = New-UnicodeString -CodePoints @(0x590D, 0x5236, 0x6587, 0x4EF6, 0x540D)
$copyFullPathLabel = New-UnicodeString -CodePoints @(0x590D, 0x5236, 0x5B8C, 0x6574, 0x8DEF, 0x5F84)

$entries = @(
    @{
        Key = 'HKCU:\Software\Classes\AllFilesystemObjects\shell\CopyFileName'
        Label = $copyFileNameLabel
        Mode = 'Name'
    },
    @{
        Key = 'HKCU:\Software\Classes\AllFilesystemObjects\shell\CopyFullPath'
        Label = $copyFullPathLabel
        Mode = 'FullPath'
    }
)

foreach ($entry in $entries) {
    $menuKey = $entry.Key
    $commandKey = Join-Path $menuKey 'command'

    New-Item -Path $menuKey -Force | Out-Null
    Set-Item -LiteralPath $menuKey -Value $entry.Label
    Set-RegistryStringValue -Path $menuKey -Name 'MUIVerb' -Value $entry.Label
    Set-RegistryStringValue -Path $menuKey -Name 'Icon' -Value 'imageres.dll,-5302'
    Set-RegistryStringValue -Path $menuKey -Name 'MultiSelectModel' -Value 'Player'
    Set-RegistryStringValue -Path $menuKey -Name 'Position' -Value 'Bottom'

    New-Item -Path $commandKey -Force | Out-Null
    $command = "`"$WScriptExe`" //nologo `"$LauncherPath`" `"$($entry.Mode)`" `"%1`""
    Set-Item -LiteralPath $commandKey -Value $command
}

Write-Host 'Install completed.'
Write-Host 'The context menu now uses a hidden launcher to avoid the flashing black console window.'
Write-Host 'The entries are positioned at the bottom of the classic context menu instead of the top.'
Write-Host 'On Windows 11, use Show more options or Shift + F10 if the entries do not appear in the first context menu.'
Write-Host 'If this tool folder is moved, run install.ps1 again from the new location.'
