param(
    [switch]$NeedGit,
    [switch]$NeedPython,
    [switch]$NeedNode
)
$ErrorActionPreference = "Stop"

function Test-Internet {
    try {
        $r = Invoke-WebRequest -UseBasicParsing -Uri "https://github.com" -TimeoutSec 8
        return ($r.StatusCode -ge 200 -and $r.StatusCode -lt 500)
    } catch {
        try {
            $c = [System.Net.Sockets.TcpClient]::new()
            $a = $c.BeginConnect("1.1.1.1", 443, $null, $null)
            $ok = $a.AsyncWaitHandle.WaitOne(3000)
            if ($ok) { $c.EndConnect($a) }
            $c.Dispose()
            return $ok
        } catch { return $false }
    }
}

$missing = @()
if ($NeedGit) { $missing += "Git" }
if ($NeedPython) { $missing += "Python 3.10+" }
if ($NeedNode) { $missing += "Node.js 20+" }

if ($missing.Count -eq 0) { exit 0 }

Write-Host ""
Write-Host "Checking internet connection before installing required software..."
if (-not (Test-Internet)) {
    Write-Host ""
    Write-Host "[ERROR] No internet connection detected. Installation has been stopped."
    Write-Host "Connect to the internet and run launch.bat again."
    exit 10
}

Write-Host "Internet connection detected."
Write-Host ""
Write-Host "The following required software is missing: $($missing -join ', ')"
Write-Host "Vanguard will install it automatically using Windows Package Manager."
Write-Host "Windows may ask you to approve installation prompts."
Write-Host ""

$winget = Get-Command winget.exe -ErrorAction SilentlyContinue
if (-not $winget) {
    Write-Host "[ERROR] Windows Package Manager (winget) is not available."
    Write-Host "Install or update 'App Installer' from Microsoft Store, then run launch.bat again."
    exit 11
}

if ($NeedGit) {
    Write-Host "[1/3] Installing Git for Windows..."
    & winget install --id Git.Git --exact --silent --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) { Write-Host "[ERROR] Git installation failed."; exit 12 }
}
if ($NeedPython) {
    Write-Host "[2/3] Installing Python 3.12..."
    & winget install --id Python.Python.3.12 --exact --silent --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) { Write-Host "[ERROR] Python installation failed."; exit 13 }
}
if ($NeedNode) {
    Write-Host "[3/3] Installing Node.js LTS..."
    & winget install --id OpenJS.NodeJS.LTS --exact --silent --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) { Write-Host "[ERROR] Node.js installation failed."; exit 14 }
}

# Refresh PATH for this process. winget-installed apps commonly register these paths.
$env:Path = [Environment]::GetEnvironmentVariable("Path","Machine") + ";" +
            [Environment]::GetEnvironmentVariable("Path","User") + ";" + $env:Path
$env:Path += ";C:\Program Files\Git\cmd;C:\Program Files\nodejs"
$local = [Environment]::GetFolderPath("LocalApplicationData")
$env:Path += ";$local\Programs\Python\Python312;$local\Programs\Python\Python312\Scripts"
$env:Path += ";C:\Python312;C:\Python312\Scripts"

# Verify installations now; if PATH has not refreshed, stop clearly rather than continue broken.
if ($NeedGit -and -not (Get-Command git.exe -ErrorAction SilentlyContinue)) {
    Write-Host "[ERROR] Git installed but is not yet available in this terminal. Restart Windows or sign out/in, then run launch.bat again."
    exit 15
}
if ($NeedPython) {
    $py = Get-Command py.exe -ErrorAction SilentlyContinue
    $python = Get-Command python.exe -ErrorAction SilentlyContinue
    if (-not $py -and -not $python) {
        Write-Host "[ERROR] Python installed but is not yet available in this terminal. Restart Windows, then run launch.bat again."
        exit 16
    }
}
if ($NeedNode -and -not (Get-Command node.exe -ErrorAction SilentlyContinue)) {
    Write-Host "[ERROR] Node.js installed but is not yet available in this terminal. Restart Windows, then run launch.bat again."
    exit 17
}
Write-Host "All required software is installed."
exit 0
