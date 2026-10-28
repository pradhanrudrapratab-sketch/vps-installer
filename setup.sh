#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Run with sudo."
    exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
    apt-get update
    apt-get install -y curl
fi

if ! command -v tailscale >/dev/null 2>&1; then
    curl -fsSL https://tailscale.com/install.sh | sh
fi

systemctl enable --now tailscaled

STATE="$(tailscale status --json 2>/dev/null || true)"

if printf '%s' "$STATE" | grep -q '"BackendState":"Running"'; then
    echo "Tailscale already running; preserving current connection."
else
    if [[ ! -r /dev/tty ]]; then
        echo "Interactive terminal required for Auth Key."
        exit 1
    fi

    read -r -s -p "Tailscale Auth Key: " AUTH_KEY </dev/tty
    echo
    [[ -n "$AUTH_KEY" ]] || { echo "Empty key."; exit 1; }

    tailscale up --auth-key="$AUTH_KEY"
    unset AUTH_KEY
fi

read -r -s -p "New root password: " P1 </dev/tty
echo
read -r -s -p "Confirm root password: " P2 </dev/tty
echo

if [[ -z "$P1" || "$P1" != "$P2" ]]; then
    unset P1 P2
    echo "Password mismatch or empty password."
    exit 1
fi

printf 'root:%s\n' "$P1" | chpasswd
unset P1 P2

echo "Root password updated."
tailscale status
echo "Tailscale IP:"
tailscale ip -4
