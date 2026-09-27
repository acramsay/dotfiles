# VPN + DNS

Proton WireGuard tunnel chained behind Tailscale's exit node, with split DNS and
a DNS-driven bypass whitelist. Everything lives in this repo; only the Proton
private key is machine-local.

## What it does

- **Tunnel** — `wg-quick up proton` brings up the Proton tunnel. Tailscale routes
  exit-node traffic through it. The machine is v4-only (this LAN has no native
  IPv6), so the tunnel carries no v6.
- **Split DNS** — dnsmasq is the single stub resolver (`127.0.0.1`) in *both*
  tunnel states. Lookup order: local/hosts → Tailscale MagicDNS → default
  upstreams (Proton while the tunnel is up, LAN gateway always).
- **Bypass whitelist** — domains listed in dnsmasq's `nftset=` have their resolved
  A records injected into an nft set. Packets to them are policy-routed out the
  LAN instead of the tunnel — so a site that blocks datacenter IPs (e.g.
  `nhes.nh.gov`) connects directly, while everything else goes through Proton.

## Resolution order

`/etc/dnsmasq.d/vpn-bypass.conf`:

1. `/etc/hosts` plus `hostsdir=/etc/dnsmasq.d/hosts.d` — local names and the
   materialized Tailscale MagicDNS names.
2. `servers-file=/etc/dnsmasq.d/dnsmasq.servers` — ordered upstreams, regenerated
   by `vpn-dns-refresh.sh`: Proton's tunnel resolver first while the tunnel is up,
   then the LAN gateway. `strict-order` keeps a tunnel-up lookup from falling
   through to the gateway (a DNS leak).
3. `no-resolv` makes dnsmasq ignore `/etc/resolv.conf` (which points back at it)
   and take upstreams only from the servers-file. Note `no-resolv` disables
   `resolv-file` but **not** `servers-file`/`server=`.

`/etc/resolv.conf` is a fixed `nameserver 127.0.0.1`, owned by dnsmasq in both
states. NetworkManager is set `rc-manager=unmanaged` so nothing rewrites it when
the tunnel changes. **Resolver ownership must not flip between tunnel states** —
that was the original bug class.

Tailscale runs `--accept-dns=false`, so its own `100.100.100.100` resolver is off
(and `server=/ts.net/100.100.100.100` would be a dead end). Instead
`vpn-dns-refresh.sh` reads `tailscale status --json` and materializes self + peer
names into `hosts.d/tailscale.hosts` — a snapshot, refreshed by `vpn-dns.timer`
every 10 minutes (`task ot:vpn-dns-refresh` for on demand).

## Bypass mechanism

`/etc/wireguard/vpn-bypass.nft`, table `ip vpn_bypass`:

- `prerouting` (filter) and `output` (**type route**) chains mark packets whose
  destination is in the `bypass` set with `0x200`.
- The output chain must be `type route`: a `filter` output hook runs *after* the
  routing decision and cannot re-route on a mark change.
- `postrouting` masquerades marked traffic — after re-routing, the source is still
  the tunnel address, which is unroutable via the LAN.
- Routing: `ip rule fwmark 0x200 lookup 200`; table 200 holds the live LAN default
  route (copied by `PreUp`), so marked traffic bypasses the tunnel.

dnsmasq injects bypass IPs on a *fresh* upstream query (`nftset=`), not on cache
hits. The table is recreated empty on each tunnel up, so a reload plus a fresh
query repopulates it.

## Files

Repo → deployed (`task ot:deploy-etc`):

| Repo | Deployed | Mode |
|---|---|---|
| `linux/etc/wireguard/proton.conf` | `/etc/wireguard/proton.conf` | symlink |
| `linux/etc/wireguard/vpn-bypass.nft` | `/etc/wireguard/vpn-bypass.nft` | symlink |
| `linux/etc/dnsmasq.d/vpn-bypass.conf` | `/etc/dnsmasq.d/vpn-bypass.conf` | **copy** |
| `linux/etc/resolv.conf` | `/etc/resolv.conf` | **copy** |
| `linux/etc/NetworkManager/conf.d/90-dns.conf` | `/etc/NetworkManager/conf.d/90-dns.conf` | **copy** |
| `linux/etc/systemd/system/vpn-dns.service` | `/etc/systemd/system/vpn-dns.service` | **copy** |
| `linux/etc/systemd/system/vpn-dns.timer` | `/etc/systemd/system/vpn-dns.timer` | **copy** |
| `linux/etc/tailscale/vpn-dns-refresh.sh` | `/etc/tailscale/vpn-dns-refresh.sh` | symlink |
| `linux/selinux/dnsmasq-nftset.te` | compiled into the SELinux policy | — |

