param(
    [int]$BackendPort = 8000,
    [int]$FrontendPort = 5173,
    [int]$TimeoutSeconds = 90
)

$deadline = (Get-Date).AddSeconds($TimeoutSeconds)
$backendReady = $false
$frontendReady = $false

function Test-TcpPort([int]$Port) {
    $client = [System.Net.Sockets.TcpClient]::new()
    try {
        $task = $client.BeginConnect("127.0.0.1", $Port, $null, $null)
        if (-not $task.AsyncWaitHandle.WaitOne(350)) { return $false }
        $client.EndConnect($task)
        return $true
    } catch {
        return $false
    } finally {
        $client.Dispose()
    }
}

while ((Get-Date) -lt $deadline) {
    if (-not $backendReady -and (Test-TcpPort $BackendPort)) {
        try {
            $response = Invoke-WebRequest -UseBasicParsing -Uri "http://127.0.0.1:$BackendPort/health" -TimeoutSec 2
            if ($response.StatusCode -ge 200 -and $response.StatusCode -lt 500) {
                $backendReady = $true
            }
        } catch {
            # Keep waiting; app startup/imports may still be running.
        }
    }

    if (-not $frontendReady -and (Test-TcpPort $FrontendPort)) {
        try {
            $response = Invoke-WebRequest -UseBasicParsing -Uri "http://127.0.0.1:$FrontendPort/" -TimeoutSec 2
            if ($response.StatusCode -ge 200 -and $response.StatusCode -lt 400) {
                $frontendReady = $true
            }
        } catch {
            # Keep waiting for Vite to finish starting.
        }
    }

    if ($backendReady -and $frontendReady) {
        Write-Host "       Backend ready. Frontend ready."
        exit 0
    }
    Start-Sleep -Milliseconds 500
}

Write-Host "       Timed out waiting for services. Backend=$backendReady Frontend=$frontendReady"
exit 1
