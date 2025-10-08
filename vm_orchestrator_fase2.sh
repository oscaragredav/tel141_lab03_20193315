#!/bin/bash

SSH_USER="ubuntu"

HEADNODE_IP="10.0.10.2"
OFS_IP="10.0.10.5"
WORKER1_IP="10.0.10.1"
WORKER2_IP="10.0.10.3"
WORKER3_IP="10.0.10.4"

OVS_WORKER_BRIDGE="br-int"
OVS_OFS_BRIDGE="br-data"

IFACE_HEADNODE_DATA="ens5"
IFACE_HEADNODE_MGMT="ens3"
IFACE_WORKER1="ens4"
IFACE_WORKER2="ens4"
IFACE_WORKER3="ens4"
IFACES_OFS="ens4 ens5 ens6 ens7"

REMOTE_SCRIPT_PATH="/home/ubuntu"

cat << EOF
=======================================================
      Orquestador de Topología - Fase 2
=======================================================
Plan de ejecución:
1. Inicializar el Headnode en $HEADNODE_IP.
2. Inicializar el Switch central (OFS) en $OFS_IP.
3. Inicializar Worker 1 en $WORKER1_IP.
4. Inicializar Worker 2 en $WORKER2_IP.
5. Inicializar Worker 3 en $WORKER3_IP.
6. Crear VM 'vm1' (VLAN 100) en Worker 1.
7. Crear VM 'vm2' (VLAN 200) en Worker 2.
8. Crear VM 'vm3' (VLAN 100) en Worker 3.

Presiona Enter para comenzar o Ctrl+C para cancelar...
EOF
read

echo "--- [Paso 1/8] Inicializando el Headnode en $HEADNODE_IP ---"
ssh "$SSH_USER@$HEADNODE_IP" "sudo $REMOTE_SCRIPT_PATH/init_headnode.sh '$OVS_OFS_BRIDGE' '$IFACE_HEADNODE_DATA' '$IFACE_HEADNODE_MGMT'"

echo "--- [Paso 2/8] Inicializando el Switch Central (OFS) en $OFS_IP ---"
ssh "$SSH_USER@$OFS_IP" "sudo $REMOTE_SCRIPT_PATH/init_ofs.sh '$OVS_OFS_BRIDGE' $IFACES_OFS"

echo "--- [Paso 3/8] Inicializando Worker 1 en $WORKER1_IP ---"
ssh "$SSH_USER@$WORKER1_IP" "sudo $REMOTE_SCRIPT_PATH/init_worker.sh '$OVS_WORKER_BRIDGE' '$IFACE_WORKER1'"

echo "--- [Paso 4/8] Inicializando Worker 2 en $WORKER2_IP ---"
ssh "$SSH_USER@$WORKER2_IP" "sudo $REMOTE_SCRIPT_PATH/init_worker.sh '$OVS_WORKER_BRIDGE' '$IFACE_WORKER2'"

echo "--- [Paso 5/8] Inicializando Worker 3 en $WORKER3_IP ---"
ssh "$SSH_USER@$WORKER3_IP" "sudo $REMOTE_SCRIPT_PATH/init_worker.sh '$OVS_WORKER_BRIDGE' '$IFACE_WORKER3'"

echo "Pausa de 5 segundos..."
sleep 5

echo "--- [Paso 6/8] Creando VM 'vm1' en Worker 1 ---"
ssh "$SSH_USER@$WORKER1_IP" "sudo $REMOTE_SCRIPT_PATH/vm_create.sh vm1 '$OVS_WORKER_BRIDGE' 100 5901"

echo "--- [Paso 7/8] Creando VM 'vm2' en Worker 2 ---"
ssh "$SSH_USER@$WORKER2_IP" "sudo $REMOTE_SCRIPT_PATH/vm_create.sh vm2 '$OVS_WORKER_BRIDGE' 200 5902"

echo "--- [Paso 8/8] Creando VM 'vm3' en Worker 3 ---"
ssh "$SSH_USER@$WORKER3_IP" "sudo $REMOTE_SCRIPT_PATH/vm_create.sh vm3 '$OVS_WORKER_BRIDGE' 100 5903"

echo "======================================================="
echo "¡Orquestación de la Fase 2 completada!"
echo "Resumen:"
echo " - Headnode configurado con DHCP, Gateway e Internet."
echo " - Red de datos inicializada en OFS y 3 Workers."
echo " - VMs creadas y deberían recibir IP automáticamente."
echo "======================================================="

exit 0