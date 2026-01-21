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

# Resolve repo root
if([string]::IsNullOrWhiteSpace($RepoPath)){
  $RepoPath = (& git rev-parse --show-toplevel 2>$null)
}
if([string]::IsNullOrWhiteSpace($RepoPath)){ Fail "Not inside a git repo (RepoPath empty)." }
$RepoPath = (Resolve-Path -LiteralPath $RepoPath).Path

# Default output
if([string]::IsNullOrWhiteSpace($OutDir)){
  $OutDir = Join-Path $HOME "Downloads"
}
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

# Load allowlist
$allowFull = Join-Path $RepoPath $AllowlistPath
if(!(Test-Path -LiteralPath $allowFull)){ Fail "Allowlist not found: $AllowlistPath" }
$allow = Get-Content -Raw -LiteralPath $allowFull | ConvertFrom-Json
$include = @($allow.include)
if($include.Count -eq 0){ Fail "Allowlist include[] is empty." }
$exclude = @()
if($allow.exclude){ $exclude = @($allow.exclude) }

function Assert-Rel([string]$p){
  if($p -match '^[a-zA-Z]:\\' -or $p -match '^[a-zA-Z]:/' -or $p -match '^\\\\'){ Fail "Absolute/UNC path not allowed: $p" }
  if($p -match '\.\.'){ Fail "Traversal '..' not allowed: $p" }
  if($p -match '^(O:|\\\\Server\\CoCiviumAdmin\\CoVault)'){ Fail "Vault path forbidden by default: $p" }
}
function NormalizeRel([string]$p){
  $p = $p.Replace('\','/')
  $p = $p.TrimStart('/')
  if($p.StartsWith("./")){ $p = $p.Substring(2) }
  return $p
}
function GlobToWildcard([string]$pat){
  $p = $pat.Replace('\','/')
  $p = $p.Replace('**','*')
  return $p.TrimStart('/')
}

$files = New-Object 'System.Collections.Generic.List[string]'
Push-Location -LiteralPath $RepoPath
try {
  foreach($inc in $include){
    Assert-Rel $inc
    $relInc = NormalizeRel $inc
    $full = Join-Path $RepoPath $relInc
    if(!(Test-Path -LiteralPath $full)){ Fail "Include not found: $relInc" }
    $item = Get-Item -LiteralPath $full
    if($item.PSIsContainer){
      Get-ChildItem -LiteralPath $full -Recurse -File | ForEach-Object {
        $rel = $_.FullName.Substring($RepoPath.Length).TrimStart('\','/')
        $files.Add((NormalizeRel $rel))
      }
    } else {
      $files.Add($relInc)
    }
  }

  $files = $files | Sort-Object -Unique

  if($exclude.Count -gt 0){
    $keep = New-Object 'System.Collections.Generic.List[string]'
    foreach($f in $files){
      $drop=$false
      foreach($pat in $exclude){
        $wp = GlobToWildcard $pat
        if($f -like $wp){ $drop=$true; break }
      }
      if(-not $drop){ $keep.Add($f) }
    }
    $files = $keep
  }

  if($files.Count -eq 0){ Fail "After excludes, file list is empty." }

  $repoName = Split-Path -Leaf $RepoPath
  $ts = UTS
  $zipName = "${repoName}__SAFE_EXCERPT__${ts}.zip"
  $zipPath = Join-Path $OutDir $zipName

  $head = (& git rev-parse HEAD).Trim()
  $origin = ""
  try { $origin = (& git remote get-url origin).Trim() } catch { $origin = "" }

  $manifest = [pscustomobject]@{
    schema_version = "0.1"
    generated_utc  = $ts
    session_label  = $env:CO_SESSION_LABEL
    repo_name      = $repoName
    repo_origin    = $origin
    head_sha       = $head
    allowlist_path = $AllowlistPath
    file_count     = $files.Count
    files          = $files
  }

  $manifestPath = "${zipPath}.manifest.json"
  $zipShaPath   = "${zipPath}.sha256"
  $manShaPath   = "${manifestPath}.sha256"

  if($DryRun){
    Write-Host "DRYRUN zip:" $zipPath
    Write-Host "DRYRUN files:" $files.Count
    exit 0
  }

  if(Test-Path -LiteralPath $zipPath){ Remove-Item -Force -LiteralPath $zipPath }
  Compress-Archive -Path $files -DestinationPath $zipPath -Force

  ($manifest | ConvertTo-Json -Depth 50) | Set-Content -Encoding UTF8 -LiteralPath $manifestPath
  (Get-FileHash -Algorithm SHA256 -LiteralPath $zipPath).Hash.ToLower() + "  " + (Split-Path -Leaf $zipPath) |
    Set-Content -Encoding ASCII -LiteralPath $zipShaPath
  (Get-FileHash -Algorithm SHA256 -LiteralPath $manifestPath).Hash.ToLower() + "  " + (Split-Path -Leaf $manifestPath) |
    Set-Content -Encoding ASCII -LiteralPath $manShaPath

  Write-Host "OK ZIP:" $zipPath
  Write-Host "OK ZIP.SHA:" $zipShaPath
  Write-Host "OK MANIFEST:" $manifestPath
  Write-Host "OK MANIFEST.SHA:" $manShaPath
}
finally { Pop-Location }
