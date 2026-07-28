# Private VPS deployment for Hermes and Telegram

This is the default deployment for a single-user Hermes setup. It does not require a domain, Caddy, public HTTPS, or inbound access to AgentSoul.

## Network model

- Hermes reaches Telegram using an outbound connection.
- AgentSoul listens on the VPS loopback interface only: `127.0.0.1:8000`.
- Hermes on the same VPS calls AgentSoul locally.
- The AgentSoul bearer token remains enabled even though the port is private.
- The browser UI is opened through an SSH tunnel instead of a public port.

## Install

Clone or unpack the repository on the VPS, check out the AgentSoul branch, and run:

```bash
sudo bash deploy/vps/install.sh
```

The installer:

- copies the checkout to `/opt/agentsoul`;
- creates `/var/lib/agentsoul` for persistent memory;
- creates `/var/backups/agentsoul` for verified backups;
- generates a bearer token in `/etc/agentsoul/token`;
- starts AgentSoul through systemd and Docker Compose;
- enables the daily backup timer.

Verify locally on the VPS:

```bash
curl http://127.0.0.1:8000/health
sudo systemctl status agentsoul.service --no-pager
```

## Connect Hermes

When Hermes runs directly on the VPS host, configure its AgentSoul/MCP endpoint as:

```text
http://127.0.0.1:8000/mcp
```

Use this bearer token:

```bash
sudo cat /etc/agentsoul/token
```

Pass the token as an HTTP `Authorization` header:

```text
Authorization: Bearer <token>
```

The exact place where the endpoint and headers are entered depends on the Hermes version and its MCP configuration format. Keep the URL and token values above unchanged.

When Hermes runs in another Docker container, `127.0.0.1` points to that container rather than the VPS host. Put both services on one Docker network and use the service name `agentsoul:8000`, or explicitly route the Hermes container to the host loopback proxy. Do not publish AgentSoul on `0.0.0.0` merely to connect two local containers.

## Open the browser UI safely

From a laptop, create an SSH tunnel:

```bash
ssh -L 8000:127.0.0.1:8000 <user>@<vps-ip>
```

Then open:

```text
http://127.0.0.1:8000/ui
```

Enter the token from `/etc/agentsoul/token` in the UI. The tunnel encrypts traffic through SSH and does not expose port 8000 to the internet.

## Firewall

No inbound AgentSoul port is required. SSH is the only required inbound service for this setup. Telegram polling uses outbound HTTPS.

Check that AgentSoul is bound only to loopback:

```bash
ss -ltn | grep ':8000'
```

The expected local address is `127.0.0.1:8000`, not `0.0.0.0:8000`.

## Backups and updates

Create a backup manually:

```bash
sudo agentsoul-backup
```

Update safely:

```bash
sudo agentsoul-update
```

The updater creates a backup before rebuilding and checks the local health endpoint after restart.

## When public HTTPS becomes necessary

A public endpoint is only needed when a remote service outside the VPS must call AgentSoul directly. Add a tunnel or reverse proxy as a separate optional layer; do not weaken the private default deployment.
