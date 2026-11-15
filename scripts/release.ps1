# Prepares a release: sets the version in both TOC files, commits that change, and creates the tag.
# Pushing the tag makes GitHub package the addon and upload it to CurseForge
# (.github/workflows/release.yml).
#
#   powershell -File scripts/release.ps1 -Version 1.0.1         # prepare, then push from Sourcetree
#   powershell -File scripts/release.ps1 -Version 1.0.1 -Push   # prepare and push
#
# A version containing "beta" or "alpha" (for example 1.1.0-beta1) is uploaded as a beta or alpha file,
# any other version as a release. CHANGELOG.md needs a section for the version first, "## 1.0.1 (date)":
# it becomes the changelog of the CurseForge file. A beta may use the section of its final version
# (1.1.0-beta1 can use "## 1.1.0").
param(
    [Parameter(Mandatory)][string]$Version,
    [switch]$Push
)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

function Invoke-Git {
    $output = & git -C $root @args
    if ($LASTEXITCODE -ne 0) { throw "git $($args -join ' ') failed (exit code $LASTEXITCODE)" }
    $output
}

if ($Version -notmatch '^\d+\.\d+\.\d+(-(alpha|beta)\d*)?$') {
    throw "The version must look like 1.2.3, 1.2.3-beta1 or 1.2.3-alpha1, not '$Version'."
}
$baseVersion = $Version -replace '-.*$', ''

$branch = Invoke-Git rev-parse --abbrev-ref HEAD
if ($branch -ne 'main') { throw "Releases are made from main. The current branch is $branch." }
if (Invoke-Git status --porcelain) { throw 'The working tree has uncommitted changes. Commit or discard them first.' }
if (Invoke-Git tag --list $Version) { throw "The tag $Version already exists." }

$changelog = [System.IO.File]::ReadAllText((Join-Path $root 'CHANGELOG.md'))
$sectionFound = $false
foreach ($candidate in @($Version, $baseVersion) | Select-Object -Unique) {
    if ($changelog -match "(?m)^## $([regex]::Escape($candidate))(\s|$)") { $sectionFound = $true }
}
if (-not $sectionFound) {
    throw "CHANGELOG.md has no '## $Version' section. Add one first: it becomes the changelog of the CurseForge file."
}

# Rewrite only the "## Version:" line, keeping the files' encoding (UTF-8 without BOM) and line endings.
$utf8 = New-Object System.Text.UTF8Encoding $false
foreach ($toc in 'Kong\Kong.toc', 'KongConfig\KongConfig.toc') {
    $path = Join-Path $root $toc
    $text = [System.IO.File]::ReadAllText($path)
    if ($text -notmatch '(?m)^## Version:') { throw "No '## Version:' line in $toc." }
    $text = [regex]::Replace($text, '(?m)^(## Version:[ \t]*)[^\r\n]*', "`${1}$Version")
    [System.IO.File]::WriteAllText($path, $text, $utf8)
}

Invoke-Git add -- Kong/Kong.toc KongConfig/KongConfig.toc | Out-Null
if (Invoke-Git status --porcelain) {
    Invoke-Git commit -q -m "Release $Version" | Out-Null
}
Invoke-Git tag -a $Version -m "Kong UI Hider - Forever $Version" | Out-Null
Write-Output "Tagged $Version on $(Invoke-Git rev-parse --short HEAD)."

if ($Push) {
    Invoke-Git push origin main | Out-Null
    Invoke-Git push origin $Version | Out-Null
    Write-Output "Pushed. GitHub is now packaging $($Version): follow it in the repository's Actions tab."
} else {
    Write-Output "Ready. Push the main branch and the tag to publish it (Sourcetree: Push, with 'Push all tags' ticked)."
}
