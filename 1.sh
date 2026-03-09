#!/bin/bash
set -e

# Tailscale Auth Key 
read -p "Enter Tailscale Auth Key: " TS_KEY
if [ -z "$TS_KEY" ]; then
  echo "❌ Error: Tailscale Auth Key is required"
  exit 1
fi

echo "=== Installing EPEL ==="
dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm

echo "=== Installing xrdp ==="
dnf install -y xrdp xorgxrdp
systemctl enable --now xrdp

echo "=== Firewall ==="
firewall-cmd --permanent --add-port=3389/tcp
firewall-cmd --permanent --add-service=ssh
firewall-cmd --reload

echo "=== Installing Tailscale ==="
curl -fsSL https://tailscale.com/install.sh | sh
systemctl enable --now tailscaled
tailscale up --authkey=$TS_KEY --accept-routes --ssh

echo "=== GNOME session ==="
echo "gnome-session" > /home/cloud-user/.xsession
chown cloud-user:cloud-user /home/cloud-user/.xsession

echo "✅ Done! Connect via Tailscale IP"
tailscale ip -4
