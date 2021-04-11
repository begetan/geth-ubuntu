#!/bin/bash
set -euo pipefail

echo "Geth has not direct link to the checksum and latest version"
echo "Edit parameters in the script manually from https://geth.ethereum.org/downloads/"

geth_version="1.10.2"
geth_commit="97d11b01"
geth_hash="defd2333d2d646836dc42469053db076" # for amd64

# Select proper achitecture
arch=$(uname -m)
arch=${arch/x86_64/amd64}
arch=${arch/aarch64/arm64}
arch=${arch/armv6l/arm6}
arch=${arch/armv7l/arm7}
readonly os_arch_suffix="$(uname -s | tr '[:upper:]' '[:lower:]')-$arch"

# Select proper OS version
system=""
case "$OSTYPE" in
darwin*) system="darwin" ;;
linux*) system="linux" ;;
*) exit 1 ;;
esac

if [[ "$os_arch_suffix" == *"arm64"* ]]; then
    arch="arm64"
fi

geth="geth-$system-$arch-$geth_version-$geth_commit"

echo "==> Install Geth binary"
wget -q -O "/tmp/$geth.tar.gz" "https://gethstore.blob.core.windows.net/builds/$geth.tar.gz"
wget -q -O "/tmp/$geth.tar.gz.asc" "https://gethstore.blob.core.windows.net/builds/$geth.tar.gz.asc"

gpg --keyserver hkp://keyserver.ubuntu.com --recv-key 9BA28146
gpg --verify "/tmp/$geth.tar.gz.asc"

md5sum  -c <(echo "$geth_hash" "/tmp/$geth.tar.gz")

tar -xzf "/tmp/$geth.tar.gz" -C /tmp/
cp "/tmp/$geth/geth" /usr/local/bin/geth
chown root.root /usr/local/bin/geth


echo "==> Check geth paths"
if [[ ! -d "/var/lib/geth/data" ]]
then
  echo "  Create data path /var/lib/geth/data"
  mkdir -m0700 -p /var/lib/geth/data
else
  echo "  Found existing directory at /var/lib/geth/data"
  echo "  Reload geth service"  
  systemctl reload geth.service
  exit 0
fi

echo "==> Add ethereum user"
useradd -r -m -d /var/lib/geth ethereum -s /bin/bash
chown ethereum.ethereum /var/lib/geth/data

echo "==> Create systemd config"
cat << EOF > /etc/systemd/system/geth.service
[Unit]
Description=Ethereum daemon
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=ethereum
Group=ethereum
WorkingDirectory=/var/lib/geth

# /run/geth
RuntimeDirectory=geth
RuntimeDirectoryMode=0710

ExecStartPre=+/bin/chown -R ethereum:ethereum /usr/local/bin/geth /var/lib/geth
ExecStart=/usr/local/bin/geth --nousb --cache=512 --datadir=/var/lib/geth/data \
  --ws --wsorigins '*' --ws.api eth,net,web3,debug \
  --http --http.vhosts '*' --http.corsdomain '*' --http.api eth,net,web3,debug
 
PIDFile=/run/geth/geth.pid
StandardOutput=journal
StandardError=journal
KillMode=process
TimeoutSec=180
Restart=always
RestartSec=60

[Install]
WantedBy=multi-user.target
EOF
chmod 0644 /etc/systemd/system/geth.service
chown root.root /etc/systemd/system/geth.service

echo "==> Create syslog config"
echo ':programname, startswith, "geth" /var/log/geth/geth.log' > /etc/rsyslog.d/100-geth.conf
chown root.root /etc/rsyslog.d/100-geth.conf
chmod 0644 /etc/rsyslog.d/100-geth.conf
systemctl restart rsyslog.service

echo "==> Create logrotate config"
cat << EOF > /etc/logrotate.d/geth
/var/log/geth/geth.log
{
  rotate 5
  daily
  copytruncate
  missingok
  notifempty
  compress
  delaycompress
  sharedscripts
}
EOF
chown root.root /etc/logrotate.d/geth
chmod 0644 /etc/logrotate.d/geth
logrotate -f /etc/logrotate.d/geth

echo "==> Update daemon"
systemctl daemon-reload
systemctl enable geth.service --now
