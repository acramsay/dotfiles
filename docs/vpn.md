# VPN + DNS

Proton WireGuard tunnel chained behind Tailscale's exit node, with split DNS and
a DNS-driven bypass whitelist. Everything lives in this repo; only the Proton
private key is machine-local.

## What it does

- **Tunnel** — `wg-quick@proton.service` (enabled by `ot:init`, so it starts at
  boot) runs `wg-quick up proton`, dual-stack; `task ot:vpn-up`/`ot:vpn-down`
  start/stop it. Tailscale routes exit-node traffic through it; Proton NAT66s the
  tunnel's v6 address. The LAN itself has no native IPv6, so there is no v6
  bypass path — all v6 egresses via Proton.
- **Forwarding** — `linux/etc/sysctl.d/99-vpn-forwarding.conf` enables IPv4 and
  IPv6 forwarding; `ot:init` applies it.
- **Split DNS** — dnsmasq is the single stub resolver (`127.0.0.1`) in *both*
  tunnel states, and also answers tailnet peers on `tailscale0`. Lookup order:
  local/hosts → Tailscale MagicDNS → default upstreams (Proton while the tunnel
  is up, LAN gateway always).
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
   through to the gateway (a DNS leak). The refresh runs from `vpn-dns.service` —
   by the timer (boot + every 10 min) and from `ot:vpn-up`/`ot:vpn-down`. It is
   not run from the wg-quick hooks: `wg-quick@proton.service` is confined as
   `wireguard_t`, which cannot write dnsmasq's files or signal it.
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

Exit-node clients send **all** their DNS to the exit node over the tailnet;
tailscaled forwards it to the first nameserver in this machine's
`/etc/resolv.conf` — dnsmasq. `--accept-dns=false` does not change this. MagicDNS
names resolve client-side, so clients do not need the exit node for them.

The exit node and DNS prefs are set with:

```sh
sudo tailscale set --advertise-exit-node --accept-dns=false
```

## Bypass mechanism

`/etc/wireguard/vpn-bypass.nft`, table `ip vpn_bypass`:

- `prerouting` (filter) and `output` (**type route**) chains mark packets whose
  destination is in the `bypass` set with `0x100`.
- `0x100` is a bit no other component uses (wg-quick's fwmark is `0xca6c`,
  Tailscale's marks are `0x40000`/`0x80000`), and every match is masked because
  forwarded tailnet traffic also carries Tailscale's mark. The prerouting chain
  runs at `priority mangle + 1`, after wg-quick's premangle chain, which rewrites
  the whole mark on UDP packets.
- The output chain must be `type route`: a `filter` output hook runs *after* the
  routing decision and cannot re-route on a mark change.
- `postrouting` masquerades marked traffic — after re-routing, the source is still
  the tunnel address, which is unroutable via the LAN.
- Routing: `ip rule fwmark 0x100/0x100 lookup 200` (priority 5207); table 200
  holds the live LAN default route (copied by `PreUp`), so marked traffic bypasses
  the tunnel.

dnsmasq injects bypass IPs on a *fresh* upstream query (`nftset=`), not on cache
hits. The table is recreated empty on each tunnel up, so a reload plus a fresh
query repopulates it.

## Tailnet return path

wg-quick's catch-all default route would otherwise swallow traffic to
`100.64.0.0/10` — replies to exit-node clients and this machine's own traffic to
peers. `PostUp` adds, ahead of wg-quick's rules:

```sh
ip rule add to 100.64.0.0/10 lookup 52 priority 5200
ip -6 rule add to fd7a:115c:a1e0::/48 lookup 52 priority 5200
```

so tailnet-bound traffic uses Tailscale's table 52. `PreDown` removes them.

## firewalld

`tailscale0` must be in the `trusted` zone. In the default `public` zone,
firewalld rejects inbound connections to services (opencode, syncthing, …) and
forwarded traffic that exits via `proton` (the public zone's forward allow only
covers `enp18s0`). `ot:init` applies the zone idempotently:

```sh
sudo firewall-cmd --zone=trusted --add-interface=tailscale0             # runtime
sudo firewall-cmd --permanent --zone=trusted --add-interface=tailscale0 # persists
```

Avoid `firewall-cmd --reload`: on some systems it drops Tailscale's netfilter
tables, so tailscaled must be restarted afterwards. Tailscale ACLs remain the
access control for the tailnet.

## Files

Repo → deployed (`task ot:deploy-etc`):

| Repo | Deployed | Mode |
|---|---|---|
| `linux/etc/wireguard/proton.conf` | `/etc/wireguard/proton.conf` | **copy** |
| `linux/etc/wireguard/vpn-bypass.nft` | `/etc/wireguard/vpn-bypass.nft` | **copy** |
| `linux/etc/sysctl.d/99-vpn-forwarding.conf` | `/etc/sysctl.d/99-vpn-forwarding.conf` | **copy** |
| `linux/etc/dnsmasq.d/vpn-bypass.conf` | `/etc/dnsmasq.d/vpn-bypass.conf` | **copy** |
| `linux/etc/resolv.conf` | `/etc/resolv.conf` | **copy** |
| `linux/etc/NetworkManager/conf.d/90-dns.conf` | `/etc/NetworkManager/conf.d/90-dns.conf` | **copy** |
| `linux/etc/systemd/system/vpn-dns.service` | `/etc/systemd/system/vpn-dns.service` | **copy** |
| `linux/etc/systemd/system/vpn-dns.timer` | `/etc/systemd/system/vpn-dns.timer` | **copy** |
| `linux/etc/tailscale/vpn-dns-refresh.sh` | `/etc/tailscale/vpn-dns-refresh.sh` | symlink |
| `linux/selinux/dnsmasq-nftset.te` | compiled into the SELinux policy | — |

Copies (not symlinks) are required because confined daemons — systemd `init_t`,
`NetworkManager_t`, `dnsmasq_t`, and `wireguard_t` (the `wg-quick@proton.service`
domain) — cannot read symlinks whose targets live under `$HOME`.
`vpn-dns-refresh.sh` stays a symlink because only `/usr/bin/bash` runs it (via
`vpn-dns.service` and manual `sudo`, both unconfined). It writes its generated
files under `/etc/dnsmasq.d/` (SELinux type `dnsmasq_etc_t`) because `dnsmasq_t`
cannot read `/var/lib`.

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
| `task ot:init` | Packages, deploy `/etc`, apply forwarding sysctls, trust `tailscale0`, install SELinux module, enable dnsmasq + timer + tunnel service |
| `task ot:vpn-up` / `ot:vpn-down` | Start / stop `wg-quick@proton.service` (same hooks as a manual `wg-quick`, plus boot ordering) and refresh dnsmasq upstreams |
| `task ot:vpn-rescue` | Emergency rollback: tunnel down, remove rules/tables, restore LAN resolver |
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
comments and `AllowedIPs` preserved), installs the updated file to the deployed
copy at `/etc/wireguard/proton.conf`, and writes the `PrivateKey` to
`/etc/wireguard/proton.key`, snapshotting the previous pair to `*.prev`. It
rejects v4-only configs — the exit node advertises `::/0`, so the server must
support IPv6. It does **not** touch the live tunnel — apply by bouncing it. Keep
several downloaded configs and re-import to swap back. Verify with
`task ot:vpn-status`.

