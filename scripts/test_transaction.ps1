# Simple end-to-end transaction smoke test for local DB
# Usage: .\scripts\test_transaction.ps1 [-Amount <decimal>] [-MinimumBalance <decimal>]
param(
    [decimal]$Amount = 10.00,
    [decimal]$MinimumBalance = 10.00
)

$Container = 'pg-bank'
$User = if ($env:POSTGRES_USER) { $env:POSTGRES_USER } else { 'postgres' }
$DB = if ($env:POSTGRES_DB) { $env:POSTGRES_DB } else { 'bankdb' }

function ExecSql($sql) {
    docker exec -i $Container psql -U $User -d $DB -t -A -c $sql
}

Write-Host "Running transaction smoke test against $Container (db=$DB user=$User) - amount=$Amount"

# Pick two accounts with sufficient balance
$rows = ExecSql("SELECT id::text || '|' || account_number || '|' || balance::text FROM accounts WHERE balance >= $MinimumBalance ORDER BY balance DESC LIMIT 2;") | Where-Object { $_ -ne '' }
if ($rows.Count -lt 2) {
    Write-Error "Not enough accounts with minimum balance $MinimumBalance found."
    exit 2
}

$leftParts = $rows[0].Split('|')
$rightParts = $rows[1].Split('|')
$fromId = [int]$leftParts[0]; $fromAcct = $leftParts[1]; $fromBalBefore = [decimal]$leftParts[2]
$toId = [int]$rightParts[0]; $toAcct = $rightParts[1]; $toBalBefore = [decimal]$rightParts[2]

Write-Host "Selected from: $fromAcct (id=$fromId, bal=$fromBalBefore) -> to: $toAcct (id=$toId, bal=$toBalBefore)"

# Compose unique description
$ts = (Get-Date).ToString('yyyyMMddHHmmss')
$rand = Get-Random -Maximum 9999
$desc = "TEST_TX_${ts}_${rand}"
$descEsc = $desc -replace "'","''"

# Insert test transaction with status 'posted'
$insSql = "INSERT INTO transactions (from_account_id,to_account_id,amount,type,status,description,initiated_by_customer_id) VALUES ($fromId,$toId,$Amount,'transfer','posted','$descEsc',(SELECT customer_id FROM account_owners WHERE account_id=$fromId AND is_primary=true LIMIT 1)) RETURNING id;"
$inserted = ExecSql($insSql) | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^[0-9]+' }
if (-not $inserted) {
    Write-Error "Failed to insert test transaction (insert returned nothing)."
    exit 3
}
$txId = [int]$inserted
Write-Host "Inserted transaction id=$txId desc=$desc"

Start-Sleep -Seconds 1

# Verify balances changed
$after = ExecSql("SELECT id::text||'|'||account_number||'|'||balance::text FROM accounts WHERE id IN ($fromId,$toId) ORDER BY id;") | Where-Object { $_ -ne '' }
if ($after.Count -lt 2) {
    Write-Error "Could not read account balances after posting transaction."
    exit 4
}
$fa = $after[0].Split('|'); $fb = $after[1].Split('|')
$fromBalAfter = [decimal]$fa[2]; $toBalAfter = [decimal]$fb[2]

if ($fromBalAfter -ne ($fromBalBefore - $Amount)) {
    Write-Error "From-account balance did not decrease as expected: before=$fromBalBefore after=$fromBalAfter expected=$(($fromBalBefore - $Amount))"
    $status = 'FAIL'
} elseif ($toBalAfter -ne ($toBalBefore + $Amount)) {
    Write-Error "To-account balance did not increase as expected: before=$toBalBefore after=$toBalAfter expected=$(($toBalBefore + $Amount))"
    $status = 'FAIL'
} else {
    Write-Host "Balances updated OK: $fromAcct $fromBalBefore->$fromBalAfter, $toAcct $toBalBefore->$toBalAfter"
    $status = 'OK'
}

# Create reversal transaction to restore balances
$revDesc = "REVERSAL_$txId"
$revDescEsc = $revDesc -replace "'","''"
$revIns = ExecSql("INSERT INTO transactions (from_account_id,to_account_id,amount,type,status,description,initiated_by_customer_id) VALUES ($toId,$fromId,$Amount,'reversal','posted','$revDescEsc',(SELECT customer_id FROM account_owners WHERE account_id=$toId AND is_primary=true LIMIT 1)) RETURNING id;") | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^[0-9]+' }
if (-not $revIns) {
    Write-Warning "Failed to insert reversal transaction; manual cleanup may be required."
    if ($status -eq 'OK') { Write-Host "Test succeeded but reversal failed: $txId"; exit 0 } else { exit 5 }
}
$revId = [int]$revIns
Write-Host "Inserted reversal id=$revId"

Start-Sleep -Seconds 1

# Verify balances restored
$rest = ExecSql("SELECT id::text||'|'||account_number||'|'||balance::text FROM accounts WHERE id IN ($fromId,$toId) ORDER BY id;") | Where-Object { $_ -ne '' }
$ra = $rest[0].Split('|'); $rb = $rest[1].Split('|')
$fromBalFinal = [decimal]$ra[2]; $toBalFinal = [decimal]$rb[2]

if (($fromBalFinal -ne $fromBalBefore) -or ($toBalFinal -ne $toBalBefore)) {
    Write-Error "Balances not restored to original: from was $fromBalBefore now $fromBalFinal; to was $toBalBefore now $toBalFinal"
    exit 6
}

Write-Host "Balances restored to original - test PASSED."
exit 0