Copies (not symlinks) are required because confined daemons — systemd `init_t`,
`NetworkManager_t`, and `dnsmasq_t` (via home protection) — cannot read symlinks
whose targets live under `$HOME`. `vpn-dns-refresh.sh` writes its generated files
under `/etc/dnsmasq.d/` (SELinux type `dnsmasq_etc_t`) because `dnsmasq_t` cannot
read `/var/lib`.

`/etc/wireguard/proton.key` is the machine-local secret (root:600, never
committed).

## SELinux

`dnsmasq_t` needs `netlink_netfilter_socket` permissions to use `nftset=`. The
committed module `linux/selinux/dnsmasq-nftset.te` is compiled and installed by
`task ot:init`. Do **not** regenerate it with `audit2allow` — that drops
permissions a fresh AVC set doesn't happen to include.

## Commands

| Task | What |
|---|---|
| `task ot:init` | Packages, deploy `/etc`, install SELinux module, enable dnsmasq + timer |
| `task ot:vpn-up` / `ot:vpn-down` | Bring the tunnel up / down |
| `task ot:vpn-status` | Tunnel, bypass set, rules, upstreams, timer |
| `task ot:vpn-import -- <conf>` | Switch to a downloaded Proton config (two steps, see below) |
| `task ot:vpn-dns-refresh` | Regenerate upstreams + MagicDNS hosts now |
| `task ot:deploy-etc` (`ot:de`) | Deploy `linux/etc/**` to `/etc` |

## Switching Proton servers

Download a fresh config from account.protonvpn.com (Downloads → WireGuard
configuration), then:

```sh
task ot:vpn-import -- ~/Downloads/proton-<server>.conf
task ot:vpn-down && task ot:vpn-up    # if the tunnel is already up;
                                      # otherwise just: task ot:vpn-up
```

`vpn-import` copies `Address`/`PublicKey`/`Endpoint` into `proton.conf` (hooks,
comments and `AllowedIPs` preserved) and writes the `PrivateKey` to
`/etc/wireguard/proton.key`, snapshotting the previous pair to `*.prev`. It does
**not** touch the live tunnel — apply by bouncing it. Keep several downloaded
configs and re-import to swap back. Verify with `task ot:vpn-status`.

## Rollback

**Emergency** (restore internet immediately):

```sh
printf 'nameserver 192.168.40.1\n' | sudo tee /etc/resolv.conf
```

**Undo a bad import** (restore the snapshotted pair, then bounce):

```sh
sudo install -o root -g root -m 600 /etc/wireguard/proton.key.prev /etc/wireguard/proton.key
sudo cp -f /etc/wireguard/proton.conf.prev /etc/wireguard/proton.conf
sudo wg-quick down proton; sudo wg-quick up proton
```

Full teardown and restore of pre-work networking:

```sh
sudo wg-quick down proton
sudo systemctl disable --now vpn-dns.timer vpn-dns.service dnsmasq
sudo rm -f /etc/dnsmasq.d/vpn-bypass.conf /etc/dnsmasq.d/dnsmasq.servers
sudo rm -rf /etc/dnsmasq.d/hosts.d
sudo rm -f /etc/wireguard/proton.conf /etc/wireguard/vpn-bypass.nft
sudo rm -f /etc/NetworkManager/conf.d/90-dns.conf
sudo rm -f /etc/systemd/system/vpn-dns.service /etc/systemd/system/vpn-dns.timer
sudo rm -rf /etc/tailscale
sudo semodule -r dnsmasq-nftset
sudo systemctl daemon-reload
sudo rm -f /etc/resolv.conf && sudo systemctl restart NetworkManager
sudo tailscale set --accept-dns=true    # re-enable MagicDNS
```

The pre-work state was NetworkManager owning `/etc/resolv.conf` (`1.1.1.1`,
`1.0.0.1`, `search lan`) with MagicDNS enabled and no `proton` tunnel,
`vpn_bypass` table, or `0x200` rules. `/etc/resolv.conf.bak` is the captured
original if NM does not rewrite it. Then revert the repo so a later `task cs` /
`ot:init` cannot re-apply it, and optionally drop packages added by this work
(`openresolv`) plus the linger setting and `/etc/sudoers.d/$USER` from `ot:init`.
A reboot guarantees no leftover interface, rules, or nft table.

## Gotchas

- The tunnel is v4-only. All v6 lines are commented in place; re-enabling needs a
  native v6 default route and moving the nft table back to `inet` (which has no
  `route` chain type).
- `proton.conf` must have no `DNS=` line; dnsmasq owns DNS. Adding one makes
  `wg-quick` call `resolvconf` and breaks resolver ownership.
- `resolv.conf` must stay `nameserver 127.0.0.1`. If something else rewrote it:
  `sudo rm /etc/resolv.conf && sudo resolvconf -u` (or let NM rewrite it).
- dnsmasq injects bypass IPs only on fresh queries; `sudo systemctl restart
  dnsmasq` forces a cache miss when testing.
