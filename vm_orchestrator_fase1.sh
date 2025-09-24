#!/bin/bash

echo "===== INICIANDO DESPLIEGUE DE RED VIRTUAL ====="

HEADNODE="10.0.10.4"
WORKERS=("10.0.10.1" "10.0.10.2" "10.0.10.3")
OFS_NODE="10.0.10.5"

BRIDGE_WORKER="br-local"
BRIDGE_OFS="br-global"

INTERFACES_OFS=("eth1" "eth2" "eth3" "eth4")

declare -A VM_DEPLOYMENT=(
    ["vm1_w1"]="10.0.10.1 100 5901"
    ["vm2_w1"]="10.0.10.1 200 5902"
    ["vm3_w1"]="10.0.10.1 300 5903"
    ["vm1_w2"]="10.0.10.2 100 5911"
    ["vm2_w2"]="10.0.10.2 200 5912"
    ["vm3_w2"]="10.0.10.2 300 5913"
    ["vm1_w3"]="10.0.10.3 100 5921"
    ["vm2_w3"]="10.0.10.3 200 5922"
    ["vm3_w3"]="10.0.10.3 300 5923"
)

run_remote() {
    local host="$1"
    local cmd="$2"
    ssh -o StrictHostKeyChecking=no root@"$host" "$cmd"
}

copy_file() {
    local host="$1"
    local source_path="$2"
    local dest_path="$3"
    scp -o StrictHostKeyChecking=no "$source_path" root@"$host":"$dest_path"
}

test_all_hosts() {
    local hosts=("$@")
    local status=0
    for h in "${hosts[@]}"; do
        ping -c 1 -W 3 "$h" >/dev/null 2>&1
        if [ $? -ne 0 ]; then
            echo "El host $h no responde."
            status=1
        fi
    done
    return $status
}

distribute_files() {
    local hosts=("$@")
    for host in "${hosts[@]}"; do
        copy_file "$host" "init_worker.sh" "/tmp/"
        copy_file "$host" "vm_create.sh" "/tmp/"
        copy_file "$host" "init_ofs.sh" "/tmp/"
        run_remote "$host" "chmod +x /tmp/*.sh"
    done
}

configure_ofs() {
    local ifaces_str="${INTERFACES_OFS[*]}"
    run_remote "$OFS_NODE" "/tmp/init_ofs.sh $BRIDGE_OFS $ifaces_str"
}

configure_workers() {
    for worker_ip in "${WORKERS[@]}"; do
        run_remote "$worker_ip" "/tmp/init_worker.sh $BRIDGE_WORKER eth1"
    done
}

deploy_vms() {
    for vm_id in "${!VM_DEPLOYMENT[@]}"; do
        read -r host vlan port <<< "${VM_DEPLOYMENT[$vm_id]}"
        vm_name=$(echo "$vm_id" | cut -d'_' -f1)
        
        run_remote "$host" "/tmp/vm_create.sh $vm_name $BRIDGE_WORKER $vlan $port"
    done
}

if ! test_all_hosts "${WORKERS[@]}" "$OFS_NODE"; then
    echo "Fallo al verificar la conectividad con los hosts. Abortando."
    exit 1
fi

distribute_files "${WORKERS[@]}" "$OFS_NODE"
configure_ofs
configure_workers
sleep 10
deploy_vms

echo "===== ORQUESTACIÓN COMPLETADA ====="