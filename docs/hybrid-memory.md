# Hybrid memory model

AgentSoul uses two complementary memory layers.

## 1. Durable knowledge

The existing `case -> pattern -> principle` hierarchy stores reviewed knowledge with confidence, evidence, confirmations, and contradictions. This layer is intentionally conservative.

## 2. Notes and entities

A lightweight SQLite database at `~/.agentsoul/agentsoul.db` stores:

- quick notes that have not yet been promoted into durable knowledge;
- entities such as projects, companies, people, documents, decisions, and topics;
- typed links between stored objects.

This lets users capture information immediately without deciding its final schema. Important notes can later become structured entities or reviewed knowledge.

## MCP tools

- `agentsoul_note` captures an unstructured note;
- `agentsoul_entity` creates or updates an entity;
- `agentsoul_link` creates a typed relationship;
- `agentsoul_recall` searches durable knowledge, notes, and entities together.

## Resource profile

The hybrid store uses Python's built-in SQLite support and no separate database server. WAL mode allows safe concurrent reads while keeping memory use low, making the initial deployment suitable for a small VPS with 1 GB RAM.

## Example

1. Capture a note about an AUSN payment.
2. Create a `company` entity and a `document` entity.
3. Link the company to the document with `has_document`.
4. After verification, promote the conclusion into a durable `case` or `pattern` with evidence.

The design is deliberately incremental: existing JSON knowledge remains valid and no forced migration is required.
