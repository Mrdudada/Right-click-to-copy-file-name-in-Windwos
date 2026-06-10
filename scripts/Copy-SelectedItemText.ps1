param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Name', 'FullPath')]
    [string]$Mode,

    [switch]$UseExplorerSelection,

    [switch]$PassThru,

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Paths
)

$ErrorActionPreference = 'Stop'

function Normalize-FileSystemPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    try {
        $fullPath = [System.IO.Path]::GetFullPath($Path)
    }
    catch {
        $fullPath = $Path
    }

    if ($fullPath.Length -gt 3) {
        $fullPath = $fullPath.TrimEnd('\')
    }

    return $fullPath.ToLowerInvariant()
}

function Get-UniquePathList {
    param(
        [string[]]$InputPaths
    )

    $seen = @{}
    $result = New-Object System.Collections.Generic.List[string]

    foreach ($path in $InputPaths) {
        if ([string]::IsNullOrWhiteSpace($path)) {
            continue
        }

        $key = Normalize-FileSystemPath -Path $path
        if (-not $seen.ContainsKey($key)) {
            $seen[$key] = $true
            $result.Add($path) | Out-Null
        }
    }

    return $result.ToArray()
}

function Get-MatchingExplorerSelection {
    param(
        [string[]]$TriggerPaths
    )

    $triggerKeys = @{}
    foreach ($path in $TriggerPaths) {
        if ([string]::IsNullOrWhiteSpace($path)) {
            continue
        }

        $triggerKeys[(Normalize-FileSystemPath -Path $path)] = $true
    }

    if ($triggerKeys.Count -eq 0) {
        return @()
    }

    try {
        $shell = New-Object -ComObject Shell.Application
    }
    catch {
        return @()
    }

    foreach ($window in @($shell.Windows())) {
        try {
            $selectedItems = $window.Document.SelectedItems()
        }
        catch {
            continue
        }

        if ($null -eq $selectedItems -or $selectedItems.Count -eq 0) {
            continue
        }

        $selectedPaths = New-Object System.Collections.Generic.List[string]
        foreach ($item in $selectedItems) {
            if ($null -eq $item -or [string]::IsNullOrWhiteSpace($item.Path)) {
                continue
            }

            $selectedPaths.Add([string]$item.Path) | Out-Null
        }

        if ($selectedPaths.Count -eq 0) {
            continue
        }

        foreach ($selectedPath in $selectedPaths) {
            $selectedKey = Normalize-FileSystemPath -Path $selectedPath
            if ($triggerKeys.ContainsKey($selectedKey)) {
                return Get-UniquePathList -InputPaths $selectedPaths.ToArray()
            }
        }
    }

    return @()
}

function Convert-PathToText {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Name', 'FullPath')]
        [string]$Mode
    )

    switch ($Mode) {
        'Name' {
            $trimmedPath = $Path.TrimEnd('\')
            $name = [System.IO.Path]::GetFileName($trimmedPath)
            if ([string]::IsNullOrEmpty($name)) {
                return $Path
            }

            return $name
        }
        'FullPath' {
            return $Path
        }
    }
}

function Set-TextToClipboard {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text
    )

    $lastError = $null

    try {
        Add-Type -AssemblyName System.Windows.Forms

        for ($attempt = 1; $attempt -le 5; $attempt++) {
            try {
                [System.Windows.Forms.Clipboard]::SetText($Text)
                return
            }
            catch {
                $lastError = $_
                Start-Sleep -Milliseconds 120
            }
        }
    }
    catch {
        $lastError = $_
    }

    try {
        Set-Clipboard -Value $Text
        return
    }
    catch {
        $lastError = $_
    }

    throw "Failed to write to the clipboard: $($lastError.Exception.Message)"
}

$inputPaths = Get-UniquePathList -InputPaths $Paths
$effectivePaths = $inputPaths

if ($UseExplorerSelection) {
    $explorerSelection = Get-MatchingExplorerSelection -TriggerPaths $inputPaths
    if ($explorerSelection.Count -gt 0) {
        $effectivePaths = $explorerSelection
    }
}

$items = foreach ($path in $effectivePaths) {
    if ([string]::IsNullOrWhiteSpace($path)) {
        continue
    }

    Convert-PathToText -Path $path -Mode $Mode
}

$text = ($items | Where-Object { -not [string]::IsNullOrEmpty($_) }) -join "`r`n"

if ($PassThru) {
    $text
    exit 0
}

if ($text.Length -gt 0) {
    Set-TextToClipboard -Text $text
}
