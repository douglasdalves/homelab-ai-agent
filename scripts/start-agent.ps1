$ErrorActionPreference = "Stop"

$projectDirectory = Split-Path -Parent $PSScriptRoot
$pythonPath = Join-Path $projectDirectory ".venv\Scripts\python.exe"
$agentPath = Join-Path $projectDirectory "agent\agent.py"
$environmentPath = Join-Path $projectDirectory "config\.env"
$ollamaProcess = $null
$ollamaUri = $null
$sshProcess = $null
$exitCode = 1

function Get-ConfigValue {
    param(
        [string]$Name,
        [string]$DefaultValue
    )

    $value = [Environment]::GetEnvironmentVariable($Name)
    if ($value) {
        return $value.Trim()
    }

    if (Test-Path -LiteralPath $environmentPath) {
        $pattern = '^\s*' + [regex]::Escape($Name) + '\s*=\s*(.*?)\s*$'
        foreach ($line in Get-Content -LiteralPath $environmentPath) {
            if ($line -match $pattern) {
                return $Matches[1].Trim().Trim('"').Trim("'")
            }
        }
    }

    return $DefaultValue
}

function Test-OllamaApi {
    param([string]$Uri)

    try {
        $null = Invoke-RestMethod -Uri $Uri -Method Get -TimeoutSec 2
        return $true
    }
    catch [System.Net.WebException] {
        if ($_.Exception.Response) {
            throw "A API do Ollama respondeu com erro durante a verificacao."
        }
        return $false
    }
}

function Stop-LocalOllamaServer {
    param(
        [int]$Port,
        [System.Diagnostics.Process]$StartedProcess
    )

    $serverProcessIds = @()
    if ($StartedProcess) {
        $StartedProcess.Refresh()
        if (-not $StartedProcess.HasExited) {
            $serverProcessIds += $StartedProcess.Id
        }
    }

    $listeners = Get-NetTCPConnection `
        -State Listen `
        -LocalPort $Port `
        -ErrorAction SilentlyContinue
    foreach ($listener in $listeners) {
        $serverProcessIds += [int]$listener.OwningProcess
    }

    foreach ($serverProcessId in ($serverProcessIds | Sort-Object -Unique)) {
        $serverProcess = Get-Process -Id $serverProcessId -ErrorAction SilentlyContinue
        if (-not $serverProcess) {
            continue
        }
        if ($serverProcess.ProcessName -notlike "ollama*") {
            throw "A porta local $Port pertence a '$($serverProcess.ProcessName)' (PID $serverProcessId); o processo foi mantido."
        }

        Stop-Process -Id $serverProcessId
        $serverProcess.WaitForExit()
        Write-Host "Servidor Ollama encerrado (PID $serverProcessId)."
    }
}

if (-not (Test-Path -LiteralPath $pythonPath)) {
    throw "Ambiente Python nao encontrado. Consulte docs/PROJECT.md para instalar o agente."
}

if (-not (Test-Path -LiteralPath $environmentPath)) {
    throw "Arquivo config\.env nao encontrado. Copie config\.env.example e configure SSH_TARGET."
}

$sshTarget = Get-ConfigValue -Name "SSH_TARGET" -DefaultValue ""
if (-not $sshTarget) {
    throw "SSH_TARGET nao configurado em config\.env. Use um alias SSH ou usuario@host."
}

if ($sshTarget -match '\s' -or $sshTarget.StartsWith("-")) {
    throw "SSH_TARGET deve ser um alias SSH ou usuario@host, sem espacos."
}

$sshCommand = Get-Command ssh -ErrorAction SilentlyContinue
if (-not $sshCommand) {
    throw "Cliente OpenSSH (ssh) nao encontrado no PATH."
}

$portProbe = New-Object System.Net.Sockets.TcpClient
try {
    $portProbe.Connect("127.0.0.1", 5080)
    throw "A porta local 5080 ja esta em uso. Feche o servico ou tunel existente e tente novamente."
}
catch [System.Net.Sockets.SocketException] {
}
finally {
    $portProbe.Dispose()
}

try {
    $ollamaBaseUrl = Get-ConfigValue `
        -Name "OLLAMA_BASE_URL" `
        -DefaultValue "http://127.0.0.1:11434"
    $ollamaUri = [System.Uri]$ollamaBaseUrl

    if ($ollamaUri.IsLoopback) {
        $ollamaApiUrl = $ollamaBaseUrl.TrimEnd("/") + "/api/tags"
        if (-not (Test-OllamaApi -Uri $ollamaApiUrl)) {
            $ollamaCommand = Get-Command ollama -ErrorAction SilentlyContinue
            if (-not $ollamaCommand) {
                throw "Ollama nao esta respondendo e o comando ollama nao foi encontrado no PATH."
            }

            $ollamaProcess = Start-Process `
                -FilePath $ollamaCommand.Source `
                -ArgumentList @("serve") `
                -PassThru `
                -NoNewWindow

            $ollamaDeadline = (Get-Date).AddSeconds(30)
            $ollamaReady = $false
            while ((Get-Date) -lt $ollamaDeadline) {
                $ollamaProcess.Refresh()
                if ($ollamaProcess.HasExited) {
                    throw "Ollama encerrou antes de disponibilizar a API (codigo $($ollamaProcess.ExitCode))."
                }

                if (Test-OllamaApi -Uri $ollamaApiUrl) {
                    $ollamaReady = $true
                    break
                }
                Start-Sleep -Milliseconds 500
            }

            if (-not $ollamaReady) {
                throw "A API do Ollama nao ficou disponivel dentro do tempo esperado."
            }
            Write-Host "Ollama iniciado."
        }
        else {
            Write-Host "Ollama ja esta respondendo."
        }
    }

    $sshArguments = @(
        "-N",
        "-o", "ExitOnForwardFailure=yes",
        "-L", "127.0.0.1:5080:127.0.0.1:5080",
        $sshTarget
    )
    $sshProcess = Start-Process `
        -FilePath $sshCommand.Source `
        -ArgumentList $sshArguments `
        -PassThru `
        -NoNewWindow

    $deadline = (Get-Date).AddSeconds(60)
    $tunnelReady = $false
    while ((Get-Date) -lt $deadline) {
        $sshProcess.Refresh()
        if ($sshProcess.HasExited) {
            throw "O processo SSH encerrou antes de abrir o tunel (codigo $($sshProcess.ExitCode))."
        }

        $portProbe = New-Object System.Net.Sockets.TcpClient
        try {
            $portProbe.Connect("127.0.0.1", 5080)
            $tunnelReady = $true
            break
        }
        catch [System.Net.Sockets.SocketException] {
            Start-Sleep -Milliseconds 250
        }
        finally {
            $portProbe.Dispose()
        }
    }

    if (-not $tunnelReady) {
        throw "O tunel SSH nao abriu a porta local 5080 dentro do tempo esperado."
    }

    Write-Host "Tunel SSH ativo e mantido durante a sessao. Iniciando o agente..."
    & $pythonPath $agentPath
    $exitCode = $LASTEXITCODE
}
finally {
    try {
        if ($sshProcess) {
            $sshProcess.Refresh()
            if (-not $sshProcess.HasExited) {
                Stop-Process -Id $sshProcess.Id
                $sshProcess.WaitForExit()
            }
        }
    }
    finally {
        if ($ollamaUri -and $ollamaUri.IsLoopback) {
            Stop-LocalOllamaServer -Port $ollamaUri.Port -StartedProcess $ollamaProcess
        }
    }
}

exit $exitCode
