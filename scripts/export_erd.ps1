<#
Exports Mermaid ERD to PNG and SVG.
Tries Node.js mmdc first, falls back to Docker image if Node not available.
#>
param()

function Run-NodeExport {
    if (-not (Get-Command npm -ErrorAction SilentlyContinue)) { return $false }
    if (-not (Test-Path node_modules)) { Write-Host "Installing npm dependencies..."; npm install }
    Write-Host "Running npm run export:erd..."
    npm run export:erd
    return $true
}

function Run-DockerExport {
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) { return $false }
    Write-Host "Running Docker mermaid-cli export..."
    $pwd = (Get-Location).Path
    docker run --rm -v "$pwd":/data minlag/mermaid-cli mmdc -i /data/docs/erd.mmd -o /data/docs/erd.png -w 1200 -H 800
    docker run --rm -v "$pwd":/data minlag/mermaid-cli mmdc -i /data/docs/erd.mmd -o /data/docs/erd.svg
    return $true
}

if (-not (Run-NodeExport)) {
    if (-not (Run-DockerExport)) {
        Write-Error "Neither Node.js (npm) nor Docker detected. Install one to export the diagram."
        exit 2
    }
}

Write-Host "Export complete: docs/erd.png and docs/erd.svg"