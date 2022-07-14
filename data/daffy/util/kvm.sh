#!/bin/bash
############################################################
#Author           : Kyle Dawson
#Author email     : Kyle.Dawson@us.ibm.com
#Original Date    : 2021-09-25
#Initial Version  : v2021-12-01
############################################################
createBootstrapVM()
{
  printHeaderMessage "Create Bootstrap VM"
  rm -fR  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createBootstrapVM.log  2> /dev/null
  VM_ACTIVE_STORE_POOL=`virsh pool-list --all | grep -c ${VM_VOL_STORAGE_POOL}`
  if [  ${VM_ACTIVE_STORE_POOL} == 0 ] ;then
      echo "Building new Storage Pool:"
      echo "VM_VOL_STORAGE_POOL = ${VM_VOL_STORAGE_POOL}"
      echo "VM_IMAGE_ROOT_PATH = ${VM_IMAGE_ROOT_PATH}"
      mkdir -p ${VM_IMAGE_ROOT_PATH}
      virsh pool-define-as --name ${VM_VOL_STORAGE_POOL} --type dir --target ${VM_IMAGE_ROOT_PATH}
      virsh pool-start ${VM_VOL_STORAGE_POOL}
      virsh pool-autostart ${VM_VOL_STORAGE_POOL}
      virsh pool-list --all
  fi
  echo "Creating storage for bootstrap - ${VM_VOL_STORAGE_POOL} bootstrap.qcow2 ${VM_BOOTSTRAP_DISK1}" | tee ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createBootstrapVM.log
  virsh vol-create-as ${VM_VOL_STORAGE_POOL} bootstrap.qcow2 ${VM_BOOTSTRAP_DISK1}  >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createBootstrapVM.log 2>&1
  echo "Creating bootstrap VM --ram=${VM_BOOTSTRAP_RAM} --vcpus=${VM_BOOTSTRAP_VCPU}" | tee -a  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createBootstrapVM.log
  virt-install --name=bootstrap --ram=${VM_BOOTSTRAP_RAM} --vcpus=${VM_BOOTSTRAP_VCPU} --mac=52:54:00:02:85:01 \
  --disk path=${VM_IMAGE_ROOT_PATH}/bootstrap.qcow2,bus=virtio \
  --pxe --noautoconsole --graphics=vnc --hvm \
  --network network=ocp,model=virtio --boot hd,network >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createBootstrapVM.log  2>&1
  echo ""
}
createOtherVMs()
{
  printHeaderMessage "Create Other VMs"
  rm -fR ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createOtherVM.log 2> /dev/null
  echo "Creating storage for master1 - ${VM_VOL_STORAGE_POOL} master1.qcow2 ${VM_MASTER_DISK1}" | tee ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createOtherVM.log
  virsh vol-create-as ${VM_VOL_STORAGE_POOL} master1.qcow2 ${VM_MASTER_DISK1} >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createOtherVM.log  2>&1
  echo "Creating master1 VM  --ram=${VM_MASTER_RAM} --vcpus=${VM_MASTER_VCPU}" | tee -a  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createOtherVM.log
  virt-install --name=master1 --ram=${VM_MASTER_RAM} --vcpus=${VM_MASTER_VCPU} --mac=52:54:00:02:86:01 \
  --disk path=${VM_IMAGE_ROOT_PATH}/master1.qcow2,bus=virtio \
  --pxe --noautoconsole --graphics=vnc --hvm \
  --network network=ocp,model=virtio --boot hd,network  >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createOtherVM.log  2>&1
  echo ""


  echo "Creating storage for master2 - ${VM_VOL_STORAGE_POOL} master2.qcow2 ${VM_MASTER_DISK1}" | tee -a  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createOtherVM.log
  virsh vol-create-as ${VM_VOL_STORAGE_POOL} master2.qcow2 ${VM_MASTER_DISK1} >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createOtherVM.log  2>&1
  echo "Creating master2 VM  --ram=${VM_MASTER_RAM} --vcpus=${VM_MASTER_VCPU}"
  virt-install --name=master2 --ram=${VM_MASTER_RAM} --vcpus=${VM_MASTER_VCPU} --mac=52:54:00:02:86:02 \
  --disk path=${VM_IMAGE_ROOT_PATH}/master2.qcow2,bus=virtio \
  --pxe --noautoconsole --graphics=vnc --hvm \
  --network network=ocp,model=virtio --boot hd,network >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createOtherVM.log  2>&1
  echo ""

  echo "Creating storage for master3 - ${VM_VOL_STORAGE_POOL} master3.qcow2 ${VM_MASTER_DISK1}" | tee -a  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createOtherVM.log
  virsh vol-create-as ${VM_VOL_STORAGE_POOL} master3.qcow2 ${VM_MASTER_DISK1} >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createOtherVM.log  2>&1
  echo "Creating master3 VM  --ram=${VM_MASTER_RAM} --vcpus=${VM_MASTER_VCPU}"  | tee -a  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createOtherVM.log
  virt-install --name=master3 --ram=${VM_MASTER_RAM} --vcpus=${VM_MASTER_VCPU} --mac=52:54:00:02:86:03 \
  --disk path=${VM_IMAGE_ROOT_PATH}/master3.qcow2,bus=virtio \
  --pxe --noautoconsole --graphics=vnc --hvm \
  --network network=ocp,model=virtio --boot hd,network >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createOtherVM.log  2>&1
  echo ""

  if [[ "${VM_TSHIRT_SIZE}" == "Min" && "${VM_BUILD_WORKERS_NODES}" == "true" ]]  ;then
      echo "Creating storage for worker1 - ${VM_VOL_STORAGE_POOL} worker1.qcow2 ${VM_WORKER_DISK1}  worker1b.qcow2 ${VM_WORKER_DISK2} worker1c.qcow2 ${VM_WORKER_DISK3}" | tee -a  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createOtherVM.log
      virsh vol-create-as ${VM_VOL_STORAGE_POOL} worker1.qcow2 ${VM_WORKER_DISK1} >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createOtherVM.log  2>&1
      echo "Creating worker1 VM  --ram=${VM_WORKER_RAM} --vcpus=${VM_WORKER_VCPU}" | tee -a  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createOtherVM.log
      virt-install --name=worker1 --ram=${VM_WORKER_RAM} --vcpus=${VM_WORKER_VCPU} --mac=52:54:00:02:87:01 \
      --disk path=${VM_IMAGE_ROOT_PATH}/worker1.qcow2,bus=virtio \
      --pxe --noautoconsole --graphics=vnc --hvm \
      --network network=ocp,model=virtio --boot hd,network>> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createOtherVM.log  2>&1
      echo ""

      echo "Creating storage for worker2 - ${VM_VOL_STORAGE_POOL} worker2.qcow2 ${VM_WORKER_DISK1}  worker2b.qcow2 ${VM_WORKER_DISK2} worker2c.qcow2 ${VM_WORKER_DISK3}" | tee -a  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createOtherVM.log
      virsh vol-create-as ${VM_VOL_STORAGE_POOL} worker2.qcow2 ${VM_WORKER_DISK1} >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createOtherVM.log  2>&1
      echo "Creating worker2 VM  --ram=${VM_WORKER_RAM} --vcpus=${VM_WORKER_VCPU}"  | tee -a  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createOtherVM.log
      virt-install --name=worker2 --ram=${VM_WORKER_RAM} --vcpus=${VM_WORKER_VCPU} --mac=52:54:00:02:87:02 \
      --disk path=${VM_IMAGE_ROOT_PATH}/worker2.qcow2,bus=virtio \
      --pxe --noautoconsole --graphics=vnc --hvm \
      --network network=ocp,model=virtio --boot hd,network >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createOtherVM.log  2>&1
      echo ""

      echo "Creating storage for worker3 - ${VM_VOL_STORAGE_POOL} worker3.qcow2 ${VM_WORKER_DISK1}  worker3b.qcow2 ${VM_WORKER_DISK2} worker3c.qcow2 ${VM_WORKER_DISK3}" | tee -a  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createOtherVM.log
      virsh vol-create-as ${VM_VOL_STORAGE_POOL} worker3.qcow2 ${VM_WORKER_DISK1} >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createOtherVM.log  2>&1
      echo "Creating worker3 VM  --ram=${VM_WORKER_RAM} --vcpus=${VM_WORKER_VCPU}"  | tee -a  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createOtherVM.log
      virt-install --name=worker3 --ram=${VM_WORKER_RAM} --vcpus=${VM_WORKER_VCPU} --mac=52:54:00:02:87:03 \
      --disk path=${VM_IMAGE_ROOT_PATH}/worker3.qcow2,bus=virtio \
      --pxe --noautoconsole --graphics=vnc --hvm \
      --network network=ocp,model=virtio --boot hd,network >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createOtherVM.log  2>&1
      echo ""
  fi
  if [[ "${VM_TSHIRT_SIZE}" == "Large" && "${VM_BUILD_WORKERS_NODES}" == "true" ]] ;then

      echo "Creating storage for worker1 - ${VM_VOL_STORAGE_POOL} worker1.qcow2 ${VM_WORKER_DISK1}" | tee -a  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createOtherVM.log
      virsh vol-create-as ${VM_VOL_STORAGE_POOL} worker1.qcow2 ${VM_WORKER_DISK1} >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createOtherVM.log  2>&1
      echo "Creating worker1 VM  --ram=${VM_WORKER_RAM} --vcpus=${VM_WORKER_VCPU}"  | tee -a  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createOtherVM.log
      virt-install --name=worker1 --ram=${VM_WORKER_RAM} --vcpus=${VM_WORKER_VCPU} --mac=52:54:00:02:87:01 \
      --disk path=${VM_IMAGE_ROOT_PATH}/worker1.qcow2,bus=virtio \
      --pxe --noautoconsole --graphics=vnc --hvm \
      --network network=ocp,model=virtio --boot hd,network >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createOtherVM.log  2>&1
      echo ""

      echo "Creating storage for worker2 - ${VM_VOL_STORAGE_POOL} worker2.qcow2 ${VM_WORKER_DISK1}"| tee -a  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createOtherVM.log
      virsh vol-create-as ${VM_VOL_STORAGE_POOL} worker2.qcow2 ${VM_WORKER_DISK1} >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createOtherVM.log  2>&1
      echo "Creating worker2 VM  --ram=${VM_WORKER_RAM} --vcpus=${VM_WORKER_VCPU}"  | tee -a  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createOtherVM.log
      virt-install --name=worker2 --ram=${VM_WORKER_RAM} --vcpus=${VM_WORKER_VCPU} --mac=52:54:00:02:87:02 \
      --disk path=${VM_IMAGE_ROOT_PATH}/worker2.qcow2,bus=virtio \
      --pxe --noautoconsole --graphics=vnc --hvm \
      --network network=ocp,model=virtio --boot hd,network >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createOtherVM.log  2>&1
      echo ""

      echo "Creating storage for worker3 - ${VM_VOL_STORAGE_POOL} worker3.qcow2 ${VM_WORKER_DISK1}" | tee -a  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createOtherVM.log
      virsh vol-create-as ${VM_VOL_STORAGE_POOL} worker3.qcow2 ${VM_WORKER_DISK1} >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createOtherVM.log  2>&1
      echo "Creating worker3 VM  --ram=${VM_WORKER_RAM} --vcpus=${VM_WORKER_VCPU}"  | tee -a  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createOtherVM.log
      virt-install --name=worker3 --ram=${VM_WORKER_RAM} --vcpus=${VM_WORKER_VCPU} --mac=52:54:00:02:87:03 \
      --disk path=${VM_IMAGE_ROOT_PATH}/worker3.qcow2,bus=virtio \
      --pxe --noautoconsole --graphics=vnc --hvm \
      --network network=ocp,model=virtio --boot hd,network >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createOtherVM.log  2>&1
      echo ""

      echo "Creating storage for worker4 - ${VM_VOL_STORAGE_POOL} worker4.qcow2 ${VM_WORKER_DISK1} worker4b.qcow2 ${VM_WORKER_DISK2} worker4c.qcow2 ${VM_WORKER_DISK3}" | tee -a  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createOtherVM.log
      virsh vol-create-as ${VM_VOL_STORAGE_POOL} worker4.qcow2 ${VM_WORKER_DISK1} >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createOtherVM.log  2>&1
      virsh vol-create-as ${VM_VOL_STORAGE_POOL} worker4b.qcow2 ${VM_WORKER_DISK2} >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createOtherVM.log  2>&1
      virsh vol-create-as ${VM_VOL_STORAGE_POOL} worker4c.qcow2 ${VM_WORKER_DISK3} >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createOtherVM.log  2>&1
      echo "Creating worker4 VM  --ram=${VM_WORKER_RAM} --vcpus=${VM_WORKER_VCPU}"  | tee -a  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createOtherVM.log
      virt-install --name=worker4 --ram=${VM_WORKER_RAM} --vcpus=${VM_WORKER_VCPU} --mac=52:54:00:02:87:04 \
      --pxe --noautoconsole --graphics=vnc --hvm \
      --network network=ocp,model=virtio --boot hd,network \
      --disk path=${VM_IMAGE_ROOT_PATH}/worker4.qcow2,bus=virtio \
      --disk path=${VM_IMAGE_ROOT_PATH}/worker4b.qcow2,bus=virtio \
      --disk path=${VM_IMAGE_ROOT_PATH}/worker4c.qcow2,bus=virtio >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createOtherVM.log  2>&1
      echo ""

      echo "Creating storage for worker5 - ${VM_VOL_STORAGE_POOL} worker5qcow2 ${VM_WORKER_DISK1} worker5b.qcow2 ${VM_WORKER_DISK2} worker5c.qcow2 ${VM_WORKER_DISK3}"| tee -a  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createOtherVM.log
      virsh vol-create-as ${VM_VOL_STORAGE_POOL} worker5.qcow2 ${VM_WORKER_DISK1} >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createOtherVM.log  2>&1
      virsh vol-create-as ${VM_VOL_STORAGE_POOL} worker5b.qcow2 ${VM_WORKER_DISK2} >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createOtherVM.log  2>&1
      virsh vol-create-as ${VM_VOL_STORAGE_POOL} worker5c.qcow2 ${VM_WORKER_DISK3} >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createOtherVM.log  2>&1
      echo "Creating worker5 VM  --ram=${VM_WORKER_RAM} --vcpus=${VM_WORKER_VCPU}"  | tee -a  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createOtherVM.log
      virt-install --name=worker5 --ram=${VM_WORKER_RAM} --vcpus=${VM_WORKER_VCPU} --mac=52:54:00:02:87:05 \
      --pxe --noautoconsole --graphics=vnc --hvm \
      --network network=ocp,model=virtio --boot hd,network \
      --disk path=${VM_IMAGE_ROOT_PATH}/worker5.qcow2,bus=virtio \
      --disk path=${VM_IMAGE_ROOT_PATH}/worker5b.qcow2,bus=virtio \
      --disk path=${VM_IMAGE_ROOT_PATH}/worker5c.qcow2,bus=virtio >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createOtherVM.log  2>&1
      echo ""

      echo "Creating storage for worker6 - ${VM_VOL_STORAGE_POOL} worker6.qcow2 ${VM_WORKER_DISK1} worker6b.qcow2 ${VM_WORKER_DISK2} worker6c.qcow2 ${VM_WORKER_DISK3}" | tee -a  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createOtherVM.log
      virsh vol-create-as ${VM_VOL_STORAGE_POOL} worker6.qcow2 ${VM_WORKER_DISK1} >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createOtherVM.log  2>&1
      virsh vol-create-as ${VM_VOL_STORAGE_POOL} worker6b.qcow2 ${VM_WORKER_DISK2} >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createOtherVM.log  2>&1
      virsh vol-create-as ${VM_VOL_STORAGE_POOL} worker6c.qcow2 ${VM_WORKER_DISK3} >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createOtherVM.log  2>&1
      echo "Creating worker6 VM  --ram=${VM_WORKER_RAM} --vcpus=${VM_WORKER_VCPU}"  | tee -a  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createOtherVM.log
      virt-install --name=worker6 --ram=${VM_WORKER_RAM} --vcpus=${VM_WORKER_VCPU} --mac=52:54:00:02:87:06 \
      --pxe --noautoconsole --graphics=vnc --hvm \
      --network network=ocp,model=virtio --boot hd,network \
      --disk path=${VM_IMAGE_ROOT_PATH}/worker6.qcow2,bus=virtio \
      --disk path=${VM_IMAGE_ROOT_PATH}/worker6b.qcow2,bus=virtio \
      --disk path=${VM_IMAGE_ROOT_PATH}/worker6c.qcow2,bus=virtio >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createOtherVM.log  2>&1
       echo ""

      if [  ${VM_NUMBER_OF_WORKERS_LARGE} -gt 6  ]; then
        let LOOP_COUNT=1+6
        #Build more workes then Default TShirt Size large
        while [ ${LOOP_COUNT} -le  ${VM_NUMBER_OF_WORKERS_LARGE}  ]
        do
            echo "Creating storage for worker${LOOP_COUNT} - ${VM_VOL_STORAGE_POOL} worker${LOOP_COUNT}.qcow2 ${VM_WORKER_DISK1}" | tee -a  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createOtherVM.log
            virsh vol-create-as ${VM_VOL_STORAGE_POOL} worker${LOOP_COUNT}.qcow2 ${VM_WORKER_DISK1} >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createOtherVM.log  2>&1
            echo "Creating worker${LOOP_COUNT} VM  --ram=${VM_WORKER_RAM} --vcpus=${VM_WORKER_VCPU}"  | tee -a  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createOtherVM.log
            virt-install --name=worker${LOOP_COUNT} --ram=${VM_WORKER_RAM} --vcpus=${VM_WORKER_VCPU} --mac=52:54:00:02:87:0${LOOP_COUNT} \
            --pxe --noautoconsole --graphics=vnc --hvm \
            --network network=ocp,model=virtio --boot hd,network \
            --disk path=${VM_IMAGE_ROOT_PATH}/worker${LOOP_COUNT}.qcow2,bus=virtio >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createOtherVM.log  2>&1
             echo ""
            let LOOP_COUNT=LOOP_COUNT+1
        done
      fi
      #remove HAProxy seetings for extra worker nodes in proxy file. Starts with 9 workers
      if [ ${VM_NUMBER_OF_WORKERS_LARGE} -le 9 ];then
          let LOOP_COUNT=1+${VM_NUMBER_OF_WORKERS_LARGE}
          while [ ${LOOP_COUNT} -le 9 ]
          do
              sed -i '/.*server worker'"${LOOP_COUNT}"'.*/d' /etc/haproxy/haproxy.cfg
              sed -i '/^[[:space:]]*$/d' /etc/haproxy/haproxy.cfg
              let LOOP_COUNT=LOOP_COUNT+1
          done
          systemctl restart haproxy
      fi
  fi

  BOOTSTRAP_VM_CREATE_ERRORS=`cat ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createBootstrapVM.log | grep -c error`
  OTHER_VM_CREATE_ERRORS=`cat ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createOtherVM.log | grep -c error`
  if [ ${BOOTSTRAP_VM_CREATE_ERRORS} -gt 0  ] || [ ${OTHER_VM_CREATE_ERRORS} -gt 0  ] ; then
    echo "${RED_TEXT}Failed to create KVM Images.  Please check the following logs:"
    echo "${LOG_DIR}/${PRODUCT_SHORT_NAME}/createOtherVM.log"
    echo "${LOG_DIR}/${PRODUCT_SHORT_NAME}/createBootstrapVM.log ${RESET_TEXT}"
    echo ""
    echo ""
    exit 99
  fi
  echo ""
  VMS_SHUTDOWN=`virsh list --all | grep -c shut`
  while [ "${VMS_SHUTDOWN}" -ne "${VM_NUMBER_OF_IMAGES}" ]
  do
    blinkWaitMessage "Waiting for VMS's to be in Shut Off state( ${VMS_SHUTDOWN} of ${VM_NUMBER_OF_IMAGES} )" 30
    VMS_SHUTDOWN=`virsh list --all | grep -c shut`
  done
  echo "${BLUE_TEXT}COMPLETE ${RESET_TEXT} All VM's have been shutdown."
}
bootstrapSystem()
{
  printHeaderMessage "Start all VM and boostrap the System"
  systemctl enable libvirtd
  virsh start bootstrap
  virsh start master1
  virsh autostart master1 &> /dev/null
  virsh start master2
  virsh autostart master2 &> /dev/null
  virsh start master3
  virsh autostart master3 &> /dev/null
  if [ "${VM_BUILD_WORKERS_NODES}" == "true" ]  ;then
      virsh start worker1
      virsh autostart worker1 &> /dev/null
      virsh start worker2
      virsh autostart worker2 &> /dev/null
      virsh start worker3
      virsh autostart worker3 &> /dev/null
      if [ "${VM_TSHIRT_SIZE}" == "Large" ] ;then
          virsh start worker4
          virsh autostart worker4 &> /dev/null
          virsh start worker5
          virsh autostart worker5 &> /dev/null
          virsh start worker6
          virsh autostart worker6 &> /dev/null
          let LOOP_COUNT=1+6
          while [ ${LOOP_COUNT} -le  ${VM_NUMBER_OF_WORKERS_LARGE}  ]
          do
              virsh start worker${LOOP_COUNT}
              virsh autostart worker${LOOP_COUNT} &> /dev/null
              let LOOP_COUNT=LOOP_COUNT+1
          done
      fi
  fi
}


