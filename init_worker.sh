#!/bin/bash

NOMBRE_OVS=$1
shift
INTERFACES=("$@")

if [ "$#" -eq 0 ]; then
    echo "Falta el nombre del bridge y las interfaces a conectar."
    exit 1
fi

echo "Iniciando configuración del nodo de trabajo"
echo "Bridge local: $NOMBRE_OVS"
echo "Interfaces de red: ${INTERFACES[*]}"

if ! sudo ovs-vsctl br-exists $NOMBRE_OVS; then
    echo "El bridge $NOMBRE_OVS no existe, creando..."
    sudo ovs-vsctl add-br $NOMBRE_OVS
    if [ $? -ne 0 ]; then
        echo "No se pudo crear el bridge $NOMBRE_OVS."
        exit 1
    fi
else
    echo "El bridge $NOMBRE_OVS ya está presente."
fi

for iface in "${INTERFACES[@]}"; do
    echo "Procesando interfaz: $iface"

    if ! ip link show $iface >/dev/null 2>&1; then
        echo "La interfaz $iface no se encontró, continuando con la siguiente."
        continue
    fi

    if sudo ovs-vsctl port-to-br $iface | grep -q $NOMBRE_OVS; then
        echo "La interfaz $iface ya está unida al bridge $NOMBRE_OVS."
    else
        echo "Añadiendo interfaz $iface a $NOMBRE_OVS."
        sudo ip addr flush dev $iface
        sudo ovs-vsctl add-port $NOMBRE_OVS $iface
        if [ $? -eq 0 ]; then
            echo "Interfaz $iface unida con éxito."
            sudo ovs-vsctl set port $iface trunks=1-4094
        else
            echo "Fallo al unir la interfaz $iface."
        fi
    fi
done

sudo ip link set $NOMBRE_OVS up

echo "Configuración del nodo de trabajo completada."
sudo ovs-vsctl show