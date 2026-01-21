# SAFE_EXCERPT (allowlist-only import/export pack)

## Purpose
Move **minimal, safe, reviewable** subsets of repo content between sessions and/or into Vault/INBOX **without leaking** secrets or dragging whole repos.

This is the canonical way to “hand content to an AI session” when the AI cannot browse private repos: **build a SAFE_EXCERPT pack + upload it**.

## Default stance (deny-by-default)
- **Only repo-relative allowlisted paths** are permitted.
- **Absolute paths are rejected** (including `O:\...`, `\\Server\...`, etc.).
- **Vault content is forbidden by default**. (You must explicitly override in code, and we generally don’t.)
- No `..` traversal allowed.

## Outputs (every run)
- `*_SAFE_EXCERPT__<UTC>.zip`
- `*.zip.sha256`  (hash of the zip)
- `*.zip.manifest.json` (machine-readable manifest of what’s inside)
- `*.zip.manifest.json.sha256`

## Checklist (PROMOTE_IMPORTS-style)
1) **Bind session identity**
   - ` $env:CO_SESSION_LABEL = 'EntMent' `
2) **SessionGuard / RepoGuard**
   - `Assert-RepoName 'EntMent'`
3) **Edit allowlist**
   - `tools/safe_excerpt/allowlist.sample.json`
4) **Run pack**
   - `.\tools\safe_excerpt\Safe-ExcerptPack.ps1 -AllowlistPath .\tools\safe_excerpt\allowlist.sample.json`
5) **Move pack**
   - Copy the zip + sha + manifest + manifest.sha into Vault INBOX (or attach/upload to the target session).
6) **WAVE_END receipt**
   - Record one line: timestamp + repo + commit + artifact paths.

## Allowlist format (JSON)
- `include`: array of repo-relative files/dirs
- `exclude`: optional array of wildcard patterns applied to relative paths

Example:
```json
{
  "include": ["README.md", "docs/AI_CONTEXT.md", "docs/workflows"],
  "exclude": ["**/drops/**", "**/*.pem", "**/.env", "**/secrets/**"]
}
Notes

If you copy/rename a timestamped zip to __LATEST.zip, regenerate the .sha256 so the leafname matches.
