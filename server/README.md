# Local adblock-list server

Serves `adblock.txt` and `hosts.txt` from a local nginx server so consumers on
the LAN (in particular the DNS servers) fetch the lists without any external
egress. The two files are aliased individually into the vhost - there is no
document root, so nothing else (including `.git/`) is reachable and every
other path returns 404. TLS is terminated at the internal proxy, so nginx
listens on plain HTTP.

This vhost deliberately shadows the GitHub Pages deployment: the public
internet resolves `abp.markridgwell.com` to GitHub Pages (see
`.github/workflows/deploy-to-github-pages.yml`), while internal DNS points the
same name at this server. Both publishers serve the same two files and must be
changed together.

## Requirements

* Arch Linux with `nginx` and `git` pre-installed.
* Root access.

## Install

```sh
sudo ./install.sh
```

The checkout you run the script from is bootstrap-only: everything is
installed from the served clone at
`/var/lib/adblock-rules/credfeto-adblock-rules`, which the script syncs first
on a re-run - so re-running the installer always deploys whatever is on
`main`. It:

1. Creates the `adblock-sync` system user and `/var/lib/adblock-rules`.
2. Clones this repository into the served clone (or, on a re-run, syncs it to
   `origin/main` via the sync service so there is a single definition of how
   syncing works).
3. Installs and enables [adblock-rules-sync.timer](adblock-rules-sync.timer),
   which runs [adblock-rules-sync.service](adblock-rules-sync.service) hourly
   to force-sync the clone, publishing any list updates.
4. Tests the clone's [nginx.conf](nginx/nginx.conf) with `nginx -t`; only if
   the test passes does it back up any existing `/etc/nginx/nginx.conf` (to
   `/etc/nginx/nginx.conf.bak.<timestamp>`; restore with
   `cp -p /etc/nginx/nginx.conf.bak.<timestamp> /etc/nginx/nginx.conf &&
   systemctl reload nginx`) and install the new one, then reload (or start)
   nginx.
5. Opens port 80/tcp to private networks when firewalld is present (skipped
   otherwise).

## Files

| File | Purpose |
| --- | --- |
| `install.sh` | Root install script described above |
| `nginx/nginx.conf` | Complete nginx configuration installed to `/etc/nginx/nginx.conf` |
| `adblock-rules-sync.service` | Oneshot unit that force-syncs the clone (5 min start timeout) |
| `adblock-rules-sync.timer` | Hourly trigger (`Persistent=true`, 5 min random delay) |
