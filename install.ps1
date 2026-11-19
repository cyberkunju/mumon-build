# Install the mumon program on Windows, then the Mumon browser.
#
#   irm https://raw.githubusercontent.com/cyberkunju/mumon-build/main/install.ps1 | iex
#
# Downloads the newest mumon program (mumon-cli-windows-x86_64.exe, from this
# repository's releases) to %LOCALAPPDATA%\mumon\bin, puts that folder on the
# user's PATH, and runs `mumon install` when a package key is set
# (MUMON_PACKAGE_KEY, or package.key in %LOCALAPPDATA%\mumon\mumon).

$ErrorActionPreference = "Stop"
$repo = "cyberkunju/mumon-build"
$asset = "mumon-cli-windows-x86_64.exe"
if ([Environment]::Is64BitOperatingSystem -eq $false -or $env:PROCESSOR_ARCHITECTURE -eq "ARM64") {
    throw "mumon is built for 64-bit x86 Windows only"
}

$releases = Invoke-RestMethod -Headers @{ "User-Agent" = "mumon-install"; "Accept" = "application/vnd.github+json" } `
    -Uri "https://api.github.com/repos/$repo/releases?per_page=30"
$best = $null
foreach ($rel in $releases) {
    if ($rel.draft -or $rel.tag_name -notmatch '^build-(\d+)-') { continue }
    $n = [int]$Matches[1]
    $a = $rel.assets | Where-Object { $_.name -eq $asset -and $_.state -eq "uploaded" } | Select-Object -First 1
    if ($a -and (-not $best -or $n -gt $best.n)) { $best = @{ n = $n; tag = $rel.tag_name; url = $a.browser_download_url } }
}
if (-not $best) { throw "no published mumon program ($asset) in $repo" }

$bin = Join-Path $env:LOCALAPPDATA "mumon\bin"
New-Item -ItemType Directory -Force -Path $bin | Out-Null
$exe = Join-Path $bin "mumon.exe"
Write-Host "downloading the mumon program from $($best.tag)"
Invoke-WebRequest -UseBasicParsing -Headers @{ "User-Agent" = "mumon-install" } -Uri $best.url -OutFile "$exe.part"
Move-Item -Force "$exe.part" $exe

$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if (-not (($userPath -split ";") -contains $bin)) {
    [Environment]::SetEnvironmentVariable("Path", (($userPath.TrimEnd(";"), $bin) -join ";").TrimStart(";"), "User")
    Write-Host "added $bin to your PATH (new terminals see it)"
}
$env:Path = "$bin;$env:Path"

$keyFile = Join-Path $env:LOCALAPPDATA "mumon\mumon\package.key"
if ($env:MUMON_PACKAGE_KEY -or (Test-Path $keyFile)) {
    & $exe install
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    Write-Host "done: try  mumon verify"
} else {
    Write-Host "mumon is installed. Put the package key in $keyFile (or MUMON_PACKAGE_KEY), then run: mumon install"
}
