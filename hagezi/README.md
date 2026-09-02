# hagezi blocklist mirror

## Ownership and attribution

All of the `.txt` blocklist files in this folder are the work of, and are owned by,
[hagezi](https://github.com/hagezi), and are copied **byte-for-byte unmodified** from the
[hagezi/dns-blocklists](https://github.com/hagezi/dns-blocklists) repository, which is licensed
under the [GNU General Public License v3.0](https://github.com/hagezi/dns-blocklists/blob/main/LICENSE).

They are not authored, edited, or maintained in this repository.

## Purpose

This folder exists **only as a local offline cached mirror for DNS-server blocking**: it lets the
DNS servers on this network fetch every blocklist they use from a single internal source
(`abp.markridgwell.com`) instead of reaching out to `raw.githubusercontent.com`.

Anyone else wanting these lists should use the upstream
[hagezi/dns-blocklists](https://github.com/hagezi/dns-blocklists) repository directly, which is
always the canonical, up-to-date source.

## Files

| File | Upstream source |
| --- | --- |
| `doh-vpn-proxy-bypass.txt` | [hosts/doh-vpn-proxy-bypass.txt](https://github.com/hagezi/dns-blocklists/blob/main/hosts/doh-vpn-proxy-bypass.txt) |
| `multi.txt` | [hosts/multi.txt](https://github.com/hagezi/dns-blocklists/blob/main/hosts/multi.txt) |
| `hoster.txt` | [hosts/hoster.txt](https://github.com/hagezi/dns-blocklists/blob/main/hosts/hoster.txt) |

The files are refreshed hourly by the `Repo: Update hagezi blocklist mirror` GitHub Actions
workflow, which clones the upstream repository and commits the files here only when their content
has changed; each such commit message records the upstream commit it was mirrored from.
