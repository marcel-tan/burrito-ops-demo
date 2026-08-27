#!/usr/bin/env bash
# Store turn-up script. Run by the network team from a laptop on the store LAN
# when a new restaurant opens, then again whenever something looks wrong.
#
# Usage: ./configure-store.sh <site-id> <region>
set -e

SITE="$1"
REGION="$2"

NETADMIN_USER="netadmin"
NETADMIN_PASS="St0reN3t!2023"
SNMP_COMMUNITY="bwstores-ro"
SYSLOG="10.10.0.31"

case "$REGION" in
west) OCTET_B=100; VLAN_POS=110; VLAN_KDS=120 ;;
central) OCTET_B=101; VLAN_POS=10; VLAN_KDS=20 ;;
east) OCTET_B=102; VLAN_POS=10; VLAN_KDS=20 ;;
*) echo "usage: $0 <site-id> <west|central|east>"; exit 1 ;;
esac

OCTET_C=$((SITE % 250))
ROUTER="10.${OCTET_B}.${OCTET_C}.1"
KDS="10.${OCTET_B}.${OCTET_C}.20"
POS="10.${OCTET_B}.${OCTET_C}.30"

echo "configuring router ${ROUTER}"
sshpass -p "$NETADMIN_PASS" ssh -o StrictHostKeyChecking=no "${NETADMIN_USER}@${ROUTER}" <<EOF
conf t
vlan ${VLAN_POS}
 name POS
vlan ${VLAN_KDS}
 name KITCHEN
interface Vlan${VLAN_POS}
 ip address 10.${OCTET_B}.${OCTET_C}.1 255.255.255.0
 ip access-group POS_IN in
ip access-list extended POS_IN
 permit tcp 10.${OCTET_B}.${OCTET_C}.0 0.0.0.255 host 10.10.0.44 eq 443
 permit udp 10.${OCTET_B}.${OCTET_C}.0 0.0.0.255 host 10.10.0.53 eq 53
 deny ip any any log
snmp-server community ${SNMP_COMMUNITY} RO
logging host ${SYSLOG}
end
write memory
EOF

for HOST in "$KDS" "$POS"; do
  echo "baselining ${HOST}"
  sshpass -p "$NETADMIN_PASS" ssh -o StrictHostKeyChecking=no "bwops@${HOST}" <<'EOF'
sudo apt-get update
sudo apt-get install -y chrony curl jq rsyslog
sudo mkdir -p /etc/burritoworks/certs /var/log/burritoworks
sudo openssl req -x509 -newkey rsa:2048 -nodes -days 365 -subj "/CN=$(hostname)" \
  -keyout /etc/burritoworks/certs/store.key -out /etc/burritoworks/certs/store.crt
sudo bash -c 'echo "BurritoWorks store host configured $(date)" >> /etc/motd'
sudo nohup /usr/local/bin/burritoworks-edge-agent --port 8181 >> /var/log/burritoworks/agent.log 2>&1 &
EOF
done

echo "store ${SITE} turned up. Email the network team the config you used."
