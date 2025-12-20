<#
PowerShell DB helper for local Docker Postgres
Usage:
  .\scripts\db_helper.ps1 start   # starts docker-compose and waits for readiness
  .\scripts\db_helper.ps1 stop    # stops and removes containers
  .\scripts\db_helper.ps1 restart # restart
  .\scripts\db_helper.ps1 logs    # show DB container logs
  .\scripts\db_helper.ps1 verify  # run verification checks
  .\scripts\db_helper.ps1 seed    # apply seed files (useful if re-seeding a running DB)
#>

param(
    [Parameter(Position = 0, Mandatory = $true)]
    [ValidateSet('start', 'stop', 'restart', 'logs', 'verify', 'seed')]
    [string]$Action
)

function Ensure-DockerAvailable {
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        Write-Error "Docker is not installed or not in PATH. Install Docker Desktop and try again."
        exit 2
    }
}

function Start-Db {
    Ensure-DockerAvailable
    Write-Host "Starting docker-compose..."
    docker compose up -d

    $User = if ($env:POSTGRES_USER) { $env:POSTGRES_USER } else { 'postgres' }
    $DB = if ($env:POSTGRES_DB) { $env:POSTGRES_DB } else { 'bankdb' }

    Write-Host "Waiting for Postgres to accept connections... (user=$User db=$DB)"
    $max = 60
    for ($i = 0; $i -lt $max; $i++) {
        try {
            docker exec pg-bank pg_isready -U $User -d $DB | Out-Null
            if ($LASTEXITCODE -eq 0) { Write-Host "Postgres is ready."; return }
        }
        catch { }
        Start-Sleep -Seconds 2
    }
    Write-Error "Postgres did not become ready in time. Check container logs with '.\scripts\db_helper.ps1 logs'."
}

function Stop-Db {
    Ensure-DockerAvailable
    Write-Host "Stopping docker-compose..."
    docker compose down
}

function Show-Logs {
    Ensure-DockerAvailable
    docker logs -f pg-bank
}

function Verify-Db {
    Ensure-DockerAvailable

    $User = if ($env:POSTGRES_USER) { $env:POSTGRES_USER } else { 'postgres' }
    $DB = if ($env:POSTGRES_DB) { $env:POSTGRES_DB } else { 'bankdb' }

    Write-Host "Running basic verification queries... (user=$User db=$DB)"
    docker exec -i pg-bank psql -U $User -d $DB -c "SELECT current_database(), version();"

    $exists = docker exec -i pg-bank psql -U $User -d $DB -t -A -c "SELECT to_regclass('public.personal_customers');"
    if ([string]::IsNullOrEmpty($exists)) {
        Write-Warning "Table 'personal_customers' not found"
    } else {
        docker exec -i pg-bank psql -U $User -d $DB -c "SELECT count(*) FROM personal_customers;"
    }

    $v1 = docker exec -i pg-bank psql -U $User -d $DB -t -A -c "SELECT to_regclass('public.view_customer_balances');"
    if (-not [string]::IsNullOrEmpty($v1)) {
        docker exec -i pg-bank psql -U $User -d $DB -c "SELECT * FROM view_customer_balances LIMIT 10;"
    } else { Write-Warning "View 'view_customer_balances' not found" }

    $v2 = docker exec -i pg-bank psql -U $User -d $DB -t -A -c "SELECT to_regclass('public.view_recent_transactions');"
    if (-not [string]::IsNullOrEmpty($v2)) {
        docker exec -i pg-bank psql -U $User -d $DB -c "SELECT * FROM view_recent_transactions LIMIT 10;"
    } else { Write-Warning "View 'view_recent_transactions' not found" }
}

function Seed-Db {
    Ensure-DockerAvailable
    $User = if ($env:POSTGRES_USER) { $env:POSTGRES_USER } else { 'postgres' }
    $DB = if ($env:POSTGRES_DB) { $env:POSTGRES_DB } else { 'bankdb' }
    Write-Host "Applying seed scripts (may be redundant if bootstrap already ran)... (user=$User db=$DB)"
    docker exec -i pg-bank psql -U $User -d $DB -f /docker-entrypoint-initdb.d/05_seed.sql
}

switch ($Action) {
    'start' { Start-Db }
    'stop' { Stop-Db }
    'restart' { Stop-Db; Start-Db }
    'logs' { Show-Logs }
    'verify' { Verify-Db }
    'seed' { Seed-Db }
}
