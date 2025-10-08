#!/bin/bash

if [ "$(id -u)" -ne 0 ]; then
  echo "Este script debe ser ejecutado con privilegios de superusuario (sudo)." >&2
  exit 1
fi

if [ "$#" -ne 4 ]; then
  echo "Error: Número incorrecto de parámetros." >&2
  echo "Uso: $0 <nombre_vm> <nombre_ovs> <vlan_id> <puerto_vnc>" >&2
  exit 1
fi

VM_NAME=$1
OVS_BRIDGE_NAME=$2
VLAN_ID=$3
VNC_PORT=$4

TAP_IF_NAME="tap-${VM_NAME}"
IMAGE_NAME="cirros-0.5.1-x86_64-disk.img"

if [ ! -f "$IMAGE_NAME" ]; then
    echo "Error: No se encuentra el archivo de imagen '$IMAGE_NAME'." >&2
    exit 1
fi

ip tuntap add dev "$TAP_IF_NAME" mode tap
ip link set "$TAP_IF_NAME" up
ovs-vsctl add-port "$OVS_BRIDGE_NAME" "$TAP_IF_NAME"
ovs-vsctl set port "$TAP_IF_NAME" tag="$VLAN_ID"

qemu-system-x86_64 \
    -name "$VM_NAME" \
    -enable-kvm \
    -vnc "0.0.0.0:${VNC_PORT}" \
    -netdev tap,id="$TAP_IF_NAME",ifname="$TAP_IF_NAME",script=no,downscript=no \
    -device e1000,netdev="$TAP_IF_NAME" \
    -daemonize \
    -snapshot \
    "$IMAGE_NAME"

echo "VM $VM_NAME creada en VLAN $VLAN_ID, accesible en VNC puerto $VNC_PORT."

exit 0