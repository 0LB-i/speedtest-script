#!/bin/bash

# Install and configure OoklaServer
cd /opt || exit 1
wget https://install.speedtest.net/ooklaserver/ooklaserver.sh
chmod a+x ooklaserver.sh
./ooklaserver.sh install -f

# Modify settings in the OoklaServer.properties file
sed -i \
    -e 's/# OoklaServer\.allowedDomains = \*\.ookla\.com, \*\.speedtest\.net/OoklaServer.allowedDomains = \*\.ookla\.com, \*\.speedtest\.net/' \
    -e 's/# OoklaServer.enableAutoUpdate = true/OoklaServer.enableAutoUpdate = true/' \
    -e 's/# OoklaServer.ssl.useLetsEncrypt = true/OoklaServer.ssl.useLetsEncrypt = true/' \
    -e 's/# OoklaServer.ipTracking.maxConnPerIp = 500/OoklaServer.ipTracking.maxConnPerIp = 5/' \
    ./OoklaServer.properties

# Check connectivity with Ookla's API
curl -v https://host-api.speedtest.net
/opt/ooklaserver.sh stop

# Create systemd service
cat << 'EOF' > /etc/systemd/system/ookla.service
[Unit]
Description=OoklaServer-SpeedTest
After=network.target

[Service]
User=root
Group=root
Type=forking
RemainAfterExit=no

WorkingDirectory=/opt/ooklaserver
ExecStart=/opt/ooklaserver.sh start
ExecReload=/opt/ooklaserver.sh restart
#ExecStop=/opt/ooklaserver.sh stop
ExecStop=/usr/bin/killall -9 OoklaServer

TimeoutStartSec=30
TimeoutStopSec=30

[Install]
WantedBy=multi-user.target
Alias=speedtest.service
EOF

# Reload systemd and enable the service to start on boot
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable --now ookla.service
