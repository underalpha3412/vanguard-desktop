param(
    [Parameter(Mandatory=$true)]
    [string]$EnvPath
)

$ErrorActionPreference = 'Stop'
$key = [Environment]::GetEnvironmentVariable('VANGUARD_NVIDIA_KEY', 'Process')
if ($null -eq $key) { $key = '' }
$key = $key.Trim()

# Dotenv format requires one KEY=VALUE entry per physical line.
# Use NVIDIA_MODEL (the variable read by backend/ai_backend.py), not NVIDIA_API_MODEL.
$lines = @(
    "NVIDIA_API_KEY=$key",
    "NVIDIA_MODEL=nvidia/nemotron-3.5-lightning-30b-a3b",
    "DASHBOARD_ALLOWED_ORIGINS=http://localhost:5173,http://127.0.0.1:5173",
    "MODEL_GO_PROFILE=server"
)
$directory = Split-Path -Parent $EnvPath
New-Item -ItemType Directory -Force -Path $directory | Out-Null
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllLines($EnvPath, $lines, $utf8NoBom)

# Read it back and verify every setting occupies its own line.
$written = [System.IO.File]::ReadAllLines($EnvPath)
if ($written.Count -ne 4) { throw "Expected 4 separate environment lines, found $($written.Count)." }
if (-not $written[0].StartsWith('NVIDIA_API_KEY=')) { throw 'NVIDIA_API_KEY line is missing.' }
if (-not $written[1].StartsWith('NVIDIA_MODEL=')) { throw 'NVIDIA_MODEL line is missing.' }
if ($written[2] -notlike 'DASHBOARD_ALLOWED_ORIGINS=*') { throw 'DASHBOARD_ALLOWED_ORIGINS line is missing.' }
if ($written[3] -ne 'MODEL_GO_PROFILE=server') { throw 'MODEL_GO_PROFILE line is incorrect.' }

Write-Host "Environment file written and verified: $EnvPath"
Write-Host "NVIDIA key present: $([bool]$key)"
