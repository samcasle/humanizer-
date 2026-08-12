#Requires -Version 5.1
<#
.SYNOPSIS
    Install the two-pass humanizer pipeline into your agent's skills directory.

.DESCRIPTION
    Pass 1 is this repo's own humanizer (SKILL.md at the repo root).
    Pass 2 is structural-humanizer, vendored from NulightJens/humanizer-stack.

    This installs copies, not symlinks. Windows checks out git symlinks as plain
    text stubs unless Developer Mode is on, so .claude\skills\humanizer\SKILL.md
    may be a stub in your working tree. This script always reads the real
    SKILL.md at the repo root instead, so that does not matter.

.PARAMETER Project
    Install into .\.claude\skills of the current directory instead of the user
    profile.

.PARAMETER Force
    Replace an existing install. The previous one is renamed, not deleted.

.EXAMPLE
    .\install.ps1

.EXAMPLE
    .\install.ps1 -Force
#>
[CmdletBinding()]
param(
    [switch]$Project,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

$Repo = $PSScriptRoot
if (-not $Repo) { $Repo = (Get-Location).Path }

if ($Project) {
    $Target = Join-Path (Get-Location).Path '.claude\skills'
} else {
    $Target = Join-Path $env:USERPROFILE '.claude\skills'
}

# Sanity check: are we actually in the repo?
$RootSkill = Join-Path $Repo 'SKILL.md'
$Structural = Join-Path $Repo '.claude\skills\structural-humanizer'
$CopyTells = Join-Path $Repo '.claude\skills\humanizer\references\copy-tells.md'

if (-not (Test-Path $RootSkill)) {
    throw "SKILL.md not found at $RootSkill. Run this from inside the humanizer- repo."
}
if (-not (Test-Path $Structural)) {
    throw @"
structural-humanizer not found at $Structural.

You are probably on the main branch, which does not have it yet. Either merge
pull request #1, or check out the branch:

    git checkout claude/humanizer-stack-setup-8ivx2j
"@
}

if ($Target -eq (Join-Path $Repo '.claude\skills')) {
    throw "That is where the skills already live; nothing to do."
}

New-Item -ItemType Directory -Path $Target -Force | Out-Null
Write-Host "installing into $Target"

foreach ($skill in @('humanizer', 'structural-humanizer')) {
    $dst = Join-Path $Target $skill

    if (Test-Path $dst) {
        if (-not $Force) {
            Write-Host "  SKIP $skill : already exists at $dst"
            Write-Host "       re-run with -Force to replace it (a backup is kept)"
            continue
        }
        $backup = "$dst.bak.$(Get-Date -Format 'yyyyMMddHHmmss')"
        Move-Item -Path $dst -Destination $backup
        Write-Host "  backed up existing $skill to $(Split-Path $backup -Leaf)"
    }

    New-Item -ItemType Directory -Path $dst -Force | Out-Null

    if ($skill -eq 'humanizer') {
        # Read the real root SKILL.md, never the symlink stub.
        Copy-Item -Path $RootSkill -Destination (Join-Path $dst 'SKILL.md') -Force
        $refs = Join-Path $dst 'references'
        New-Item -ItemType Directory -Path $refs -Force | Out-Null
        Copy-Item -Path $CopyTells -Destination $refs -Force
    }
    else {
        Copy-Item -Path (Join-Path $Structural '*') -Destination $dst -Recurse -Force
    }

    Write-Host "  installed $skill"
}

# Verify the humanizer SKILL.md is the real file and not a symlink stub.
$installed = Join-Path $Target 'humanizer\SKILL.md'
if (Test-Path $installed) {
    if ((Get-Item $installed).Length -lt 1000) {
        Write-Warning "humanizer\SKILL.md looks too small. Check that $RootSkill is the real file."
    }
}

Write-Host ""
Write-Host "done. verify with:"
Write-Host "  Get-ChildItem '$Target'"
Write-Host ""
Write-Host "run the scanners:"
Write-Host "  python3 '$(Join-Path $Repo 'scripts\copy_scan.py')' <file>"
Write-Host "  python3 '$(Join-Path $Target 'structural-humanizer\scripts\structural_scan.py')' <file>"
Write-Host ""
Write-Host "then restart Claude Code so the skills load."