## Rollback

**Emergency** — `task ot:vpn-rescue` (offline, idempotent): stops the tunnel
service, removes the `vpn_bypass` table and every policy rule it may have left,
flushes tables 200/201, regenerates dnsmasq upstreams, and points
`/etc/resolv.conf` at the LAN gateway. It leaves dnsmasq and Tailscale running.
Manual equivalent if the repo is unavailable:

```sh
printf 'nameserver 192.168.40.1\nsearch lan\n' | sudo tee /etc/resolv.conf
```

**Undo a bad import** (restore the snapshotted pair, then bounce):

```sh
sudo install -o root -g root -m 600 /etc/wireguard/proton.key.prev /etc/wireguard/proton.key
sudo install -o root -g root -m 644 /etc/wireguard/proton.conf.prev /etc/wireguard/proton.conf
sudo install -o $USER -g $USER -m 644 /etc/wireguard/proton.conf.prev ~/git/dotfiles/linux/etc/wireguard/proton.conf
task ot:vpn-down && task ot:vpn-up
```

Full teardown and restore of pre-work networking:

```sh
sudo systemctl disable --now wg-quick@proton.service vpn-dns.timer vpn-dns.service dnsmasq
sudo rm -f /etc/dnsmasq.d/vpn-bypass.conf /etc/dnsmasq.d/dnsmasq.servers
sudo rm -f /etc/dnsmasq.d/vpn-upstream.conf
sudo rm -rf /etc/dnsmasq.d/hosts.d
sudo rm -f /etc/wireguard/proton.conf /etc/wireguard/vpn-bypass.nft
sudo rm -f /etc/sysctl.d/99-vpn-forwarding.conf && sudo systemctl restart systemd-sysctl
sudo rm -f /etc/NetworkManager/conf.d/90-dns.conf
sudo rm -f /etc/systemd/system/vpn-dns.service /etc/systemd/system/vpn-dns.timer
sudo rm -rf /etc/tailscale
sudo semodule -r dnsmasq-nftset
sudo systemctl daemon-reload
sudo firewall-cmd --permanent --zone=trusted --remove-interface=tailscale0
sudo firewall-cmd --reload && sudo systemctl restart tailscaled
sudo rm -f /etc/resolv.conf && sudo systemctl restart NetworkManager
sudo tailscale set --accept-dns=true    # re-enable MagicDNS
```

The pre-work state was NetworkManager owning `/etc/resolv.conf` (`1.1.1.1`,
`1.0.0.1`, `search lan`) with MagicDNS enabled, no `proton` tunnel,
`vpn_bypass` table, `0x100` rules, or forwarding sysctls. `/etc/resolv.conf.bak`
is the captured original if NM does not rewrite it. Then revert the repo so a later `task cs` /
`ot:init` cannot re-apply it, and optionally drop packages added by this work
(`openresolv`) plus the linger setting and `/etc/sudoers.d/$USER` from `ot:init`.
A reboot guarantees no leftover interface, rules, or nft table.

## Gotchas

- IPv6 requires a server that supports it (~80% do). `vpn-import` rejects v4-only
  configs because the exit node advertises `::/0`; a v4-only tunnel would
  black-hole client v6. All v6 egresses via Proton — there is no v6 bypass
  because the LAN has no IPv6.
- After `firewall-cmd --reload`, Tailscale's netfilter tables may be gone until
  `sudo systemctl restart tailscaled` (see firewalld).
- Take the tunnel down with `task ot:vpn-down`, not a bare `wg-quick down`: the
  unit would still look active and a later `ot:vpn-up` (`systemctl start`) would
  be a no-op.
- `proton.conf` must have no `DNS=` line; dnsmasq owns DNS. Adding one makes
  `wg-quick` call `resolvconf` and breaks resolver ownership.
- `resolv.conf` must stay `nameserver 127.0.0.1`. If something else rewrote it:
  `sudo rm /etc/resolv.conf && sudo resolvconf -u` (or let NM rewrite it).
- dnsmasq injects bypass IPs only on fresh queries; `sudo systemctl restart
  dnsmasq` forces a cache miss when testing.
