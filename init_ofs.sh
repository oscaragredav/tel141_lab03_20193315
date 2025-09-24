#!/bin/bash


if [ "$#" -lt 2 ]; then
    echo "Faltan argumentos. Por favor, proporciona el nombre del bridge y al menos una interfaz."
    exit 1
fi

BRIDGE_NAME=$1
shift
INTERFACES=("$@")

echo "--- Iniciando configuración del switch central OVS ---"
echo "Nombre del bridge: $BRIDGE_NAME"
echo "Interfaces a procesar: ${INTERFACES[*]}"

setup_interface() {
    local iface=$1
    echo "--> Procesando interfaz: $iface"

    if ! ip link show $iface >/dev/null 2>&1; then
        echo "Error: La interfaz '$iface' no se encontró. Saltando..."
        return
    fi

    echo "Limpiando IP de la interfaz '$iface'..."
    sudo ip addr flush dev $iface

    if ! sudo ovs-vsctl list-ports $BRIDGE_NAME | grep -q "^$iface$"; then
        echo "Añadiendo '$iface' al bridge '$BRIDGE_NAME'..."
        sudo ovs-vsctl add-port $BRIDGE_NAME $iface
    else
        echo "La interfaz '$iface' ya es parte de '$BRIDGE_NAME'."
    fi

    echo "Configurando '$iface' como puerto troncal..."
    sudo ovs-vsctl set port $iface trunks=1-4094

    sudo ip link set $iface up
}

if ! sudo ovs-vsctl br-exists $BRIDGE_NAME; then
    echo "Creando el bridge '$BRIDGE_NAME'..."
    sudo ovs-vsctl add-br $BRIDGE_NAME
else
    echo "El bridge '$BRIDGE_NAME' ya existe."
fi

for iface in "${INTERFACES[@]}"; do
    setup_interface $iface
done

sudo ip link set dev $BRIDGE_NAME up

echo "--- Configuración del OFS completada ---"
sudo ovs-vsctl show