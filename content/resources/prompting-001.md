---
id: entment.resource.prompting-001
type: resource
title: "Prompting best practice: make success criteria explicit"
status: draft
date_utc: 20260117T053144Z
cometatrain:
  cta:
    - "Add one example prompt pair (bad→good)"
  evolve:
    - "Add common failure modes (overconfidence, missing constraints)"
  roadmap:
    - "v0.2: add evaluation rubric"
tags:
  - entment
  - prompt-engineering
  - best-practice
---

## Idea
Most prompt failures are missing success criteria. Make the AI restate them before it answers.

## Example
Bad: "Write a business plan."
Better: "Write a 1-page plan with: ICP, value prop, 3 risks, 3 experiments, and success metrics."
