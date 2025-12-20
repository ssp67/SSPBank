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
    Write-Host "Waiting for Postgres to accept connections..."
    $max = 60
    for ($i = 0; $i -lt $max; $i++) {
        try {
            docker exec pg-bank pg_isready -U $env:POSTGRES_USER -d $env:POSTGRES_DB | Out-Null
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
    Write-Host "Running basic verification queries..."
    docker exec -i pg-bank psql -U $env:POSTGRES_USER -d $env:POSTGRES_DB -c "SELECT current_database(), version();"
    docker exec -i pg-bank psql -U $env:POSTGRES_USER -d $env:POSTGRES_DB -c "SELECT count(*) FROM personal_customers;"
    docker exec -i pg-bank psql -U $env:POSTGRES_USER -d $env:POSTGRES_DB -c "SELECT * FROM view_customer_balances LIMIT 10;"
    docker exec -i pg-bank psql -U $env:POSTGRES_USER -d $env:POSTGRES_DB -c "SELECT * FROM view_recent_transactions LIMIT 10;"
}

function Seed-Db {
    Ensure-DockerAvailable
    Write-Host "Applying seed scripts (may be redundant if bootstrap already ran)..."
    docker exec -i pg-bank psql -U $env:POSTGRES_USER -d $env:POSTGRES_DB -f /docker-entrypoint-initdb.d/05_seed.sql
}

switch ($Action) {
    'start' { Start-Db }
    'stop' { Stop-Db }
    'restart' { Stop-Db; Start-Db }
    'logs' { Show-Logs }
    'verify' { Verify-Db }
    'seed' { Seed-Db }
}