kvmCheckDiskSpaceAvailable()
{
    mkdir -p ${KVM_IMAGE_DIR_PATH}
    KVM_MOUNT=`getMonthPoint ${KVM_IMAGE_DIR_PATH}`
    MEM_FREE_SPACE=`df -h | grep -P "${KVM_MOUNT}$" | awk '{print $4}'`
    MEM_FREE_SPACE_AT_LEAST_TB=`echo ${MEM_FREE_SPACE} | grep -c 'T'`
    if [ ${MEM_FREE_SPACE_AT_LEAST_TB} -eq 0 ] ;then
        MEM_FREE_SPACE_AT_LEAST_GB=`echo ${MEM_FREE_SPACE} | grep -c 'G'`
        MEM_FREE_SPACE=`echo ${MEM_FREE_SPACE} | sed s'/[A-Z]$//g'`
        if [ ${MEM_FREE_SPACE_AT_LEAST_GB} -eq 0 ] ||  [ ${MEM_FREE_SPACE} -le ${KVM_STORGE_TOTAL} ] ;then
            echo "${RED_TEXT}FAILED: Missing disk space for KVM Images - ${KVM_MOUNT} "
            MEM_FREE_SPACE=`df -h | grep -P "${KVM_MOUNT}$" | awk '{print $4}'`  &> /dev/null
            echo "Free Disk Space - Only ${MEM_FREE_SPACE} exist on ${KVM_MOUNT} but ${KVM_STORGE_TOTAL}G is needed.${RESET_TEXT}"
            SHOULD_EXIT=1
        else
            MEM_FREE_SPACE=`df -h | grep -P "${KVM_MOUNT}$" | awk '{print $4}'`
            echo "${BLUE_TEXT}PASSED ${RESET_TEXT} You have ${MEM_FREE_SPACE} Free Disk Space and min needed is ${KVM_STORGE_TOTAL}G."
        fi
    else
         MEM_FREE_SPACE_TB=`echo ${MEM_FREE_SPACE} | sed s'/T//g'| sed s'/\.//g'`
         let "MEM_FREE_SPACE = MEM_FREE_SPACE_TB * 100"
         if [ ${MEM_FREE_SPACE} -ge ${KVM_STORGE_TOTAL} ] ;then
            echo "${BLUE_TEXT}PASSED ${RESET_TEXT} You have ${MEM_FREE_SPACE}G Free Disk Space and min needed is ${KVM_STORGE_TOTAL}G."
         else
           echo "${RED_TEXT}FAILED: Missing disk space for KVM Images - ${KVM_MOUNT} "
           MEM_FREE_SPACE=`df -h | grep -P "${KVM_MOUNT}$" | awk '{print $4}'`  &> /dev/null
           echo "Free Disk Space - Only ${MEM_FREE_SPACE}G exist on ${KVM_MOUNT} but ${KVM_STORGE_TOTAL}G is needed.${RESET_TEXT}"
           SHOULD_EXIT=1
         fi
    fi

}
kvmCheckCPUAvailable()
{
  let "KVM_NEEDED_CPU = ${KVM_MACHINE_TYPE_CPU_TOTAL}/3"
  if [ ${CURRENT_NUMBER_OF_CPU} -ge ${KVM_NEEDED_CPU} ]; then
     echo "${BLUE_TEXT}PASSED ${RESET_TEXT} You have ${CURRENT_NUMBER_OF_CPU} CPU and min needed is ${KVM_NEEDED_CPU}"
  else
     SHOULD_EXIT=1
     echo "${RED_TEXT}FAILED ${RESET_TEXT} You have ${CURRENT_NUMBER_OF_CPU} CPU and min needed is ${KVM_NEEDED_CPU}"
  fi
}

