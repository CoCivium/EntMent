# ENTMENT (EntMent.org) — AI-first beacon exemplar

ENTMENT is a dual-surface web service:
- Human surface: EntMent.org (readable front door + community context)
- AI surface: CoAura/Beacon (machine-friendly interfaces for AIs serving humans)

Primary customer: an AI acting on behalf of a human.
This repo is built to self-evolve via CoMetaTrain tags and PS7-gated contributions.

## Start here
- [CoCivium public research front door](https://github.com/CoCivium/CoCivium)
- [Beacon overview](docs/BEACON_OVERVIEW.md)
- [PS7 panel specification](docs/PS7_PANEL_SPEC.md)
- [AI context](docs/AI_CONTEXT.md)
- [Agent index](docs/AGENT_INDEX.json)

## Pointers and evidence boundary
- `docs/POINTER_SPEC.md` is referenced by existing documentation but **is not present in the inspected `docs/` tree**. Its specification and acceptance status remain unresolved; do not treat the missing file as implemented.
- AI bootstrap stub: `site/public/.well-known/cobeacon.txt` (repository path; availability not independently verified here).
- `docs/LATEST_POINTER.txt` declares `https://entment.org/` as the site root; this declaration does not independently establish live availability, deployment, or currentness.
