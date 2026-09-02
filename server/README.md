# Local adblock-list server

Serves `adblock.txt` and `hosts.txt` from a local nginx server so consumers on
the LAN (in particular the DNS servers) fetch the lists without any external
egress. Every other path, including `.git/`, returns 404. TLS is terminated at
the internal proxy, so nginx listens on plain HTTP.

## Requirements

* Arch Linux with `nginx` and `git` pre-installed.
* Root access.

## Install

```sh
sudo ./install.sh
```

The script is idempotent and safe to re-run for upgrades. It:

1. Creates the `adblock-sync` system user and `/var/lib/adblock-rules`.
2. Clones this repository into `/var/lib/adblock-rules/credfeto-adblock-rules`
   (or force-syncs an existing clone to `origin/main`).
3. Tests the shipped [nginx.conf](nginx/nginx.conf) with `nginx -t`; only if
   the test passes does it back up any existing `/etc/nginx/nginx.conf` and
   install the new one, then reload (or start) nginx.
4. Installs and enables [adblock-rules-sync.timer](adblock-rules-sync.timer),
   which runs [adblock-rules-sync.service](adblock-rules-sync.service) hourly
   to `git fetch` + `git reset --hard origin/main` the clone, publishing any
   list updates.

## Files

| File | Purpose |
| --- | --- |
| `install.sh` | Root install script described above |
| `nginx/nginx.conf` | Complete nginx configuration installed to `/etc/nginx/nginx.conf` |
| `adblock-rules-sync.service` | Oneshot unit that force-syncs the clone |
| `adblock-rules-sync.timer` | Hourly trigger (`Persistent=true`, 5 min random delay) |
