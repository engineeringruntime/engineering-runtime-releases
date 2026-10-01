#requires -Version 7.0
[CmdletBinding()]
param([Parameter(Mandatory)][string]$PublishedDirectory)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot '../install.ps1')
$arch = if ([Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString() -eq 'Arm64') { 'arm64' } else { 'amd64' }
$version = 'v0.10.0'
$package = "engrt-$version-windows-$arch"
$archiveName = "$package.zip"
$root = Join-Path ([IO.Path]::GetTempPath()) ('engrt-installer-tests-' + [guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($root) | Out-Null
$destination = Join-Path $root 'destination'
[IO.Directory]::CreateDirectory($destination) | Out-Null
$target = Join-Path $destination 'engrt.exe'
$env:ENGRT_HOME = Join-Path $root 'operator-home'
[IO.Directory]::CreateDirectory($env:ENGRT_HOME) | Out-Null
$marker = Join-Path $env:ENGRT_HOME 'preserve.txt'
Set-Content -LiteralPath $marker -Value 'operator state' -NoNewline
$markerHash = (Get-FileHash -LiteralPath $marker).Hash
$cases = [Collections.Generic.List[object]]::new()
function Assert-True([bool]$Condition, [string]$Message) { if (-not $Condition) { throw $Message } }
function Refusal([string]$Name, [scriptblock]$Action) {
    $before = (Get-FileHash -LiteralPath $target).Hash
    $homeBefore = $env:ENGRT_HOME
    $refused = $false
    try { & $Action | Out-Null } catch { $refused = $true }
    Assert-True $refused "$Name unexpectedly accepted"
    Assert-True ((Get-FileHash -LiteralPath $target).Hash -eq $before) "$Name changed existing installation"
    Assert-True ($env:ENGRT_HOME -eq $homeBefore) "$Name changed operator Home selection"
    Assert-True (@(Get-ChildItem -LiteralPath $destination -Force | Where-Object Name -like '.engrt-install-*').Count -eq 0) "$Name left partial staging"
    $cases.Add(@{name=$Name;status='passed'})
}
function Fixture([string]$Name, [string]$PackageName, [object[]]$Entries) {
    $dir = Join-Path $root $Name
    [IO.Directory]::CreateDirectory($dir) | Out-Null
    $path = Join-Path $dir "$PackageName.zip"
    $zip = [IO.Compression.ZipFile]::Open($path, [IO.Compression.ZipArchiveMode]::Create)
    try {
        foreach ($item in $Entries) {
            $entry = $zip.CreateEntry([string]$item.path)
            if ($item.ContainsKey('attributes')) { $entry.ExternalAttributes = $item.attributes }
            $stream = $entry.Open()
            try { $bytes = [byte[]]$item.bytes; $stream.Write($bytes, 0, $bytes.Length) } finally { $stream.Dispose() }
        }
    } finally { $zip.Dispose() }
    $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash.ToLowerInvariant()
    Set-Content -LiteralPath (Join-Path $dir 'SHA256SUMS.txt') -Value "$hash  $PackageName.zip"
    return $dir
}
try {
    # First use the real published native executable, not a mock or cross-architecture helper.
    Install-Engrt -Version $version -InstallDirectory $destination -ArchiveDirectory $PublishedDirectory
    $provenance = Get-Content -LiteralPath (Join-Path $PublishedDirectory 'PROVENANCE.json') -Raw | ConvertFrom-Json
    $row = @($provenance.archives | Where-Object { $_.os -eq 'windows' -and $_.arch -eq $arch })
    Assert-True ($row.Count -eq 1) 'Missing native published provenance'
    Assert-True ((Get-FileHash -Algorithm SHA256 -LiteralPath $target).Hash -ieq $row[0].binary_sha256) 'Installed binary digest mismatch'
    $cases.Add(@{name='published-native-install';status='passed'})
    Install-Engrt -Version $version -InstallDirectory $destination -ArchiveDirectory $PublishedDirectory
    $cases.Add(@{name='published-native-reinstall';status='passed'})
    $binaryBytes = [IO.File]::ReadAllBytes($target)
    $validEntry = @{path="$package/engrt.exe";bytes=$binaryBytes}
    $missing = Fixture 'missing-binary' $package @(@{path="$package/README.md";bytes=[Text.Encoding]::UTF8.GetBytes('reference')})
    Refusal 'missing-binary' { Install-Engrt -Version $version -InstallDirectory $destination -ArchiveDirectory $missing }
    foreach ($badPath in @("$package/../escape", "$package/a/../../escape", '/absolute', "$package\engrt.exe", "$package/C:escape")) {
        $dir = Fixture ('bad-path-' + $cases.Count) $package @($validEntry, @{path=$badPath;bytes=@(1)})
        Refusal 'unsafe-member' { Install-Engrt -Version $version -InstallDirectory $destination -ArchiveDirectory $dir }
    }
    $duplicate = Fixture 'duplicate-binary' $package @($validEntry, $validEntry)
    Refusal 'duplicate-binary' { Install-Engrt -Version $version -InstallDirectory $destination -ArchiveDirectory $duplicate }
    $caseDuplicate = Fixture 'case-duplicate' $package @($validEntry, @{path="$package/ENGRT.EXE";bytes=$binaryBytes})
    Refusal 'case-duplicate' { Install-Engrt -Version $version -InstallDirectory $destination -ArchiveDirectory $caseDuplicate }
    $link = Fixture 'symlink' $package @($validEntry, @{path="$package/link";bytes=@(1);attributes=-1610612736})
    Refusal 'symlink-member' { Install-Engrt -Version $version -InstallDirectory $destination -ArchiveDirectory $link }
    $mismatch = Fixture 'wrong-version' "engrt-v0.10.1-windows-$arch" @(@{path="engrt-v0.10.1-windows-$arch/engrt.exe";bytes=$binaryBytes})
    Refusal 'wrong-executable-version' { Install-Engrt -Version v0.10.1 -InstallDirectory $destination -ArchiveDirectory $mismatch }
    $invalidExe = Fixture 'invalid-exe' $package @(@{path="$package/engrt.exe";bytes=@(1,2,3)})
    Refusal 'invalid-executable' { Install-Engrt -Version $version -InstallDirectory $destination -ArchiveDirectory $invalidExe }
    $badHash = Fixture 'checksum' $package @($validEntry)
    Set-Content -LiteralPath (Join-Path $badHash 'SHA256SUMS.txt') -Value (('0' * 64) + "  $archiveName")
    Refusal 'checksum-mismatch' { Install-Engrt -Version $version -InstallDirectory $destination -ArchiveDirectory $badHash }
    $ambiguous = Fixture 'ambiguous' $package @($validEntry)
    $line = Get-Content -LiteralPath (Join-Path $ambiguous 'SHA256SUMS.txt')
    Add-Content -LiteralPath (Join-Path $ambiguous 'SHA256SUMS.txt') -Value $line
    Refusal 'duplicate-checksum' { Install-Engrt -Version $version -InstallDirectory $destination -ArchiveDirectory $ambiguous }
    Set-Content -LiteralPath (Join-Path $ambiguous 'SHA256SUMS.txt') -Value @($line, "not-a-hash  $archiveName")
    Refusal 'malformed-duplicate-checksum' { Install-Engrt -Version $version -InstallDirectory $destination -ArchiveDirectory $ambiguous }
    Refusal 'legacy-version' { Install-Engrt -Version v0.9.9 -InstallDirectory $destination -ArchiveDirectory $PublishedDirectory }
    foreach ($badVersion in @('v0.10.0-rc.1', 'v00.10.0', '../v0.10.0', '0.10.0')) {
        Refusal 'invalid-version' { Install-Engrt -Version $badVersion -InstallDirectory $destination -ArchiveDirectory $PublishedDirectory }
    }
    # A locked existing executable must survive a failed replacement and clean staging.
    $lock = [IO.File]::Open($target, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::Read)
    try { Refusal 'locked-target' { Install-Engrt -Version $version -InstallDirectory $destination -ArchiveDirectory $PublishedDirectory } }
    finally { $lock.Dispose() }
    Assert-True ((Get-FileHash -LiteralPath $marker).Hash -eq $markerHash) 'Operator Home content changed'
    Assert-True (@(Get-ChildItem -LiteralPath $env:ENGRT_HOME -Force).Count -eq 1) 'Version probe wrote to operator Home'
    $cases.Add(@{name='operator-home-preserved';status='passed'})
    # Exercise authenticated published-download transport separately, with exact same bytes.
    Install-Engrt -Version $version -InstallDirectory $destination -GitHubCLI
    Assert-True ((Get-FileHash -LiteralPath $target).Hash -ieq $row[0].binary_sha256) 'Authenticated install digest mismatch'
    $cases.Add(@{name='authenticated-published-download';status='passed'})
    # Exercise the script entry point and Latest selection, not only its function.
    & (Join-Path $PSScriptRoot '../install.ps1') -Version $version -InstallDirectory $destination -ArchiveDirectory $PublishedDirectory
    Assert-True ((Get-FileHash -LiteralPath $target).Hash -ieq $row[0].binary_sha256) 'Script entry point digest mismatch'
    $cases.Add(@{name='script-entry-point';status='passed'})
    Install-Engrt -InstallDirectory $destination -GitHubCLI
    Assert-True ((Get-FileHash -LiteralPath $target).Hash -ieq $row[0].binary_sha256) 'Latest install digest mismatch'
    $cases.Add(@{name='authenticated-latest';status='passed'})
    $report = @{status='passed';architecture=$arch;version=$version;source=$provenance.source_revision;binary_sha256=$row[0].binary_sha256;cases=$cases}
    if ($env:ENGRT_INSTALL_REPORT) { $report | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $env:ENGRT_INSTALL_REPORT }
    "Windows installer: $($cases.Count) cases PASS on native $arch"
} finally {
    Remove-Item -LiteralPath $root -Recurse -Force
}
