#!/usr/bin/env bash

## grpc模组 grpc moudle

set +e

install_grpc(){

apt-get install unzip -y
mkdir /etc/tmp/
cd /etc/tmp/
curl -LO --retry 5 https://github.com/XTLS/Xray-core/releases/download/v1.5.4/Xray-linux-64.zip
unzip Xray-linux-64.zip
rm Xray-linux-64.zip
cp -f xray /usr/bin/xray
cp -f geoip.dat /usr/bin/geoip.dat
cp -f geosite.dat /usr/bin/geosite.dat
chmod +X /usr/bin/xray
cd /root
rm -rf /etc/tmp
mkdir /etc/grpc
cd /etc/grpc
  cat > 'server.json' << "EOF"
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "port": 2002,
      "listen": "127.0.0.1",
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "49ec002d-ca69-4325-aea5-dbef18dd6f42"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "grpc",
        "grpcSettings": {
          "serviceName": "/grpc"
        }
      }
    },
    {
      "port": 2022,
      "listen": "127.0.0.1",
      "protocol": "trojan",
      "tag": "trojangRPC",
        "settings": {
            "clients": [
                {
                    "password": "49ec002d-ca69-4325-aea5-dbef18dd6f42"
                }
            ]
        },
        "streamSettings": {
            "network": "grpc",
            "grpcSettings": {
                "serviceName": "/grpc_trojan"
            }
        }
    }
  ],
  "outbounds": [
    {
      "tag": "direct",
      "protocol": "freedom",
      "settings": {}
    },
    {
      "tag": "blocked",
      "protocol": "blackhole",
      "settings": {}
    }
  ],
  "routing": {
    "domainStrategy": "IPIfNonMatch",
    "rules": [
      {
        "type": "field",
        "ip": [
          "geoip:private"
        ],
        "outboundTag": "direct"
      },
      {
        "type": "field",
        "domain": [
          "geosite:category-ads"
        ],
        "outboundTag": "blocked"
      }
    ]
  }
}
EOF

uuid_new=$(/usr/bin/xray uuid -i "${password1}")
path_new=$(/usr/bin/xray uuid -i "${password1}" | cut -c1-6 )
sed -i "s/49ec002d-ca69-4325-aea5-dbef18dd6f42/${uuid_new}/g" server.json
sed -i "s/\/grpc/\/${path_new}/g" server.json

  cat > '/etc/systemd/system/grpc.service' << EOF
[Unit]
Description=Vless(Grpc) Service
Wants=network-online.target
After=network-online.target nss-lookup.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/xray -c /etc/grpc/server.json
TimeoutStopSec=infinity
LimitNOFILE=65536
Restart=always
RestartSec=3s

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable grpc.service
systemctl restart grpc.service

cd /root
}