kvmCheckMemoryAvailable()
{
  KVM_MEMORY_AMOUNT=`free -h | grep Mem: | awk '{print $2}' | sed -e 's/Gi//g'`
  #let "KVM_TOTAL_MEMRORY_NEEDED_MASTER=${VM_MASTER_RAM} * ${VM_NUMBER_OF_MASTERS}"
  #let "KVM_TOTAL_MEMRORY_NEEDED_WORKER= ${VM_WORKER_RAM} * ${VM_NUMBER_OF_WORKERS}"
  #let "KVM_TOTAL_MEMRORY_NEEDED=${KVM_TOTAL_MEMRORY_NEEDED_MASTER}  + ${KVM_TOTAL_MEMRORY_NEEDED_WORKER} + ${VM_BOOTSTRAP_RAM}"
  #let "KVM_TOTAL_MEMRORY_NEEDED=${KVM_TOTAL_MEMRORY_NEEDED}/5000"
  case ${VM_TSHIRT_SIZE} in
    Large)
          KVM_TOTAL_MEMRORY_NEEDED=375
          ;;
    Min)
          KVM_TOTAL_MEMRORY_NEEDED=64
          ;;
  esac
  if [ ${KVM_MEMORY_AMOUNT} -ge ${KVM_TOTAL_MEMRORY_NEEDED} ]; then
     echo "${BLUE_TEXT}PASSED ${RESET_TEXT} You have ${KVM_MEMORY_AMOUNT} Memory and min needed is ${KVM_TOTAL_MEMRORY_NEEDED}"
  else
     SHOULD_EXIT=1
     echo "${RED_TEXT}FAILED ${RESET_TEXT} You have ${KVM_MEMORY_AMOUNT} Memory and min needed is ${KVM_TOTAL_MEMRORY_NEEDED}"
  fi
}

