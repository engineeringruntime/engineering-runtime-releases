#requires -Version 7.0
<#
.SYNOPSIS
Install a checksum-verified published engrt.exe on native Windows x64 or Arm64.
.DESCRIPTION
Public downloads are the default. For private release access, use -GitHubCLI
with an already authenticated gh installation; no token parameter is accepted.
Offline installation accepts -ArchiveDirectory with the ZIP and SHA256SUMS.txt.
Only engrt.exe is installed. Runtime Home, governance and old runtime.exe stay intact.
.EXAMPLE
./install.ps1 -Version v0.10.0 -GitHubCLI
.EXAMPLE
./install.ps1 -Version v0.10.0 -InstallDirectory C:\Tools\engrt
#>
[CmdletBinding()]
param(
    [string]$Version = $env:VERSION,
    [string]$InstallDirectory = $env:INSTALL_DIR,
    [switch]$GitHubCLI,
    [string]$ArchiveDirectory
)

function Install-Engrt {
    [CmdletBinding()]
    param([string]$Version, [string]$InstallDirectory, [switch]$GitHubCLI, [string]$ArchiveDirectory)
    $ErrorActionPreference = 'Stop'
    Set-StrictMode -Version Latest
    if (-not $IsWindows) { throw 'install.ps1 requires native Windows and PowerShell 7 or later.' }
    $architecture = switch ([Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString()) {
        'X64' { 'amd64' }
        'Arm64' { 'arm64' }
        default { throw 'Supported Windows architectures are x64 and Arm64.' }
    }
    $repo = 'engineeringruntime/engineering-runtime-releases'
    $scratch = $null
    $stage = $null
    $zip = $null
    try {
        if ($GitHubCLI) {
            $ghCommand = Get-Command gh -CommandType Application -ErrorAction SilentlyContinue
            if ($null -eq $ghCommand) { throw 'Authenticated downloads require GitHub CLI (gh).' }
            $ghPath = $ghCommand.Source
        }
        if ([string]::IsNullOrWhiteSpace($Version)) {
            if ($ArchiveDirectory) { throw 'Offline installation requires -Version.' }
            if ($GitHubCLI) {
                $latest = & $ghPath api "repos/$repo/releases/latest" --jq .tag_name
                if ($LASTEXITCODE -ne 0) { throw 'Could not resolve Latest through GitHub CLI. Check repository access.' }
                $Version = [string]$latest
            } else {
                try { $Version = [string](Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/releases/latest").tag_name }
                catch { throw 'Could not resolve Latest. Public access is required; for private access use -GitHubCLI.' }
            }
        }
        # This installer owns the engrt layout, never pre-0.10 runtime archives.
        if ($Version -cnotmatch '^v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$') { throw 'Version must be a stable tag such as v0.10.0.' }
        $parts = $Version.Substring(1).Split('.')
        if ($parts[0] -eq '0' -and ([System.Numerics.BigInteger]::Parse($parts[1])) -lt 10) {
            throw 'This installer supports v0.10.0 and later. Older runtime releases require separate manual installation and Home.'
        }
        $package = "engrt-$Version-windows-$architecture"
        $archiveName = "$package.zip"
        if ($ArchiveDirectory) {
            $directory = (Resolve-Path -LiteralPath $ArchiveDirectory).Path
        } else {
            $scratch = Join-Path ([IO.Path]::GetTempPath()) ('engrt-download-' + [guid]::NewGuid().ToString('N'))
            [IO.Directory]::CreateDirectory($scratch) | Out-Null
            $directory = $scratch
            if ($GitHubCLI) {
                & $ghPath release download $Version -R $repo --pattern $archiveName --pattern SHA256SUMS.txt --dir $directory
                if ($LASTEXITCODE -ne 0) { throw 'Release download failed. Check version, architecture and repository access.' }
            } else {
                $base = "https://github.com/$repo/releases/download/$Version"
                try {
                    Invoke-WebRequest -Uri "$base/$archiveName" -OutFile (Join-Path $directory $archiveName)
                    Invoke-WebRequest -Uri "$base/SHA256SUMS.txt" -OutFile (Join-Path $directory 'SHA256SUMS.txt')
                } catch { throw 'Release download failed. Public access is required; for private access use -GitHubCLI.' }
            }
        }
        $archive = Join-Path $directory $archiveName
        $manifest = Join-Path $directory 'SHA256SUMS.txt'
        foreach ($file in @($archive, $manifest)) {
            $item = Get-Item -LiteralPath $file
            if ($item.PSIsContainer -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Release inputs must be regular files.' }
        }
        $entries = @(Get-Content -LiteralPath $manifest | Where-Object {
            $_ -match ('(^|\s)\*?' + [regex]::Escape($archiveName) + '$')
        })
        if ($entries.Count -ne 1 -or $entries[0] -cnotmatch ('^[0-9a-fA-F]{64} [ *]' + [regex]::Escape($archiveName) + '$')) {
            throw 'Archive checksum entry is missing, invalid or ambiguous. Nothing installed.'
        }
        $expectedHash = $entries[0].Substring(0, 64)
        if ((Get-FileHash -Algorithm SHA256 -LiteralPath $archive).Hash -ine $expectedHash) { throw 'Archive checksum mismatch. Nothing installed.' }

        # Never Expand-Archive untrusted paths: inspect all members, stream one executable.
        $zip = [IO.Compression.ZipFile]::OpenRead($archive)
        $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
        $binaryEntry = $null
        foreach ($entry in $zip.Entries) {
            $path = $entry.FullName
            if (-not $path.StartsWith("$package/", [StringComparison]::Ordinal) -or
                $path -match '(^/|\\|(^|/)\.\.?(/|$)|:)' -or -not $seen.Add($path)) { throw 'Unsafe or duplicate ZIP member. Nothing installed.' }
            $type = ($entry.ExternalAttributes -shr 16) -band 0xf000
            if ($type -notin @(0, 0x8000, 0x4000) -or ($entry.ExternalAttributes -band 0x400)) { throw 'Non-regular ZIP member. Nothing installed.' }
            if ($path -ceq "$package/engrt.exe") {
                if ($type -eq 0x4000 -or $entry.Length -eq 0 -or $entry.Length -gt 268435456) { throw 'Invalid executable member.' }
                $binaryEntry = $entry
            }
        }
        if ($null -eq $binaryEntry) { throw 'Missing exact engrt.exe member. Nothing installed.' }
        if ([string]::IsNullOrWhiteSpace($InstallDirectory)) { $InstallDirectory = Join-Path $HOME '.local\bin' }
        $InstallDirectory = [IO.Path]::GetFullPath($InstallDirectory)
        # Do not follow junctions/symlinks through an installation directory.
        $ancestor = $InstallDirectory
        while ($ancestor) {
            if (Test-Path -LiteralPath $ancestor) {
                if ((Get-Item -LiteralPath $ancestor -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Installation path must not traverse a reparse point.' }
            }
            $parent = [IO.Path]::GetDirectoryName($ancestor)
            if ($parent -eq $ancestor) { break }
            $ancestor = $parent
        }
        $target = Join-Path $InstallDirectory 'engrt.exe'
        if (Test-Path -LiteralPath $target) {
            $existing = Get-Item -LiteralPath $target -Force
            if ($existing.PSIsContainer -or ($existing.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Existing engrt.exe must be a regular file.' }
        }
        [IO.Directory]::CreateDirectory($InstallDirectory) | Out-Null
        $stage = Join-Path $InstallDirectory ('.engrt-install-' + [guid]::NewGuid().ToString('N'))
        [IO.Directory]::CreateDirectory($stage) | Out-Null
        $staged = Join-Path $stage 'engrt.exe'
        $inputStream = $binaryEntry.Open()
        try {
            $outputStream = [IO.File]::Open($staged, [IO.FileMode]::CreateNew)
            try { $inputStream.CopyTo($outputStream); $outputStream.Flush($true) } finally { $outputStream.Dispose() }
        } finally { $inputStream.Dispose() }
        # Probe only in a disposable Home: version itself bootstraps contracts.
        $savedHome = [Environment]::GetEnvironmentVariable('ENGRT_HOME', 'Process')
        try {
            $env:ENGRT_HOME = Join-Path $stage 'probe-home'
            $reported = & $staged version
            if ($LASTEXITCODE -ne 0 -or $reported -cne "engrt $($Version.Substring(1))") { throw 'Executable version mismatch. Existing installation preserved.' }
        } finally {
            [Environment]::SetEnvironmentVariable('ENGRT_HOME', $savedHome, 'Process')
        }
        # Same-volume replacement occurs only after every admission and execution check.
        [IO.File]::Move($staged, $target, $true)
        Write-Output "Installed engrt $($Version.Substring(1)) ($architecture) at $target"
        Write-Output "Add $InstallDirectory to your user PATH if needed, then run: engrt version"
    } finally {
        if ($null -ne $zip) { $zip.Dispose() }
        if ($null -ne $stage -and (Test-Path -LiteralPath $stage)) { Remove-Item -LiteralPath $stage -Recurse -Force }
        if ($null -ne $scratch -and (Test-Path -LiteralPath $scratch)) { Remove-Item -LiteralPath $scratch -Recurse -Force }
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    Install-Engrt -Version $Version -InstallDirectory $InstallDirectory -GitHubCLI:$GitHubCLI -ArchiveDirectory $ArchiveDirectory
}
