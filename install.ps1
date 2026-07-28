param(
    [string]$Python = "python",
    [switch]$User
)

$ErrorActionPreference = "Stop"

Write-Host "Installing AgentSoul..."
& $Python -m pip install --upgrade pip
$installArgs = @("-m", "pip", "install", ".")
if ($User) { $installArgs += "--user" }
& $Python @installArgs

& agentsoul init
Write-Host "AgentSoul installed successfully."
Write-Host "Run: agentsoul install-project <path-to-project>"
