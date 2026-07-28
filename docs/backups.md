# AgentSoul backups

AgentSoul memory lives outside the repository. Backups therefore include the runtime home rather than Git-tracked source files.

## Create a backup

```bash
agentsoul backup
```

By default the archive is written under `~/.agentsoul/backups/` with a UTC timestamp. A custom path can be supplied:

```bash
agentsoul backup /safe/location/agentsoul.zip
```

The ZIP contains:

- a consistent SQLite snapshot created with the SQLite backup API;
- reviewed knowledge JSON files;
- event and session files;
- a `manifest.json` containing the backup format, file sizes, and SHA-256 checksums.

The backup process skips existing backup archives and SQLite WAL/SHM sidecar files.

## Restore a backup

Restore into an empty directory first:

```bash
agentsoul restore /safe/location/agentsoul.zip --destination ~/.agentsoul-restored
```

AgentSoul validates the archive paths and every checksum before copying any data. A non-empty destination is rejected by default.

To replace an existing destination explicitly:

```bash
agentsoul restore /safe/location/agentsoul.zip --destination ~/.agentsoul --replace
```

Stop the AgentSoul server before replacing its active memory directory. Keep the original directory until the restored copy has been opened and checked.

## Operational recommendation

For a single-user VPS, create one daily archive and retain several generations outside the server. A backup stored only on the same VPS protects against accidental edits, but not disk loss or account compromise.

Do not commit personal backups to the public AgentSoul repository. Backup archives may contain private memory and should be encrypted when stored on third-party systems.
