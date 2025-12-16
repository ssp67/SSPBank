#!/usr/bin/env pwsh
<#
Run the `scripts/check_bulk_seeds.sql` verification queries and print results.

Behavior:
- If `psql` is available in PATH, it will be used with environment variables
  (PGHOST, PGPORT, PGUSER, PGPASSWORD, PGDATABASE) or sensible defaults.
- Otherwise, the script will try to find a running Docker container using a
  Postgres image and run the SQL inside it via `docker exec -i ... psql -f -`.

Examples:
  .\scripts\run_check_bulk_seeds.ps1
  PGHOST=localhost PGPASSWORD=adminpass .\scripts\run_check_bulk_seeds.ps1
  .\scripts\run_check_bulk_seeds.ps1 -UseDocker
#>

param(
    [switch]$UseDocker,
    [string]$SqlFile = ''
)

try {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
}
catch {
    $scriptDir = Get-Location
}

if (-not $SqlFile) { $SqlFile = Join-Path $scriptDir 'check_bulk_seeds.sql' }

if (-not (Test-Path $SqlFile)) {
    Write-Error "SQL file not found: $SqlFile"
    exit 2
}

function CommandExists($cmd) { return (Get-Command $cmd -ErrorAction SilentlyContinue) -ne $null }

if (-not $UseDocker -and (CommandExists 'psql')) {
    Write-Output "Using local psql to execute $SqlFile"
    $PGHOST = $Env:PGHOST -or 'localhost'
    $PGPORT = $Env:PGPORT -or '5432'
    $PGUSER = $Env:PGUSER -or 'bank_admin'
    $PGPASSWORD = $Env:PGPASSWORD -or 'adminpass'
    $PGDATABASE = $Env:PGDATABASE -or 'bank'

    $env:PGPASSWORD = $PGPASSWORD

    $connStr = "host=$PGHOST port=$PGPORT user=$PGUSER dbname=$PGDATABASE"

    & psql $connStr -f $SqlFile -v ON_ERROR_STOP=1
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) { Write-Error "psql exited with code $exitCode"; exit $exitCode }
    exit 0
}

if (-not (CommandExists 'docker')) {
    Write-Error "Neither 'psql' nor 'docker' is available in PATH. Install psql or Docker to run verification."
    exit 3
}

Write-Output "psql not found or -UseDocker specified; attempting to locate a running Postgres container via Docker..."

# Find a running container whose image contains 'postgres'
$containers = & docker ps --format "{{.Names}} {{.Image}}" 2>$null

$candidate = $containers | ForEach-Object {
    if ($_ -match '^(\S+)\s+(\S+)$') { $n = $matches[1]; $img = $matches[2]; if ($img -match 'postgres') { $n } }
} | Select-Object -First 1

if (-not $candidate) {
    Write-Error "No running container with a Postgres image found. Start the DB container or run with psql available."
    exit 4
}

Write-Output "Found container '$candidate' — executing SQL inside the container"

# Use docker exec and feed the SQL file via stdin
try {
    # PowerShell redirection works with external processes
    & docker exec -i $candidate psql -U bank_admin -d bank -f - < $SqlFile
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) { Write-Error "docker exec psql exited with code $exitCode"; exit $exitCode }
}
catch {
    Write-Error "Failed to execute SQL in container: $_"
    exit 5
}

exit 0
