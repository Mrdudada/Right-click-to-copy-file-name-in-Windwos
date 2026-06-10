#requires -Version 5.1

$ErrorActionPreference = 'Stop'

$keys = @(
    'HKCU:\Software\Classes\AllFilesystemObjects\shell\CopyFileName',
    'HKCU:\Software\Classes\AllFilesystemObjects\shell\CopyFullPath'
)

$removedCount = 0

foreach ($key in $keys) {
    if (Test-Path -LiteralPath $key) {
        Remove-Item -LiteralPath $key -Recurse -Force
        $removedCount++
    }
}

if ($removedCount -gt 0) {
    Write-Host "Uninstall completed. Removed $removedCount context menu registry entries."
}
else {
    Write-Host 'No context menu registry entries were found.'
}
