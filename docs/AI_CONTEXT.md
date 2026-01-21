# AI_CONTEXT (EntMent)

rn## SessionGuard/RepoGuard QuickStart

**Goal:** prevent identity drift (wrong repo / wrong session / wrong “To/From”).

### Mandatory at the top of every DO block
```powershell
$env:CO_SESSION_LABEL = 'EntMent'
Assert-RepoName 'EntMent'   # fail hard if repo mismatch
Mandatory at the end of every DO block

Emit a single receipt line:
# WAVE_END EntMent <what> utc=<UTS> commit=<git-short-sha> pointers=<paths/urls># WAVE_END EntMent <what> utc=<UTS> commit=<git-short-sha> pointers=<paths/urls>rn
