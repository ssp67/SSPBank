# PowerShell verification script for Docker Postgres
param(
  $Host = 'localhost',
  $Port = 5432,
  $User = 'postgres',
  $DB = 'bankdb'
)

Write-Host "Waiting for Postgres to accept connections..."
$max = 30
for ($i=0;$i -lt $max;$i++) {
  try {
    docker exec pg-bank pg_isready -U $User -d $DB | Out-Null
    if ($LASTEXITCODE -eq 0) { break }
  } catch { }
  Start-Sleep -Seconds 2
}

Write-Host "Checking sample data..."
docker exec -i pg-bank psql -U $User -d $DB -c "SELECT count(*) FROM customers;"
docker exec -i pg-bank psql -U $User -d $DB -c "SELECT * FROM view_customer_balances LIMIT 5;"
docker exec -i pg-bank psql -U $User -d $DB -c "SELECT * FROM view_recent_transactions LIMIT 5;"
