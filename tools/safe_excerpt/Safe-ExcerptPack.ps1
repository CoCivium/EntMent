param(
[Parameter()][string]$RepoPath = "",
[Parameter()][string]$AllowlistPath = ".\tools\safe_excerpt\allowlist.sample.json",
[Parameter()][string]$OutDir = "",
[switch]$DryRun
)

$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
function UTS { (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssZ') }

function Fail([string]$m){ throw "SAFE_EXCERPT FAIL: $m" }

Resolve repo root

if([string]::IsNullOrWhiteSpace($RepoPath)){
$RepoPath = (& git rev-parse --show-toplevel 2>$null)
}
if([string]::IsNullOrWhiteSpace($RepoPath)){ Fail "Not inside a git repo (RepoPath empty)." }
$RepoPath = (Resolve-Path -LiteralPath $RepoPath).Path

Default output

if([string]::IsNullOrWhiteSpace($OutDir)){
$OutDir = Join-Path $HOME "Downloads"
}
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

Load allowlist

$allow = Get-Content -Raw -LiteralPath (Join-Path $RepoPath $AllowlistPath) | ConvertFrom-Json
if(-not $allow.include -or $allow.include.Count -eq 0){ Fail "Allowlist include[] is empty." }

Forbid absolute paths / vaultish paths / traversal

function Assert-Rel([string]$p){
if($p -match '^[a-zA-Z]:\' -or $p -match '^\\'){ Fail "Absolute/UNC path not allowed: $p" }
if($p -match '..'){ Fail "Traversal '..' not allowed: $p" }
if($p -match '^(O:|\\Server\CoCiviumAdmin\CoVault)'){ Fail "Vault path forbidden by default: $p" }
}

Expand includes to file list

$files = New-Object System.Collections.Generic.List[string]
Push-Location -LiteralPath $RepoPath
try {
foreach($inc in @($allow.include)){
Assert-Rel $inc
$full = Join-Path $RepoPath $inc
if(!(Test-Path -LiteralPath $full)){ Fail "Include not found: $inc" }if((Get-Item -LiteralPath $full).PSIsContainer){
  Get-ChildItem -LiteralPath $full -Recurse -File | ForEach-Object {
    $rel = Resolve-Path -LiteralPath $_.FullName | ForEach-Object { $_.Path.Substring($RepoPath.Length).TrimStart('\','/') }
    $files.Add($rel)
  }
} else {
  $rel = $inc.Replace('\','/')
  $files.Add($rel)
}
}

Apply excludes (wildcards on normalized relpaths)

$ex = @()
if($allow.exclude){ $ex = @($allow.exclude) }
if($ex.Count -gt 0){
$keep = New-Object System.Collections.Generic.List[string]
foreach($f in $files){
$norm = $f.Replace('','/'); $drop = $false
foreach($pat in $ex){
# naive glob -> wildcard match
$wp = $pat.Replace('','/').Replace('**','*')
if($norm -like $wp){ $drop = $true; break }
}
if(-not $drop){ $keep.Add($norm) }
}
$files = $keep
}

$files = $files | Sort-Object -Unique
if($files.Count -eq 0){ Fail "After excludes, file list is empty." }

$repoName = Split-Path -Leaf $RepoPath
$ts = UTS
$zipName = "${repoName}SAFE_EXCERPT${ts}.zip"
$zipPath = Join-Path $OutDir $zipName

$head = (& git rev-parse HEAD).Trim()
$origin = ""
try { $origin = (& git remote get-url origin).Trim() } catch { $origin = "" }

$manifest = [pscustomobject]@{
schema_version = "0.1"
generated_utc = $ts
session_label = $env:CO_SESSION_LABEL
repo_name = $repoName
repo_origin = $origin
head_sha = $head
allowlist_path = $AllowlistPath
file_count = $files.Count
files = $files
}

$manifestPath = "${zipPath}.manifest.json"
$zipShaPath = "${zipPath}.sha256"
$manShaPath = "${manifestPath}.sha256"

if($DryRun){
Write-Host "DRYRUN zip:" $zipPath
Write-Host "DRYRUN files:" $files.Count
exit 0
}

if(Test-Path -LiteralPath $zipPath){ Remove-Item -Force -LiteralPath $zipPath }
Compress-Archive -Path $files -DestinationPath $zipPath -Force

($manifest | ConvertTo-Json -Depth 50) | Set-Content -Encoding UTF8 -LiteralPath $manifestPath

(Get-FileHash -Algorithm SHA256 -LiteralPath $zipPath).Hash.ToLower() + " " + (Split-Path -Leaf $zipPath) |
Set-Content -Encoding ASCII -LiteralPath $zipShaPath

(Get-FileHash -Algorithm SHA256 -LiteralPath $manifestPath).Hash.ToLower() + " " + (Split-Path -Leaf $manifestPath) |
Set-Content -Encoding ASCII -LiteralPath $manShaPath

Write-Host "OK ZIP:" $zipPath
Write-Host "OK ZIP.SHA:" $zipShaPath
Write-Host "OK MANIFEST:" $manifestPath
Write-Host "OK MANIFEST.SHA:" $manShaPath
}
finally { Pop-Location }
