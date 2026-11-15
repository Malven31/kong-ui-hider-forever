# Builds the upload-ready zip in dist/: the Kong and KongConfig folders at the root of the archive,
# named after the version in Kong.toc. Entries use forward slashes, which Compress-Archive on
# PowerShell 5.1 does not guarantee.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$dist = Join-Path $root 'dist'
$folders = @('Kong', 'KongConfig')
New-Item -ItemType Directory -Force $dist | Out-Null

$toc = Join-Path $root 'Kong\Kong.toc'
$line = Select-String -LiteralPath $toc -Pattern '^##\s*Version:\s*(.+?)\s*$' | Select-Object -First 1
if (-not $line) { throw "No ## Version line in $toc" }
$version = $line.Matches[0].Groups[1].Value

$zipPath = Join-Path $dist "KongUIHider-Forever-$version.zip"
if (Test-Path -LiteralPath $zipPath) { Remove-Item -LiteralPath $zipPath -Confirm:$false }

$zip = [System.IO.Compression.ZipFile]::Open($zipPath, [System.IO.Compression.ZipArchiveMode]::Create)
try {
    $count = 0
    foreach ($folder in $folders) {
        $base = Join-Path $root $folder
        foreach ($file in Get-ChildItem -LiteralPath $base -Recurse -File) {
            $entry = $folder + '/' + $file.FullName.Substring($base.Length + 1).Replace('\', '/')
            [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $file.FullName, $entry) | Out-Null
            $count++
        }
    }
} finally {
    $zip.Dispose()
}
Write-Output "$zipPath ($count files)"
