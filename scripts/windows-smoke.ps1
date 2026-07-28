param(
    [string]$Python = "python",
    [int]$Port = 8765
)

$ErrorActionPreference = "Stop"
$token = "agentsoul-smoke-$([guid]::NewGuid().ToString('N'))"
$home = Join-Path $env:TEMP "agentsoul-smoke-$([guid]::NewGuid().ToString('N'))"
$baseUrl = "http://127.0.0.1:$Port"
$stdoutPath = Join-Path $home "server.stdout.log"
$stderrPath = Join-Path $home "server.stderr.log"
$server = $null

function Assert-True([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw "FAILED: $Message" }
    Write-Host "PASS: $Message"
}

try {
    New-Item -ItemType Directory -Path $home -Force | Out-Null

    $env:AGENTSOUL_HOME = $home
    $env:AGENTSOUL_API_TOKEN = $token
    $env:AGENTSOUL_HOST = "127.0.0.1"
    $env:AGENTSOUL_PORT = "$Port"

    $server = Start-Process -FilePath $Python `
        -ArgumentList @("-m", "agentsoul_mcp.server") `
        -PassThru -WindowStyle Hidden `
        -RedirectStandardOutput $stdoutPath `
        -RedirectStandardError $stderrPath

    $ready = $false
    for ($attempt = 0; $attempt -lt 40; $attempt++) {
        Start-Sleep -Milliseconds 250
        try {
            $health = Invoke-RestMethod -Uri "$baseUrl/health" -Method Get -TimeoutSec 2
            if ($health.status -eq "ok") { $ready = $true; break }
        } catch { }
        if ($server.HasExited) { break }
    }
    Assert-True $ready "server starts and /health responds"

    try {
        Invoke-RestMethod -Uri "$baseUrl/api/snapshot" -Method Get -TimeoutSec 3 | Out-Null
        throw "FAILED: private API accepted a request without a token"
    } catch {
        $status = [int]$_.Exception.Response.StatusCode
        Assert-True ($status -eq 401) "private API rejects missing authorization"
    }

    $headers = @{ Authorization = "Bearer $token" }
    $jsonHeaders = @{ Authorization = "Bearer $token"; "Content-Type" = "application/json" }

    $note = Invoke-RestMethod -Uri "$baseUrl/api/notes" -Method Post -Headers $jsonHeaders -Body (@{
        title = "Windows smoke note"
        body = "AgentSoul automated local validation"
        source = "scripts/windows-smoke.ps1"
    } | ConvertTo-Json)
    Assert-True ([bool]$note.data.note_id) "note creation"

    $company = Invoke-RestMethod -Uri "$baseUrl/api/entities" -Method Post -Headers $jsonHeaders -Body (@{
        entity_type = "company"
        name = "Smoke Company"
        attributes = @{ status = "test" }
    } | ConvertTo-Json -Depth 4)
    $project = Invoke-RestMethod -Uri "$baseUrl/api/entities" -Method Post -Headers $jsonHeaders -Body (@{
        entity_type = "project"
        name = "AgentSoul Smoke"
    } | ConvertTo-Json)
    Assert-True ([bool]$company.data.entity_id -and [bool]$project.data.entity_id) "entity creation"

    $link = Invoke-RestMethod -Uri "$baseUrl/api/links" -Method Post -Headers $jsonHeaders -Body (@{
        subject_id = $company.data.entity_id
        predicate = "uses"
        object_id = $project.data.entity_id
    } | ConvertTo-Json)
    Assert-True ([bool]$link.data.link_id) "typed link creation"

    $knowledge = Invoke-RestMethod -Uri "$baseUrl/api/knowledge" -Method Post -Headers $jsonHeaders -Body (@{
        kind = "pattern"
        title = "Automate local validation"
        summary = "Run an end-to-end smoke test instead of asking the user to perform CRUD manually."
        confidence = 4
    } | ConvertTo-Json)
    Assert-True ([bool]$knowledge.data.knowledge_id) "reviewed knowledge creation"

    $snapshot = Invoke-RestMethod -Uri "$baseUrl/api/snapshot" -Method Get -Headers $headers
    Assert-True ($snapshot.data.notes.Count -eq 1) "snapshot contains note"
    Assert-True ($snapshot.data.entities.Count -eq 2) "snapshot contains entities"
    Assert-True ($snapshot.data.links.Count -eq 1) "snapshot contains link"
    Assert-True ($snapshot.data.knowledge.Count -eq 1) "snapshot contains knowledge"

    $search = Invoke-RestMethod -Uri "$baseUrl/api/search?q=automated" -Method Get -Headers $headers
    Assert-True ($search.data.notes.Count -ge 1) "search finds stored note"

    $deleted = Invoke-RestMethod -Uri "$baseUrl/api/notes/$($note.data.note_id)" -Method Delete -Headers $headers
    Assert-True ($deleted.data.deleted -eq $true) "note deletion"

    Write-Host ""
    Write-Host "AgentSoul Windows smoke test completed successfully."
    Write-Host "Temporary memory: $home"
}
catch {
    Write-Error $_
    foreach ($path in @($stdoutPath, $stderrPath)) {
        if (Test-Path $path) {
            Write-Host "--- $(Split-Path $path -Leaf) ---"
            Get-Content $path -ErrorAction SilentlyContinue
        }
    }
    exit 1
}
finally {
    if ($server -and -not $server.HasExited) {
        Stop-Process -Id $server.Id -Force -ErrorAction SilentlyContinue
        $server.WaitForExit()
    }
    Remove-Item Env:AGENTSOUL_HOME -ErrorAction SilentlyContinue
    Remove-Item Env:AGENTSOUL_API_TOKEN -ErrorAction SilentlyContinue
    Remove-Item Env:AGENTSOUL_HOST -ErrorAction SilentlyContinue
    Remove-Item Env:AGENTSOUL_PORT -ErrorAction SilentlyContinue
}
