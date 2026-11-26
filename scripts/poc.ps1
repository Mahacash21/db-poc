<#
.SYNOPSIS
  Runs the local POC on Windows: Terraform builds Postgres, Liquibase builds the tables.

.EXAMPLE
  .\scripts\poc.ps1 up         # create Postgres + database, then apply all Liquibase changes
  .\scripts\poc.ps1 status     # list Liquibase changes not yet applied
  .\scripts\poc.ps1 migrate    # apply pending Liquibase changes only
  .\scripts\poc.ps1 rollback   # undo the most recent Liquibase change
  .\scripts\poc.ps1 tables     # list the tables in appdb
  .\scripts\poc.ps1 psql       # open an interactive SQL prompt
  .\scripts\poc.ps1 down       # delete the container, data volume and network
#>
param(
    [Parameter(Position = 0)]
    [ValidateSet("up", "migrate", "status", "rollback", "tables", "psql", "down")]
    [string]$Action = "up"
)

$ErrorActionPreference = "Stop"
$Root          = Split-Path -Parent $PSScriptRoot
$TfDir         = Join-Path $Root "terraform"
$ChangelogDir  = Join-Path $Root "liquibase\changelog"
$LiquibaseImg  = if ($env:LIQUIBASE_IMAGE) { $env:LIQUIBASE_IMAGE } else { "liquibase:4.33.0" }

# PowerShell doesn't stop on a failed .exe by itself, so check exit codes.
function Invoke-Native([string]$Name, [scriptblock]$Command) {
    & $Command
    if ($LASTEXITCODE -ne 0) { throw "$Name failed (exit code $LASTEXITCODE)" }
}

function Get-TfOutput([string]$Name) {
    $value = terraform "-chdir=$TfDir" output -raw $Name
    if ($LASTEXITCODE -ne 0) { throw "Could not read Terraform output '$Name'. Run '.\scripts\poc.ps1 up' first." }
    return $value
}

function Invoke-Liquibase([string[]]$LiquibaseArgs) {
    $net  = Get-TfOutput "docker_network"
    $url  = Get-TfOutput "liquibase_jdbc_url"
    $user = Get-TfOutput "app_username"
    $pw   = Get-TfOutput "app_password"

    Invoke-Native "Liquibase" {
        docker run --rm --network $net `
            -v "${ChangelogDir}:/liquibase/changelog" `
            $LiquibaseImg `
            --search-path=/liquibase/changelog `
            --changelog-file=db.changelog-master.yaml `
            "--url=$url" "--username=$user" "--password=$pw" `
            @LiquibaseArgs
    }
}

function Show-Tables {
    $user = Get-TfOutput "app_username"
    Invoke-Native "psql" { docker exec poc-postgres psql -U $user -d appdb -c "\dt" }
}

if (-not (Test-Path (Join-Path $TfDir "terraform.tfvars")) -and -not $env:TF_VAR_pg_admin_password) {
    throw "Missing terraform\terraform.tfvars. Copy terraform\terraform.tfvars.example to terraform\terraform.tfvars and set the passwords."
}

switch ($Action) {
    "up" {
        Write-Host "`n== Terraform: building Postgres ==" -ForegroundColor Cyan
        Invoke-Native "terraform init"  { terraform "-chdir=$TfDir" init -input=false }
        Invoke-Native "terraform apply" { terraform "-chdir=$TfDir" apply -auto-approve -input=false }

        Write-Host "`n== Liquibase: building tables ==" -ForegroundColor Cyan
        Invoke-Liquibase @("update")

        Write-Host "`n== Result ==" -ForegroundColor Cyan
        Show-Tables
        Write-Host "Connect a SQL client with: $(Get-TfOutput 'local_connection')" -ForegroundColor Green
    }
    "migrate"  { Invoke-Liquibase @("update"); Show-Tables }
    "status"   { Invoke-Liquibase @("status", "--verbose") }
    "rollback" { Invoke-Liquibase @("rollback-count", "--count=1"); Show-Tables }
    "tables"   { Show-Tables }
    "psql"     {
        $user = Get-TfOutput "app_username"
        docker exec -it poc-postgres psql -U $user -d appdb
    }
    "down"     {
        Invoke-Native "terraform destroy" { terraform "-chdir=$TfDir" destroy -auto-approve -input=false }
    }
}
