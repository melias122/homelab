#!/bin/bash

set -e

# https://golb.hplar.ch/2020/04/backup-restic.html

v="0.10.0"

# apt install apache2-utils
# cd /opt/restic/data
# htpasswd -B -c .htpasswd backup_user

rm -fr /opt/restic
mkdir -p /opt/restic

# if [ `grep -c "^restic" /etc/passwd` = 0 ]; then
#     adduser --system --shell /bin/false --gecos 'Restic Rest Server user' --group --disabled-password restic
# fi
# chown restic:restic -R /opt/restic

cat <<EOF > /opt/restic/rest-server.service
[Unit]
Description=Restic Rest Server
After=syslog.target
After=network.target

[Service]
Type=simple
User=root
Group=root
ExecStart=/opt/restic/rest-server --no-auth --append-only --path /backup
Restart=always
RestartSec=5

# Optional security enhancements
NoNewPrivileges=yes
PrivateTmp=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=/backup

[Install]
WantedBy=multi-user.target
EOF

cd /opt/restic/
echo `pwd`

wget -q https://github.com/restic/rest-server/releases/download/v${v}/rest-server_${v}_linux_amd64.tar.gz
tar xzf rest-server_${v}_linux_amd64.tar.gz
chmod +x rest-server_${v}_linux_amd64/rest-server
mv rest-server_${v}_linux_amd64/rest-server /opt/restic/

ln -sf /opt/restic/rest-server.service /lib/systemd/system/rest-server.service
systemctl daemon-reload
systemctl start rest-server
systemctl enable rest-server
systemctl status rest-server
