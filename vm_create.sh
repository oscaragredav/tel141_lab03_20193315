#!/bin/bash

VM_NAME=$1
OVS_NAME=$2
VLAN_ID=$3
VNC_PORT=$4

if [ "$#" -ne 4 ]; then
    echo "Debe proporcionar el nombre de la VM, el nombre del bridge OvS, el VLAN ID y el puerto VNC."
    exit 1
fi

DISK_SIZE="10G"
VM_DIR="/tmp/vms"
DISK_IMAGE="$VM_DIR/${VM_NAME}.qcow2"
TAP_IFACE="tap-${VM_NAME}"

echo "Iniciando despliegue de VM: $VM_NAME"

if ! sudo ovs-vsctl br-exists "$OVS_NAME"; then
    echo "Error: El bridge OvS '$OVS_NAME' no se encuentra."
    exit 1
fi

sudo mkdir -p "$VM_DIR"
cd "$VM_DIR"

if [ ! -f "$DISK_IMAGE" ]; then
    sudo qemu-img create -f qcow2 "$DISK_IMAGE" "$DISK_SIZE"
fi

sudo ip tuntap del dev "$TAP_IFACE" mode tap 2>/dev/null
sudo ip tuntap add dev "$TAP_IFACE" mode tap
sudo ip link set "$TAP_IFACE" up

sudo ovs-vsctl add-port "$OVS_NAME" "$TAP_IFACE"
sudo ovs-vsctl set port "$TAP_IFACE" tag="$VLAN_ID"

STARTUP_SCRIPT="$VM_DIR/start_${VM_NAME}.sh"
cat > "$STARTUP_SCRIPT" << EOF
#!/bin/bash
pgrep -f "qemu.*${VM_NAME}" > /dev/null && { echo "VM $VM_NAME ya se está ejecutando."; exit 1; }
sudo qemu-system-x86_64 \\
    -name "$VM_NAME" \\
    -m 1024 \\
    -hda "$DISK_IMAGE" \\
    -netdev tap,id=net0,ifname="$TAP_IFACE",script=no,downscript=no \\
    -device virtio-net-pci,netdev=net0,mac=52:54:00:\$(printf '%02x:%02x:%02x' \$((RANDOM%256)) \$((RANDOM%256)) \$((RANDOM%256))) \\
    -vnc :$(($VNC_PORT - 5900)) \\
    -daemonize \\
    -pidfile "$VM_DIR/${VM_NAME}.pid"
EOF

chmod +x "$STARTUP_SCRIPT"
bash "$STARTUP_SCRIPT"

echo "VM $VM_NAME está en marcha en el puerto VNC $VNC_PORT."
sudo ovs-vsctl show | grep -A 5 -B 5 "$TAP_IFACE"
echo "Despliegue de VM completado."