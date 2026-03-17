# Policy Proposal: Bounded File Crawling and Harvesting

## Intent
Prevent slow, fragile, or misleading ingestion runs while improving public, auditable harvesting.

## Rule 1 — Discovery before recursion
Do not start with deep recursive crawls on UNC/network shares.
Start with:
- top-level folders
- immediate child folders
- filename-based filtering
- small candidate sets

## Rule 2 — Separate phases
Use four phases:
1. discover
2. classify
3. compress
4. promote

Do not treat raw harvest as public canon.

## Rule 3 — Bounded traversal
Every crawl must declare:
- root set
- max folders per root
- max files per folder
- max bytes copied
- timeout / cancellation rule

## Rule 4 — Prefer metadata-first enumeration
Prefer fast directory entry inspection over full file reads.
Avoid reading file bodies until a candidate has been selected.

## Rule 5 — Explicit link handling
Junctions, symlinks, and related link structures must be handled deliberately.
Do not assume the filesystem is a clean tree.

## Rule 6 — Retry budgets must be small
Copy/mining tools must override dangerous retry defaults.
Fast failure is preferred over silent hour-long hangs.

## Rule 7 — Trust tiering
Every harvested artifact must be tagged:
- speculative
- grounded
- verified

And also:
- CoEx candidate
- CoInt only
- needs Prime review

## Rule 8 — Public receipts
Every harvest wave should publish:
- source manifest
- candidate index
- hash receipts
- promotion rationale

## Rule 9 — Promotion pressure
Large harvests should not become large public sites directly.
Use:
- many harvested candidates
- fewer compressed drafts
- very few promoted canonical pages

## Rule 10 — Fail loud, fail visible
If a crawl is too slow, too broad, or blocked by permissions, publish the lesson publicly as an operational note.