kvmValidateBastionIP()
{
  if [ -z ${BASTION_HOST} ]; then
    getBastionIP
  fi
  local FOUND_KVM_LOCAL_BASTION_IP=`ip a | grep -c ${BASTION_HOST}/`
  if [ ${FOUND_KVM_LOCAL_BASTION_IP} == 1 ]; then
     echo "${BLUE_TEXT}PASSED ${RESET_TEXT} Your bastion host is valid Local IP(${BASTION_HOST})"
  else
     SHOULD_EXIT=1
     echo "${RED_TEXT}FAILED : Your bastion host is NOT a valid Local IP(${BASTION_HOST})${RESET_TEXT}"
  fi
}
vmDashboardSetUser()
{
    echo "Creating User and Password"
    VM_DASHBOARD_PASSWORD=`tr -dc A-Za-z0-9 </dev/urandom | head -c 20 ; echo ''`
    mkdir -p ${OCP_KUBECONFIG_DIR}/${CLUSTER_NAME}/
    echo "${VM_DASHBOARD_PASSWORD}" > ${OCP_KUBECONFIG_DIR}/${CLUSTER_NAME}/vmdashboard-password
    cp -fR ${DATA_DIR}/${PROJECT_NAME}/${PRODUCT_SHORT_NAME}/templates/vmdashboard/* ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/vmdashboard
    find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@VM_DASHBOARD_USER@/$VM_DASHBOARD_USER/g"
    find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@VM_DASHBOARD_PASSWORD@/$VM_DASHBOARD_PASSWORD/g"
    find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@VM_DASHBOARD_DB_NAME@/$VM_DASHBOARD_DB_NAME/g"
}

vmDashboardInstallTools()
{
    echo "apt-get -y install apache2 mysql-server php libapache2-mod-php php-mysql php-xml php-libvirt-php python"
    apt-get -y install apache2 mysql-server php libapache2-mod-php php-mysql php-xml php-libvirt-php python &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/vmdashboard-apt-get.log
    sed -i 's/Listen 80$/Listen 8081/g' /etc/apache2/ports.conf &> /dev/null
    sed -i 's/Listen 81$/Listen 8081/g' /etc/apache2/ports.conf &> /dev/null
    sed -i  's/\#vnc_listen.*/vnc_listen = \"0.0.0.0\"/g' /etc/libvirt/qemu.conf &> /dev/null
    a2dismod --force autoindex &> /dev/null
    rm /var/www/html/index.html &> /dev/null
    sed -i 's/ServerTokens.*//g' /etc/apache2/ports.conf &> /dev/null
    sed -i 's/ServerSignature.*//g' /etc/apache2/ports.conf &> /dev/null
    echo "ServerTokens Prod" >> /etc/apache2/apache2.conf
    echo "ServerSignature Off" >> /etc/apache2/apache2.conf
    sed -i '/^$/d' /etc/apache2/apache2.conf > /dev/null 2>&1
}

