#!/bin/bash

if [ "$(id -u)" -ne 0 ]; then
  echo "Este script debe ser ejecutado con privilegios de superusuario (sudo)." >&2
  exit 1
fi

if [ "$#" -lt 2 ]; then
  echo "Error: Faltan parámetros." >&2
  echo "Uso: $0 <nombre_ovs> <interfaz1> <interfaz2> ..." >&2
  exit 1
fi

OVS_BRIDGE_NAME=$1
shift

for iface in "$@"; do
  if [ "$iface" == "ens3" ]; then
    echo "ERROR CRÍTICO: Se ha intentado modificar la interfaz de gestión 'ens3'." >&2
    echo "Esta acción está prohibida para prevenir la pérdida de conexión. Abortando." >&2
    exit 1
  fi
done

if ovs-vsctl br-exists "$OVS_BRIDGE_NAME"; then
  ovs-vsctl del-br "$OVS_BRIDGE_NAME"
fi

ovs-vsctl add-br "$OVS_BRIDGE_NAME"

for iface in "$@"; do
  ip addr flush dev "$iface"
  ovs-vsctl add-port "$OVS_BRIDGE_NAME" "$iface"
done

ovs-vsctl show
echo "Inicialización del OFS finalizada."

exit 0