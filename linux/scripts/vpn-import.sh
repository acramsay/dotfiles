#!/usr/bin/env bash
set -euo pipefail

# Import a downloaded Proton WireGuard config; run via `task ot:vpn-import`. See docs/vpn.md.

target=${1:-}
source=${2:-}
if [ -z "$target" ] || [ -z "$source" ]; then
  echo "usage: $(basename "$0") <target proton.conf> <downloaded.conf>" >&2
  exit 2
fi
source=${source/#\~/$HOME}
[ -f "$target" ] || { echo "target not found: $target" >&2; exit 1; }
[ -f "$source" ] || { echo "downloaded config not found: $source" >&2; exit 1; }

field() { # <section> <key> <file>
  awk -v want="$1" -v key="$2" '
    /^\[/ { section = tolower($0); next }
    section != "[" tolower(want) "]" { next }
    {
      line = $0; sub(/#.*/, "", line)
      if (line !~ /^[[:space:]]*[A-Za-z]+[[:space:]]*=/) next
      k = line; sub(/=.*/, "", k); gsub(/[[:space:]]/, "", k)
      if (tolower(k) != tolower(key)) next
      v = line; sub(/^[^=]*=/, "", v); gsub(/^[[:space:]]+|[[:space:]]+$/, "", v)
      if (v != "") { print v; exit }
    }
  ' "$3"
}

private_key=$(field Interface PrivateKey "$source")
address=$(field Interface Address "$source")
public_key=$(field Peer PublicKey "$source")
endpoint=$(field Peer Endpoint "$source")

missing=()
[ -n "$private_key" ] || missing+=(PrivateKey)
[ -n "$address" ] || missing+=(Address)
[ -n "$public_key" ] || missing+=(PublicKey)
[ -n "$endpoint" ] || missing+=(Endpoint)
if [ "${#missing[@]}" -gt 0 ]; then
  echo "not a usable Proton WireGuard config (missing: ${missing[*]}): $source" >&2
  exit 1
fi

case "$address" in
  *10.[0-9]*.0.2/32*) : ;;
  *) echo "warning: unexpected IPv4 Address in '$address' — Proton single-tunnel default is 10.N.0.2/32" >&2 ;;
esac
case "$address" in
  *:*) : ;;
  *)
    echo "error: '$address' has no IPv6 address. This setup advertises ::/0, so a" >&2
    echo "v4-only server would black-hole client v6 traffic. Pick an IPv6-capable server." >&2
    exit 1
    ;;
esac

new_conf=$(mktemp "$(dirname "$target")/.vpn-import.XXXXXX")
key_tmp=$(mktemp)
trap 'rm -f "$new_conf" "$key_tmp"' EXIT

awk -v addr="$address" -v pub="$public_key" -v ep="$endpoint" '
  /^Address[[:space:]]*=/   { print "Address = " addr; a=1; next }
  /^PublicKey[[:space:]]*=/ { print "PublicKey = " pub; p=1; next }
  /^Endpoint[[:space:]]*=/  { print "Endpoint = " ep; e=1; next }
  { print }
  END { if (!a || !p || !e) { print "target is missing an Address/PublicKey/Endpoint line" > "/dev/stderr"; exit 1 } }
' "$target" > "$new_conf"

printf '%s\n' "$private_key" > "$key_tmp"

sudo -v
sudo cp -f "$target" /etc/wireguard/proton.conf.prev
if sudo test -s /etc/wireguard/proton.key; then
  sudo cp -f /etc/wireguard/proton.key /etc/wireguard/proton.key.prev
fi
sudo install -o root -g root -m 600 "$key_tmp" /etc/wireguard/proton.key
mv -f "$new_conf" "$target"
sudo rm -f /etc/wireguard/proton.conf
sudo install -o root -g root -m 644 "$target" /etc/wireguard/proton.conf

echo "Active config: $source"
echo "  Address  = $address"
echo "  Endpoint = $endpoint"
echo "Previous config saved to /etc/wireguard/proton.conf.prev and proton.key.prev"
if [ -d /sys/class/net/proton ]; then
  echo "Tunnel is up — apply with: task ot:vpn-down && task ot:vpn-up"
else
  echo "Tunnel is down — start it with: task ot:vpn-up"
fi