vmDashboardSetWebserver()
{
    echo "Setting up Web Server"
    adduser www-data libvirt &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/vmdashboard-addUser.log
    cd /var/www/html
    rm -fR v${VM_DASHBOARD_VERSION}.tar.gz vmdashboard &> /dev/null
    wget https://github.com/VMDashboard/vmdashboard/archive/v${VM_DASHBOARD_VERSION}.tar.gz &>${LOG_DIR}/${PRODUCT_SHORT_NAME}/vmdashboard-wget.log
    tar -xzf v${VM_DASHBOARD_VERSION}.tar.gz &> /dev/null
    mv vmdashboard-${VM_DASHBOARD_VERSION} vmdashboard &> /dev/null
    chown -R www-data:www-data /var/www/html/vmdashboard &> /dev/null
    rm -fR /var/www/html/v${VM_DASHBOARD_VERSION}.tar.gz
    systemctl restart apache2
}

vmDashboardSetDB()
{
    echo "Creating Database"
    mysql -u root < ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/vmdashboard/createDB.sql
}
vmDashboardDisplayConnectionInfo()
{
    VM_DASHBOARD_PASSWORD=`cat ${OCP_KUBECONFIG_DIR}/${CLUSTER_NAME}/vmdashboard-password`
    echo "VM URL                :      ${BLUE_TEXT}http://${BASTION_HOST}:8081/vmdashboard${RESET_TEXT}"
    echo "VM Database Name      :      ${VM_DASHBOARD_DB_NAME}"
    echo "VM Database User      :      ${VM_DASHBOARD_USER}"
    echo "VM Database Password  :      ${VM_DASHBOARD_PASSWORD}"
    echo "VM Database Host      :      localhost"
}
