#!/bin/bash

if [ "$(id -u)" -ne 0 ]; then
  echo "Este script debe ser ejecutado con privilegios de superusuario (sudo)." >&2
  exit 1
fi

if [ "$#" -ne 3 ]; then
  echo "Error: Faltan parámetros." >&2
  echo "Uso: $0 <nombre_ovs> <interfaz_datos> <interfaz_internet>" >&2
  exit 1
fi

OVS_BRIDGE_NAME=$1
DATA_IFACE=$2
INTERNET_IFACE=$3
VLAN_IDS=(100 200 300)
SUBNET_PREFIXES=("192.168.10" "192.168.20" "192.168.30")

if ovs-vsctl br-exists "$OVS_BRIDGE_NAME"; then
  ovs-vsctl del-br "$OVS_BRIDGE_NAME"
fi

ovs-vsctl add-br "$OVS_BRIDGE_NAME"
ip addr flush dev "$DATA_IFACE"
ovs-vsctl add-port "$OVS_BRIDGE_NAME" "$DATA_IFACE"

for i in "${!VLAN_IDS[@]}"; do
  vlan_id=${VLAN_IDS[$i]}
  subnet_prefix=${SUBNET_PREFIXES[$i]}
  vlan_iface="vlan${vlan_id}"

  ovs-vsctl add-port "$OVS_BRIDGE_NAME" "$vlan_iface" -- set interface "$vlan_iface" type=internal
  ovs-vsctl set port "$vlan_iface" tag="$vlan_id"

  ip addr add "${subnet_prefix}.1/24" dev "$vlan_iface"
  ip link set "$vlan_iface" up

  DNSMASQ_CONFIG_FILE="/etc/dnsmasq.d/${vlan_iface}.conf"
  echo "interface=${vlan_iface}" > "$DNSMASQ_CONFIG_FILE"
  echo "dhcp-range=${subnet_prefix}.10,${subnet_prefix}.100,255.255.255.0,12h" >> "$DNSMASQ_CONFIG_FILE"
  echo "dhcp-option=option:router,${subnet_prefix}.1" >> "$DNSMASQ_CONFIG_FILE"
  echo "dhcp-option=option:dns-server,8.8.8.8" >> "$DNSMASQ_CONFIG_FILE"
done

systemctl restart dnsmasq

echo 1 > /proc/sys/net/ipv4/ip_forward

iptables -t nat -F POSTROUTING
iptables -t filter -F FORWARD
iptables -t nat -A POSTROUTING -o "$INTERNET_IFACE" -j MASQUERADE
iptables -A FORWARD -i "$OVS_BRIDGE_NAME" -o "$INTERNET_IFACE" -j ACCEPT
iptables -A FORWARD -i "$INTERNET_IFACE" -o "$OVS_BRIDGE_NAME" -m state --state RELATED,ESTABLISHED -j ACCEPT

ovs-vsctl show
echo "Inicialización del Headnode finalizada."

exit 0