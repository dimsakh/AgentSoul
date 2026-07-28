# AgentSoul web interface

AgentSoul includes a lightweight browser interface served by the same process as the MCP endpoint.

## Start locally

```bash
set AGENTSOUL_API_TOKEN=replace-with-a-long-random-token
agentsoul-mcp
```

On PowerShell:

```powershell
$env:AGENTSOUL_API_TOKEN = "replace-with-a-long-random-token"
agentsoul-mcp
```

Open:

```text
http://127.0.0.1:8000/ui
```

Enter the bearer token in the page header and select **Load**.

## Available sections

- **Notes** — quick unstructured capture with an optional source.
- **Entities** — companies, projects, people, documents, topics, and other structured objects.
- **Links** — typed relationships between entities.
- **Knowledge** — reviewed cases, patterns, and principles with confidence metadata.

The interface supports combined search, creation, and deletion. The JSON API also supports note and entity updates, leaving room for richer inline editing later.

## Security

The HTML shell at `/ui` contains no private memory and may load without authentication. Every `/api/*` request and the `/mcp` endpoint require the configured bearer token. Deploy the service behind HTTPS and do not put the token into URLs, logs, screenshots, or Git.

For a public or multi-user deployment, replace the static token with OAuth and per-user storage isolation.

## Resource profile

The interface is plain HTML, CSS, and JavaScript embedded in the Python package. It requires no Node.js process, frontend build server, Redis, or separate database. SQLite and one Uvicorn process keep the initial deployment suitable for a small 1 GB VPS.
