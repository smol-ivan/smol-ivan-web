#!/bin/bash
set -euxo pipefail

apt-get update
apt-get install -y ca-certificates curl gnupg

# Docker's official GPG keyring
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# Docker's official repository for Debian
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
$(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Let the 'admin' user run docker without sudo
usermod -aG docker admin

# --- Swap file ---
# t3.micro only has 1GB RAM. Running the web app, nginx, certbot, and
# optionally Kuma/Umami/Postgres alongside it can spike memory usage.
# A swap file acts as a safety net against the OOM killer.
if [ ! -f /swapfile ]; then
  fallocate -l ${swap_size_gb}G /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  echo "/swapfile none swap sw 0 0" >> /etc/fstab
  # Conservative swappiness: prefer RAM, only swap under real pressure
  sysctl vm.swappiness=10
  echo "vm.swappiness=10" >> /etc/sysctl.conf
fi

# Weekly cron: restart nginx every Sunday at 4:00 AM to pick up renewed SSL certs
echo "0 4 * * 0 root cd /home/admin/app && docker compose -f docker-compose.yml restart smol-ivan-web" | tee -a /etc/crontab
