#!/bin/bash
set -e

read -p "Enter Tailscale Auth Key: " TS_KEY
if [ -z "$TS_KEY" ]; then
  echo "❌ Error: Tailscale Auth Key is required"
  exit 1
fi

echo "=== Installing EPEL ==="
dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm

echo "=== Installing KDE Plasma ==="
dnf groupinstall -y "KDE Plasma Workspaces"
systemctl set-default graphical.target

echo "=== Installing xrdp ==="
dnf install -y xrdp xorgxrdp
systemctl enable --now xrdp

echo "=== Configure xrdp to use KDE ==="
cat > /home/cloud-user/.xsession << 'XSESSION'
#!/bin/sh
export DESKTOP_SESSION=plasma
export XDG_SESSION_DESKTOP=KDE
startplasma-x11
XSESSION
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
