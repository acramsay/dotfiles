#!/usr/bin/env bash
# Refresh dnsmasq's Tailscale MagicDNS hosts and ordered upstream servers.
# Invoked by vpn-dns.service (timer + ot:vpn-up/ot:vpn-down); see docs/vpn.md.
set -euo pipefail

TAILSCALE=/usr/bin/tailscale
JQ=/usr/bin/jq
HOSTS_DIR=/etc/dnsmasq.d/hosts.d
HOSTS_FILE=$HOSTS_DIR/tailscale.hosts
SERVERS_FILE=/etc/dnsmasq.d/dnsmasq.servers

# up | down | auto ("auto" infers from the tunnel interface).
MODE="${1:-auto}"
if [ "$MODE" = auto ]; then
  if ip link show proton >/dev/null 2>&1; then MODE=up; else MODE=down; fi
fi

# dnsmasq_t reads only dnsmasq_etc_t; no-op when SELinux is not enforcing.
relabel() {
  [ -e /sys/fs/selinux/enforce ] || return 0
  chcon -t dnsmasq_etc_t "$@"
}

install -d -m 0755 "$HOSTS_DIR"
relabel "$HOSTS_DIR"

# --- Tailscale MagicDNS names -> hosts file (IPv4 tailnet addresses only) ---
hosts_tmp=$(mktemp)
status_tmp=$(mktemp)
if "$TAILSCALE" status --json > "$status_tmp"; then
  "$JQ" -r '
    def emit($dns; $ips):
      ($dns | sub("\\.$"; "")) as $fqdn
      | ($fqdn | split(".")[0]) as $short
      | $ips[]
      | select(test(":") | not)
      | "\(.) \($short) \($fqdn)";
    (.Self | select(.DNSName != null) | emit(.DNSName; .TailscaleIPs)),
    (.Peer[] | select(.DNSName != null) | emit(.DNSName; .TailscaleIPs))
  ' < "$status_tmp" > "$hosts_tmp"
else
  echo "vpn-dns-refresh: tailscale status unavailable; MagicDNS hosts left empty" >&2
  : > "$hosts_tmp"
fi
install -m 0644 "$hosts_tmp" "$HOSTS_FILE"
relabel "$HOSTS_FILE"
rm -f "$hosts_tmp" "$status_tmp"

# --- ordered upstreams -> servers-file ---
gateway=$(ip route show table main | awk '$1 == "default" && $2 == "via" { print $3; exit }')
servers_tmp=$(mktemp)
if [ "$MODE" = up ]; then
  # Proton's resolver is the gateway of the tunnel /24.
  proton_addr=$(ip -4 -o addr show dev proton | awk '{ print $4; exit }' | cut -d/ -f1)
  if [ -n "$proton_addr" ]; then
    printf 'server=%s\n' "${proton_addr%.*}.1" > "$servers_tmp"
  fi
fi
if [ -n "$gateway" ]; then
  printf 'server=%s\n' "$gateway" >> "$servers_tmp"
fi

# servers-file is re-read only on SIGHUP, so signal only when it actually changed.
if ! cmp -s "$servers_tmp" "$SERVERS_FILE"; then
  install -m 0644 "$servers_tmp" "$SERVERS_FILE"
  relabel "$SERVERS_FILE"
  systemctl kill -s HUP dnsmasq || true
fi
rm -f "$servers_tmp"
