# CoExGate v1 — Global Session-Close Protocol

## Intent
No session should declare .done until identified CoEx-worthy artifacts have been externalized to a verified target.

## Required steps

### 1. Enumerate CoEx candidates
- CoTerms
- policies
- mandates
- handoff notes
- lessons
- CoPaths
- public-facing content

### 2. Run CoRepoProbe
Before any git action, confirm the target path actually contains a .git directory.

### 3. Select target class
- CoEx-canonical = pushed repo / live public surface
- CoEx-staged = repo-ready local export waiting for push
- CoInt-only = internal only, not sufficient for close unless explicitly justified

### 4. Write before claim
Write artifacts first.
Then write receipt / hash.
Then emit status.

### 5. Close rules
- CoClosePass = CoExGate satisfied
- CoCloseFail = CoExGate not satisfied
- CoExGap = identified artifact was not externalized
- CoReceiptFirst = receipt exists before close claim

### 6. Handoff discipline
Carry only:
- CoAnchorCarry
- policy deltas
- receipts / pointers
- next actions

## New CoTerms
- CoExGate
- CoExGap
- CoClosePass
- CoCloseFail
- CoStageSafe
- CoRepoProbe
- CoReceiptFirst
- CoAnchorCarry
