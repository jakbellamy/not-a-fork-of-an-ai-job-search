[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

function Write-Step([string]$Message) {
    Write-Host "`n[setup] $Message" -ForegroundColor Cyan
}

function Ensure-Command([string]$Name, [string]$InstallHint) {
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "$Name was not found. $InstallHint"
    }
}

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw "Winget was not found. Install the Microsoft App Installer from the Microsoft Store and rerun this script."
}

Write-Step "Installing Git, Python, Node.js, and MiKTeX..."
$packages = @(
    @{ Id = 'Git.Git'; Name = 'Git' },
    @{ Id = 'Python.Python.3.12'; Name = 'Python 3.12' },
    @{ Id = 'OpenJS.NodeJS.LTS'; Name = 'Node.js LTS' },
    @{ Id = 'MiKTeX.MiKTeX'; Name = 'MiKTeX' }
)

foreach ($pkg in $packages) {
    Write-Host "Installing $($pkg.Name)..."
    & winget install --id $pkg.Id --silent --accept-source-agreements --accept-package-agreements
}

Write-Step "Installing Bun..."
$bunBin = Join-Path $HOME '.bun\bin'
if (-not (Test-Path $bunBin)) {
    & powershell -ExecutionPolicy Bypass -c "irm https://bun.sh/install.ps1 | iex"
}

if (Test-Path (Join-Path $bunBin 'bun.exe')) {
    $env:Path = "$bunBin;$env:Path"
    [Environment]::SetEnvironmentVariable('Path', "$([Environment]::GetEnvironmentVariable('Path', 'User'));$bunBin", 'User')
}

Write-Step "Installing optional tooling and Python packages..."
try {
    & winget install --id GnuWin32.Poppler --silent --accept-source-agreements --accept-package-agreements
} catch {
    Write-Warning 'Poppler could not be installed automatically. The setup will continue; install it later if you want pdftotext.'
}

if (Get-Command py -ErrorAction SilentlyContinue) {
    & py -m pip install --user --upgrade pip pytest
} elseif (Get-Command python -ErrorAction SilentlyContinue) {
    & python -m pip install --user --upgrade pip pytest
} else {
    throw 'Python was not found after installation. Reopen the terminal and rerun this script.'
}

Write-Step "Installing Claude Code..."
& npm install -g @anthropic-ai/claude-code

Write-Step "Installing job-portal CLI dependencies..."
$tools = @('jobbank-search', 'jobdanmark-search', 'jobindex-search', 'jobnet-search', 'linkedin-search', 'freehire-search')
foreach ($tool in $tools) {
    $cliPath = Join-Path $scriptDir ('.agents\skills\' + $tool + '\cli')
    if (Test-Path $cliPath) {
        Write-Host "Installing $tool..."
        Push-Location $cliPath
        try {
            $bunExe = Join-Path $HOME '.bun\bin\bun.exe'
            if (Test-Path $bunExe) {
                & $bunExe install
            } else {
                & bun install
            }
        } finally {
            Pop-Location
        }
    }
}

Write-Step 'Setup complete.'
Write-Host 'Open a new terminal and run: claude' -ForegroundColor Green
Write-Host 'Then inside Claude Code, run: /setup' -ForegroundColor Green
