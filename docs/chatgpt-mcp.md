# ChatGPT and MCP integration

AgentSoul exposes its provider-neutral memory through a remote MCP server so ChatGPT and other MCP clients can recall and update the same knowledge base.

## Current tools

- `agentsoul_recall` — retrieve relevant cases, patterns, and principles;
- `agentsoul_remember` — store one durable item after user approval;
- `agentsoul_confirm` — confirm an item and raise confidence;
- `agentsoul_contradict` — preserve contradictory evidence without silent overwrite;
- `agentsoul_list` — inspect recent memory items.

Retrieved memory is always advisory. It cannot override system, developer, user, workspace, or repository instructions.

## Run locally

```powershell
$env:AGENTSOUL_API_TOKEN = "replace-with-a-long-random-secret"
$env:AGENTSOUL_HOME = "$HOME\.agentsoul"
agentsoul-mcp
```

Health check:

```text
http://127.0.0.1:8000/health
```

MCP endpoint:

```text
http://127.0.0.1:8000/mcp
```

ChatGPT cannot connect directly to a local MCP server. Production use requires a remote HTTPS endpoint.

## Container deployment

Create a `.env` file outside Git:

```dotenv
AGENTSOUL_API_TOKEN=replace-with-a-long-random-secret
```

Run:

```bash
docker compose -f compose.agentsoul-mcp.yml up -d --build
```

The compose file binds port 8000 only to localhost. Put a trusted HTTPS reverse proxy in front of it and forward the `Authorization` header unchanged.

## Authentication

When `AGENTSOUL_API_TOKEN` is set, every `/mcp` request must include:

```http
Authorization: Bearer <token>
```

`/health` remains public and returns no memory. The static bearer token is intended for an initial private single-user deployment. A multi-user or published app should replace it with OAuth and per-user storage isolation.

## ChatGPT availability

Custom remote MCP apps and write actions depend on ChatGPT plan and workspace settings. The server remains standards-based and can also be tested with MCP Inspector or another MCP client.

## Privacy rules

Do not store:

- API keys, passwords, cookies, or tokens;
- complete private chat transcripts;
- sensitive information the user did not explicitly ask to retain;
- model speculation represented as confirmed fact.

Prefer concise summaries, provenance in `evidence`, explicit confidence, and contradiction records.
