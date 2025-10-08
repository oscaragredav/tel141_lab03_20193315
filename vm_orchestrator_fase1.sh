#!/bin/bash

#================================================================
# Script: vm_orchestrator_fase1.sh
# Descripción: Orquesta la creación de la topología de la Fase 1
#              del laboratorio. Se conecta por SSH a los nodos
#              remotos para ejecutar los scripts de inicialización
#              y creación de VMs.
#
# Ejecución: Se ejecuta desde el nodo Headnode.
#================================================================

# --- Sección de Configuración ---
# MODIFICA ESTAS VARIABLES SEGÚN TU TOPOLOGÍA ASIGNADA

# Usuario para la conexión SSH
SSH_USER="ubuntu"

# Direcciones IP de la red de GESTIÓN de tus nodos
OFS_IP="10.0.10.5"
WORKER1_IP="10.0.10.1" # server1
WORKER2_IP="10.0.10.3" # server3
WORKER3_IP="10.0.10.4" # server4

# Nombres de los bridges a crear en los nodos
OVS_WORKER_BRIDGE="br-int"
OVS_OFS_BRIDGE="br-data"

# Interfaces de la red de DATOS para cada nodo
# Asegúrate de que no sea la interfaz de gestión (ens3 en workers)
IFACE_WORKER1="ens4"
IFACE_WORKER2="ens4"
IFACE_WORKER3="ens4"
# Para el OFS, lista todas sus interfaces de datos separadas por espacios
IFACES_OFS="ens4 ens5 ens6 ens7"

# Ruta donde se encuentran los scripts en los nodos remotos
REMOTE_SCRIPT_PATH="/home/ubuntu" # Cambiar si los pusiste en otra carpeta

# --- Fin de la Sección de Configuración ---


# Muestra un resumen de lo que el script va a hacer
cat << EOF

=======================================================
      Orquestador de Topología - Fase 1
=======================================================
Este script configurará la red de datos y creará VMs.
Asegúrate de que las IPs y nombres de interfaces en la
sección de configuración son correctos.

Plan de ejecución:
1. Inicializar el Switch central (OFS) en $OFS_IP.
2. Inicializar Worker 1 en $WORKER1_IP.
3. Inicializar Worker 2 en $WORKER2_IP.
4. Inicializar Worker 3 en $WORKER3_IP.
5. Crear VM 'vm1' (VLAN 100) en Worker 1.
6. Crear VM 'vm2' (VLAN 200) en Worker 2.
7. Crear VM 'vm3' (VLAN 100) en Worker 3.

Presiona Enter para comenzar o Ctrl+C para cancelar...
EOF
read

# --- Lógica Principal de Orquestación ---

echo ""
echo "--- [Paso 1/7] Inicializando el Switch Central (OFS) en $OFS_IP ---"
# Se conecta al OFS y ejecuta el script de inicialización con los parámetros definidos
ssh "$SSH_USER@$OFS_IP" "sudo $REMOTE_SCRIPT_PATH/init_ofs.sh '$OVS_OFS_BRIDGE' $IFACES_OFS"
echo "-> OFS inicializado."
echo ""

echo "--- [Paso 2/7] Inicializando Worker 1 en $WORKER1_IP ---"
ssh "$SSH_USER@$WORKER1_IP" "sudo $REMOTE_SCRIPT_PATH/init_worker.sh '$OVS_WORKER_BRIDGE' '$IFACE_WORKER1'"
echo "-> Worker 1 inicializado."
echo ""

echo "--- [Paso 3/7] Inicializando Worker 2 en $WORKER2_IP ---"
ssh "$SSH_USER@$WORKER2_IP" "sudo $REMOTE_SCRIPT_PATH/init_worker.sh '$OVS_WORKER_BRIDGE' '$IFACE_WORKER2'"
echo "-> Worker 2 inicializado."
echo ""

echo "--- [Paso 4/7] Inicializando Worker 3 en $WORKER3_IP ---"
ssh "$SSH_USER@$WORKER3_IP" "sudo $REMOTE_SCRIPT_PATH/init_worker.sh '$OVS_WORKER_BRIDGE' '$IFACE_WORKER3'"
echo "-> Worker 3 inicializado."
echo ""

# Pausa para asegurar que las redes están estables antes de crear VMs
echo "Pausa de 5 segundos..."
sleep 5
echo ""

echo "--- [Paso 5/7] Creando VM 'vm1' en Worker 1 ---"
# Se conecta al worker y ejecuta el script de creación de VM con sus parámetros específicos
ssh "$SSH_USER@$WORKER1_IP" "sudo $REMOTE_SCRIPT_PATH/vm_create.sh vm1 '$OVS_WORKER_BRIDGE' 100 5901"
echo "-> VM 'vm1' creada en Worker 1 (VLAN 100, VNC 5901)."
echo ""

echo "--- [Paso 6/7] Creando VM 'vm2' en Worker 2 ---"
ssh "$SSH_USER@$WORKER2_IP" "sudo $REMOTE_SCRIPT_PATH/vm_create.sh vm2 '$OVS_WORKER_BRIDGE' 200 5902"
echo "-> VM 'vm2' creada en Worker 2 (VLAN 200, VNC 5902)."
echo ""

echo "--- [Paso 7/7] Creando VM 'vm3' en Worker 3 ---"
ssh "$SSH_USER@$WORKER3_IP" "sudo $REMOTE_SCRIPT_PATH/vm_create.sh vm3 '$OVS_WORKER_BRIDGE' 100 5903"
echo "-> VM 'vm3' creada en Worker 3 (VLAN 100, VNC 5903)."
echo ""

echo "======================================================="
echo "¡Orquestación de la Fase 1 completada!"
echo "Resumen:"
echo " - Red de datos inicializada en OFS y 3 Workers."
echo " - VM 'vm1' y 'vm3' deberían poder comunicarse entre sí (VLAN 100)."
echo " - VM 'vm2' está aislada en su propia red (VLAN 200)."
echo "======================================================="

exit 0