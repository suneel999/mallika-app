#!/usr/bin/env bash
# First-time setup for a new Ubuntu 24.04 EC2 server. Run once with sudo.
set -euo pipefail

apt-get update
apt-get install -y docker.io docker-compose-v2 git unattended-upgrades
snap install aws-cli --classic

# Let the default user run docker without sudo. Sign out and in for it to apply.
usermod -aG docker ubuntu

# A small server builds two images. Swap keeps the build from running out of memory.
if [ ! -f /swapfile ]; then
  fallocate -l 2G /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  echo "/swapfile none swap sw 0 0" >> /etc/fstab
fi

# Security updates install by themselves.
dpkg-reconfigure -f noninteractive unattended-upgrades

systemctl enable --now docker
echo "Server is ready. Sign out, sign in again, then follow infra/README.md."
