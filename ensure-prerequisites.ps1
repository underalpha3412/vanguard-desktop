param(
    [switch]$NeedPython,
    [switch]$NeedNode
)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

function Test-Internet {
    foreach ($uri in @("https://www.python.org", "https://nodejs.org")) {
        try {
            $r = Invoke-WebRequest -UseBasicParsing -Uri $uri -TimeoutSec 10
            if ($r.StatusCode -ge 200 -and $r.StatusCode -lt 500) { return $true }
        } catch {}
    }
    return $false
}

function Get-LatestPython312 {
    $html = (Invoke-WebRequest -UseBasicParsing -Uri "https://www.python.org/ftp/python/" -TimeoutSec 20).Content
    $versions = [regex]::Matches($html, 'href="(3\.12\.\d+)/"') | ForEach-Object { [version]$_.Groups[1].Value }
    if (-not $versions) { throw "Could not determine the latest Python 3.12 maintenance release from python.org." }
    return ($versions | Sort-Object -Descending | Select-Object -First 1).ToString()
}

function Install-Python {
    Write-Host "  - Getting the current Python 3.12 installer from python.org..."
    $version = Get-LatestPython312
    $installer = Join-Path $env:TEMP "vanguard-python-$version.exe"
    $url = "https://www.python.org/ftp/python/$version/python-$version-amd64.exe"
    Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $installer -TimeoutSec 120
    Write-Host "  - Installing Python for the current Windows user..."
    $p = Start-Process -FilePath $installer -ArgumentList @("/quiet","InstallAllUsers=0","PrependPath=1","Include_launcher=1","Include_pip=1","Include_test=0","Shortcuts=0") -Wait -PassThru
    if ($p.ExitCode -notin @(0,3010)) { throw "Python installer exited with code $($p.ExitCode)." }
}

function Install-PortableNode {
    Write-Host "  - Getting the current Node.js LTS portable package from nodejs.org..."
    $index = Invoke-RestMethod -Uri "https://nodejs.org/dist/index.json" -TimeoutSec 30
    $release = $index | Where-Object { $_.lts -and $_.files -contains "win-x64-zip" } | Select-Object -First 1
    if (-not $release) { throw "Could not find a supported Node.js LTS Windows x64 release." }
    $version = $release.version
    $runtimeRoot = Join-Path $PSScriptRoot "runtimes"
    $nodeDir = Join-Path $runtimeRoot "node"
    $zipPath = Join-Path $env:TEMP "vanguard-node-$version.zip"
    New-Item -ItemType Directory -Path $runtimeRoot -Force | Out-Null
    Invoke-WebRequest -UseBasicParsing -Uri "https://nodejs.org/dist/$version/node-$version-win-x64.zip" -OutFile $zipPath -TimeoutSec 180
    $extract = Join-Path $env:TEMP ("vanguard-node-" + [guid]::NewGuid().ToString("N"))
    Expand-Archive -LiteralPath $zipPath -DestinationPath $extract -Force
    $folder = Get-ChildItem -LiteralPath $extract -Directory | Select-Object -First 1
    if (-not $folder -or -not (Test-Path (Join-Path $folder.FullName "node.exe"))) { throw "Downloaded Node.js archive is incomplete." }
    if (Test-Path $nodeDir) { Remove-Item $nodeDir -Recurse -Force }
    Move-Item -LiteralPath $folder.FullName -Destination $nodeDir
    Remove-Item $extract -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
    $env:Path = "$nodeDir;$env:Path"
}

Write-Host ""
Write-Host "Checking internet before downloading required software..."
if (-not (Test-Internet)) {
    Write-Host "[ERROR] No internet connection. Setup has been stopped before downloading."
    exit 10
}

try {
    if ($NeedPython) {
        Write-Host "[1/2] Installing Python 3.12..."
        Install-Python
    }
    if ($NeedNode) {
        Write-Host "[2/2] Installing Node.js LTS (portable, inside Vanguard folder)..."
        Install-PortableNode
    }

    # Refresh this PowerShell process from updated Windows PATH and known install locations.
    $machinePath = [Environment]::GetEnvironmentVariable("Path","Machine")
    $userPath = [Environment]::GetEnvironmentVariable("Path","User")
    $env:Path = "$machinePath;$userPath;$env:Path"
    $local = [Environment]::GetFolderPath("LocalApplicationData")
    $env:Path += ";$local\Programs\Python\Python312;$local\Programs\Python\Python312\Scripts;$local\Programs\Python\Launcher"
    $env:Path += ";$PSScriptRoot\runtimes\node"

    if ($NeedPython) {
        $pythonOk = $false
        foreach ($candidate in @(
            (Join-Path $local "Programs\Python\Python312\python.exe"),
            (Join-Path $local "Programs\Python\Python313\python.exe"),
            (Join-Path $local "Programs\Python\Python314\python.exe")
        )) {
            if (Test-Path $candidate) {
                & $candidate -c "import sys; raise SystemExit(0 if sys.version_info >= (3,10) else 1)"
                if ($LASTEXITCODE -eq 0) { $pythonOk = $true; break }
            }
        }
        if (-not $pythonOk) {
            $py = Get-Command py.exe -ErrorAction SilentlyContinue
            if ($py) { & $py.Source -3.12 -c "import sys; raise SystemExit(0 if sys.version_info >= (3,10) else 1)"; $pythonOk = ($LASTEXITCODE -eq 0) }
        }
        if (-not $pythonOk) { throw "Python installer finished, but a working Python 3.10+ interpreter could not be verified. Sign out/in or restart Windows, then run setup.bat again." }
    }

    if ($NeedNode) {
        $nodeExe = Join-Path $PSScriptRoot "runtimes\node\node.exe"
        if (-not (Test-Path $nodeExe)) { throw "Node.js portable installation did not create runtimes\node\node.exe." }
        & $nodeExe -e "process.exit(parseInt(process.versions.node.split('.')[0],10)>=20?0:1)"
        if ($LASTEXITCODE -ne 0) { throw "Installed Node.js is older than version 20." }
    }

    Write-Host "Required software installation and verification completed."
    exit 0
} catch {
    Write-Host "[ERROR] $($_.Exception.Message)"
    exit 20
}
