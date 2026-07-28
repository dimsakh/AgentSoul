# Knowledge lifecycle CLI

AgentSoul stores provider-neutral knowledge outside the repository under `~/.agentsoul/knowledge/`.

## Capture

```bash
agentsoul knowledge-capture case \
  "Preserve existing project instructions" \
  "Managed AgentSoul sections must not overwrite user-authored AGENTS.md content." \
  --anchors '{"domain":"tooling","trigger":"install","stakes":"trust_erosion"}' \
  --evidence "installer design"
```

Supported kinds:

- `case` — one concrete incident or observation;
- `pattern` — a repeated relationship supported by multiple cases;
- `principle` — a transferable rule supported across contexts.

Each item receives a stable identifier and starts with confidence from 1 to 5.

## Confirm

```bash
agentsoul knowledge-confirm case-2026-07-28-preserve-existing-project-instructions \
  --evidence "verified in another project"
```

Confirmation increments `confirmed_count`, raises confidence by one up to 5, and preserves the evidence trail.

## Contradict

```bash
agentsoul knowledge-contradict case-2026-07-28-preserve-existing-project-instructions \
  "A legacy adapter rewrites the whole file" \
  --evidence "observed in adapter v0"
```

Contradictions are appended rather than silently replacing the existing item. Confidence decreases by one down to 1. When contradictions outnumber confirmations, status becomes `weakened`.

## List

```bash
agentsoul knowledge-list --kind case --limit 10
```

Output is newline-delimited JSON so adapters and scripts can consume it without parsing human-oriented tables.

## Safety properties

- writes use a temporary file followed by an atomic replace;
- duplicate titles receive unique identifiers;
- unknown identifiers fail without creating files;
- repository code never contains the user's private memory;
- contradiction lineage remains inspectable.
