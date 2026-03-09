#!/bin/bash
set -e

read -p "Enter Tailscale Auth Key: " TS_KEY
if [ -z "$TS_KEY" ]; then
  echo "❌ Error: Tailscale Auth Key is required"
  exit 1
fi

echo "=== Installing EPEL ==="
dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm

echo "=== Installing MATE Desktop ==="
dnf groupinstall -y "MATE Desktop"
systemctl set-default graphical.target

echo "=== Installing xrdp ==="
dnf install -y xrdp xorgxrdp
systemctl enable --now xrdp

echo "=== Configure xrdp to use MATE ==="
echo "mate-session" > /home/cloud-user/.xsession
chown cloud-user:cloud-user /home/cloud-user/.xsession
chmod +x /home/cloud-user/.xsession

echo "=== Firewall ==="
if ! command -v firewall-cmd &> /dev/null; then
  dnf install -y firewalld
  systemctl enable --now firewalld
fi
firewall-cmd --permanent --add-port=3389/tcp
firewall-cmd --permanent --add-service=ssh
firewall-cmd --reload

echo "=== Installing Tailscale ==="
curl -fsSL https://tailscale.com/install.sh | sh
systemctl enable --now tailscaled
tailscale up --authkey=$TS_KEY --accept-routes --ssh

echo "✅ Done! Connect via RDP to:"
tailscale ip -4
