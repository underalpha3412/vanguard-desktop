param(
    [switch]$NeedPython,
    [switch]$NeedNode
)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$installerDir = Join-Path $PSScriptRoot "installers"
$pythonInstallerName = "python-3.15.2-amd64.exe"
$nodeInstallerName = "node-v26.13.1-x64.msi"
$pythonUrl = "https://www.python.org/ftp/python/3.15.2/python-3.15.2-amd64.exe"
$nodeUrl = "https://nodejs.org/dist/v26.13.1/node-v26.13.1-x64.msi"

function Test-Internet {
    foreach ($uri in @("https://www.python.org", "https://nodejs.org")) {
        try {
            $r = Invoke-WebRequest -UseBasicParsing -Uri $uri -TimeoutSec 10
            if ($r.StatusCode -ge 200 -and $r.StatusCode -lt 500) { return $true }
        } catch {}
    }
    return $false
}

function Get-Installer([string]$Name, [string]$Url) {
    New-Item -ItemType Directory -Path $installerDir -Force | Out-Null
    $path = Join-Path $installerDir $Name
    if (Test-Path $path) {
        Write-Host "  - Found bundled installer: $Name"
    } else {
        Write-Host "  - Bundled $Name is missing. Downloading official installer..."
        if (-not (Test-Internet)) {
            throw "Internet is unavailable and $Name is not present in the installers folder. Setup cannot continue."
        }
        Invoke-WebRequest -UseBasicParsing -Uri $Url -OutFile $path -TimeoutSec 300
    }
    if (-not (Test-Path $path) -or (Get-Item $path).Length -lt 1000000) {
        throw "Installer $Name is missing or appears incomplete."
    }
    $sig = Get-AuthenticodeSignature -FilePath $path
    if ($sig.Status -ne "Valid") {
        throw "Authenticode signature check failed for $Name ($($sig.Status)). Delete it and run setup again."
    }
    return $path
}

function Install-Python {
    $installer = Get-Installer $pythonInstallerName $pythonUrl
    $pythonDir = Join-Path $PSScriptRoot "runtimes\python"
    New-Item -ItemType Directory -Path $pythonDir -Force | Out-Null
    Write-Host "  - Installing Python into Vanguard's local runtimes\python folder..."
    $args = @("/quiet","InstallAllUsers=0","TargetDir=$pythonDir","PrependPath=0","Include_launcher=0","Include_pip=1","Include_test=0","Shortcuts=0")
    $p = Start-Process -FilePath $installer -ArgumentList $args -Wait -PassThru
    if ($p.ExitCode -notin @(0,3010)) { throw "Python installer exited with code $($p.ExitCode)." }
    $localPython = Join-Path $pythonDir "python.exe"
    if (-not (Test-Path $localPython)) { throw "Python installer finished but runtimes\python\python.exe was not created." }
    & $localPython -c "import sys; raise SystemExit(0 if sys.version_info >= (3,10) else 1)"
    if ($LASTEXITCODE -ne 0) { throw "Vanguard-local Python failed its version check." }
}

function Install-Node {
    $installer = Get-Installer $nodeInstallerName $nodeUrl
    $nodeDir = Join-Path $PSScriptRoot "runtimes\node"
    New-Item -ItemType Directory -Path $nodeDir -Force | Out-Null
    Write-Host "  - Installing Node.js into Vanguard's local runtimes\node folder..."
    $log = Join-Path $env:TEMP "vanguard-node-msi-install.log"
    $arguments = "/i `"$installer`" /qn /norestart INSTALLDIR=`"$nodeDir`" /l*v `"$log`""
    $p = Start-Process -FilePath "msiexec.exe" -ArgumentList $arguments -Wait -PassThru
    if ($p.ExitCode -notin @(0,3010)) { throw "Node.js MSI installation failed with code $($p.ExitCode). MSI log: $log" }
    $nodeExe = Join-Path $nodeDir "node.exe"
    if (-not (Test-Path $nodeExe)) {
        # Some MSI builds install under the standard machine path. Accept it if present.
        $standard = Join-Path $env:ProgramFiles "nodejs\node.exe"
        if (Test-Path $standard) { $nodeExe = $standard; $nodeDir = Split-Path $standard }
        else { throw "Node.js MSI finished but node.exe could not be found. See $log" }
    }
    & $nodeExe -e "process.exit(parseInt(process.versions.node.split('.')[0],10)>=20?0:1)"
    if ($LASTEXITCODE -ne 0) { throw "Installed Node.js is older than version 20." }
    return $nodeDir
}

try {
    if ($NeedPython -or $NeedNode) {
        Write-Host ""
        Write-Host "Checking installer files..."
        # Bundled installers work offline. Internet is required only for a missing installer.
        if ($NeedPython) { Install-Python }
        if ($NeedNode) {
            $nodeDir = Install-Node
            [Environment]::SetEnvironmentVariable("Path", "$nodeDir;$([Environment]::GetEnvironmentVariable('Path','User'))", "User")
            $env:Path = "$nodeDir;$env:Path"
        }
    }

    $localPython = Join-Path $PSScriptRoot "runtimes\python\python.exe"
    if ($NeedPython) {
        if (-not (Test-Path $localPython)) { throw "Python installation finished, but the Vanguard-local interpreter is missing." }
        & $localPython -c "import sys; raise SystemExit(0 if sys.version_info >= (3,10) else 1)"
        if ($LASTEXITCODE -ne 0) { throw "Vanguard-local Python did not pass the Python 3.10+ check." }
    }
    if ($NeedNode) {
        $nodeExe = Join-Path $PSScriptRoot "runtimes\node\node.exe"
        if (-not (Test-Path $nodeExe)) { $nodeExe = Join-Path $env:ProgramFiles "nodejs\node.exe" }
        if (-not (Test-Path $nodeExe)) { throw "Node.js installation finished, but node.exe could not be found." }
        & $nodeExe -e "process.exit(parseInt(process.versions.node.split('.')[0],10)>=20?0:1)"
        if ($LASTEXITCODE -ne 0) { throw "Installed Node.js did not pass the Node 20+ check." }
    }

    Write-Host "Required software installation and verification completed."
    exit 0
} catch {
    Write-Host "[ERROR] $($_.Exception.Message)"
    exit 20
}
