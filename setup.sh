#!/usr/bin/env bash
set -Eeuo pipefail

# Fill these in locally. Do NOT publish real credentials.
AUTH_KEY="PASTE_TAILSCALE_AUTH_KEY_HERE"
ROOT_PASSWORD="PASTE_ROOT_PASSWORD_HERE"

if [[ $EUID -ne 0 ]]; then
  echo "Run with sudo."
  exit 1
fi

if [[ "$AUTH_KEY" == PASTE_* || "$ROOT_PASSWORD" == PASTE_* ]]; then
  echo "Configure AUTH_KEY and ROOT_PASSWORD before running."
  exit 1
fi

command -v curl >/dev/null 2>&1 || {
  apt-get update
  apt-get install -y curl
}

command -v tailscale >/dev/null 2>&1 || {
  curl -fsSL https://tailscale.com/install.sh | sh
}

systemctl enable --now tailscaled
tailscale up --auth-key="$AUTH_KEY"
printf 'root:%s\n' "$ROOT_PASSWORD" | chpasswd

unset AUTH_KEY ROOT_PASSWORD

echo "Setup complete."
echo "Tailscale status:"
tailscale status
echo "Tailscale IPv4:"
tailscale ip -4
