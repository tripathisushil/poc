#!/bin/bash
############################################################
#Author           : Kyle Dawson
#Author email     : Kyle.Dawson@us.ibm.com
#Original Date    : 2021-09-25
#Initial Version  : v2021-12-01
############################################################
installGOVC()
{
  printHeaderMessage "Install GOVC command line tool"
  FOUND_CURL_COMMAND=`which curl | grep -c "curl"`
  if [ ${FOUND_CURL_COMMAND} == 0 ] ;then
    echo "${BLUE_TEXT}Missing curl command, installing now.${RESET_TEXT}"
    $OS_INSTALL -y install curl
  fi
  FOUND_GOVC_COMMAND=`which govc 2>/dev/null | grep -c "govc"`
  if [ ${FOUND_GOVC_COMMAND} == 0 ] ;then
    echo "${BLUE_TEXT}Missing govc command, installing now.${RESET_TEXT}"
    curl -L -o - "https://github.com/vmware/govmomi/releases/latest/download/govc_$(uname -s)_$(uname -m).tar.gz" | tar -C /usr/local/bin -xvzf - govc
    FOUND_GOVC_COMMAND=`which govc 2>/dev/null | grep -c "govc"`
    if [ ${FOUND_GOVC_COMMAND} == 0 ] ;then
      echo "${RED_TEXT}FAILED ${RESET_TEXT} GOVC command line tool failed to install!"
      echo "Current PATH=${PATH}"
      echo "GOVC file info:"
      ls -lart /usr/local/bin/govc
      SHOULD_EXIT=1
    else
      echo "${BLUE_TEXT}PASSED ${RESET_TEXT} GOVC command line tool installed sucessfully"
    fi
  else
    echo "${BLUE_TEXT}PASSED ${RESET_TEXT} GOVC command line tool already installed."
  fi
  echo ""
}

VMWareFastDiskDataStoreValid()
{
  TEST_VM_NAME=PreCheckTestVMDataStore
  mkdir -p ${TEMP_DIR}/${PRODUCT_SHORT_NAME}
  govc vm.create -on=false -disk-datastore=${VSPHERE_FAST_DISK_DATASTORE}  ${TEST_VM_NAME}  2>  ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/vsphere-testCreateVM.log
  govc vm.destroy ${TEST_VM_NAME} 2> /dev/null
  VM_CREATE_ERROR=`cat ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/vsphere-testCreateVM.log | grep -c "cannot stat"`
  if [ "${VM_CREATE_ERROR}" == "1" ] ;then
     echo "${RED_TEXT}FAILED: Invalid VSPHERE_FAST_DISK_DATASTORE - ${VSPHERE_FAST_DISK_DATASTORE}${RESET_TEXT}"
     SHOULD_EXIT=1
  else
    echo "${BLUE_TEXT}PASSED ${RESET_TEXT} Valid VSPHERE_FAST_DISK_DATASTORE - ${VSPHERE_FAST_DISK_DATASTORE}"
  fi
}

VMWareCoreOSISOPresent()
{
    TEST_VM_NAME=PreCheckTestVM
    mkdir -p ${TEMP_DIR}/${PRODUCT_SHORT_NAME}
    govc vm.create -on=false -iso-datastore="${VSPHERE_ISO_DATASTORE}" -iso="${VSPHERE_ISO_IMAGE_BASE}/${COREOS_ISO_IMAGE}" ${TEST_VM_NAME}  2>  ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/vsphere-testCreateVM.log
    govc vm.destroy ${TEST_VM_NAME} 2> /dev/null
    VM_CREATE_ERROR=`cat ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/vsphere-testCreateVM.log | grep -c "cannot stat"`
    if [ "${VM_CREATE_ERROR}" == "1" ] ;then
       echo "${RED_TEXT}FATAL  ${RESET_TEXT} Missing ISO Image - ${VSPHERE_ISO_DATASTORE}/${VSPHERE_ISO_IMAGE_BASE}/${COREOS_ISO_IMAGE}${RESET_TEXT}"
       echo "From your environment file:"
       echo "VSPHERE_ISO_DATASTORE=${VSPHERE_ISO_DATASTORE}"
       echo "VSPHERE_ISO_IMAGE_BASE=${VSPHERE_ISO_IMAGE_BASE}"
       echo "Looking for ${COREOS_ISO_IMAGE} based on ${OCP_BASE_VERSION} from ${DATA_DIR}/${PROJECT_NAME}/env.sh"
       echo "You can download the ISO image from here:"
       echo "${BLUE_TEXT} ${OPENSHIFT_SITE_DOWNLOAD}/pub/openshift-v4/dependencies/rhcos/${OCP_BASE_VERSION}/latest/${RESET_TEXT}"
       SHOULD_EXIT=1
    else
      echo "${BLUE_TEXT}PASSED ${RESET_TEXT} ISO Image Present - ${VSPHERE_ISO_DATASTORE}/${VSPHERE_ISO_IMAGE_BASE}/${COREOS_ISO_IMAGE}"
    fi

}

rebootAllVMImages()
{
  printHeaderMessage "Reboot VSphere Images"
  echo "Rebooting ${CLUSTER_NAME}-bootstrap"
  govc vm.power -r=true -force=true ${CLUSTER_NAME}-bootstrap >> ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/reboot-vm.log
  #blinkWaitMessage "Sleeping for 120 seconds to allow boostrap to start" 120
  echo "Rebooting the cluster nodes now"
  if [ "${VM_BUILD_WORKERS_NODES}" == "true" ] ;then
      govc vm.power -r=true -force=true ${CLUSTER_NAME}-master1 ${CLUSTER_NAME}-master2 ${CLUSTER_NAME}-master3 ${CLUSTER_NAME}-worker1 ${CLUSTER_NAME}-worker2 ${CLUSTER_NAME}-worker3 >> ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/reboot-vm.log
      if [ "${VM_TSHIRT_SIZE}" == "Large" ]  ;then
          govc vm.power -r=true -force=true  ${CLUSTER_NAME}-worker4 ${CLUSTER_NAME}-worker5 ${CLUSTER_NAME}-worker6  >> ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/reboot-vm.log
      fi
  else
      govc vm.power -r=true -force=true ${CLUSTER_NAME}-master1 ${CLUSTER_NAME}-master2 ${CLUSTER_NAME}-master3 >> ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/reboot-vm.log
  fi
  echo ""

}

updateAllVSphereImageIPSettings()
{
  printHeaderMessage "Update VSphere Images IP Settings"
  setCoreOSStaticIPSettings ${CLUSTER_NAME}-bootstrap ${OCP_INSTALLBOOTSTRAP_IP}  ${OCP_INSTALL_GATEWAY} ${OCP_INSTALL_DNS} bootstrap
  setCoreOSStaticIPSettings ${CLUSTER_NAME}-master1 ${OCP_INSTALL_MASTER1_IP} ${OCP_INSTALL_GATEWAY} ${OCP_INSTALL_DNS} master1
  setCoreOSStaticIPSettings ${CLUSTER_NAME}-master2 ${OCP_INSTALL_MASTER2_IP} ${OCP_INSTALL_GATEWAY} ${OCP_INSTALL_DNS} master2
  setCoreOSStaticIPSettings ${CLUSTER_NAME}-master3 ${OCP_INSTALL_MASTER3_IP} ${OCP_INSTALL_GATEWAY} ${OCP_INSTALL_DNS} master3
  if [ "${VM_BUILD_WORKERS_NODES}" == "true" ]  ;then
      setCoreOSStaticIPSettings ${CLUSTER_NAME}-worker1 ${OCP_INSTALL_WORKER1_IP} ${OCP_INSTALL_GATEWAY} ${OCP_INSTALL_DNS} worker1
      setCoreOSStaticIPSettings ${CLUSTER_NAME}-worker2 ${OCP_INSTALL_WORKER2_IP} ${OCP_INSTALL_GATEWAY} ${OCP_INSTALL_DNS} worker2
      setCoreOSStaticIPSettings ${CLUSTER_NAME}-worker3 ${OCP_INSTALL_WORKER3_IP} ${OCP_INSTALL_GATEWAY} ${OCP_INSTALL_DNS} worker3
      if [ "${VM_TSHIRT_SIZE}" == "Large" ]  ;then
          setCoreOSStaticIPSettings ${CLUSTER_NAME}-worker4 ${OCP_INSTALL_WORKER4_IP} ${OCP_INSTALL_GATEWAY} ${OCP_INSTALL_DNS} worker4
          setCoreOSStaticIPSettings ${CLUSTER_NAME}-worker5 ${OCP_INSTALL_WORKER5_IP} ${OCP_INSTALL_GATEWAY} ${OCP_INSTALL_DNS} worker5
          setCoreOSStaticIPSettings ${CLUSTER_NAME}-worker6 ${OCP_INSTALL_WORKER6_IP} ${OCP_INSTALL_GATEWAY} ${OCP_INSTALL_DNS} worker6
      fi
  fi
  echo ""

}
deployAllIgnitionFiles()
{
  printHeaderMessage "Deploy ignition files to VSphere Images"
  if [ "${OCP_DEPLOY_ALL_IGNTIION_FILES_PAUSE}" == "true" ]; then
        read -p "Press [Enter] key to resume ..."
  fi
  deployIgnitionFiles ${CLUSTER_NAME}-bootstrap bootstrap
  deployIgnitionFiles ${CLUSTER_NAME}-master1 master
  deployIgnitionFiles ${CLUSTER_NAME}-master2 master
  deployIgnitionFiles ${CLUSTER_NAME}-master3 master
  if [ "${VM_BUILD_WORKERS_NODES}" == "true" ]  ;then
      deployIgnitionFiles ${CLUSTER_NAME}-worker1 worker
      deployIgnitionFiles ${CLUSTER_NAME}-worker2 worker
      deployIgnitionFiles ${CLUSTER_NAME}-worker3 worker
      if [ "${VM_TSHIRT_SIZE}" == "Large" ]  ;then
        deployIgnitionFiles ${CLUSTER_NAME}-worker4 worker
        deployIgnitionFiles ${CLUSTER_NAME}-worker5 worker
        deployIgnitionFiles ${CLUSTER_NAME}-worker6 worker
      fi
  fi
  echo ""
  blinkWaitMessage "Wait for 240 seconds to allow ignition install to complete" 240
  echo ""

}


deployIgnitionFiles()
{
   DIGF_VM_NAME=$1
   DIGF_VM_TYPE=$2
   echo "Deploying ignition files to ${DIGF_VM_NAME} of type ${DIGF_VM_TYPE}"
   cp ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/coreos-installer/install-* ${OPENSHFIT_INSTALL_DIR}
   chmod -fR 777  ${OPENSHFIT_INSTALL_DIR}
   sleep 2
   govc vm.keystrokes -vm ${DIGF_VM_NAME} -s "scp -o StrictHostKeyChecking=no ${BASTION_USER}@${BASTION_HOST}:${OPENSHFIT_INSTALL_DIR}/* ."
   govc vm.keystrokes -vm ${DIGF_VM_NAME} -c 0x28
   sleep 2
   govc vm.keystrokes -vm ${DIGF_VM_NAME} -s "${BASTION_PASSWORD}"
   govc vm.keystrokes -vm ${DIGF_VM_NAME} -c 0x28
   sleep 2
   govc vm.keystrokes -vm ${DIGF_VM_NAME} -s "./install-${DIGF_VM_TYPE}.sh"
   sleep 2
   govc vm.keystrokes -vm ${DIGF_VM_NAME} -c 0x28
}
setCoreOSStaticIPSettings()
{
  FSCIP_VM_NAME=$1
  FSCIP_STATIC_IP=$2
  FSCIP_GATEWAY=$3
  FSCIP_DNS_SERVER=$4
  FSCIP_NODE_NAME=$5
  echo "Updating IP settings for ${FSCIP_VM_NAME} - ipv4.method manual ipv4.address ${FSCIP_STATIC_IP}/${OCP_NODE_SUBNET_MASK}  ipv4.gateway ${FSCIP_GATEWAY} ipv4.dns ${FSCIP_DNS_SERVER} ipv4.dns-search ${OCP_HOST_NAME}"
  govc vm.keystrokes -vm ${FSCIP_VM_NAME} -s "nmcli con mod '${OCP_NET_CONNECTION_PROFILE}' ipv4.method manual ipv4.address "${FSCIP_STATIC_IP}/${OCP_NODE_SUBNET_MASK}" ipv4.gateway ${FSCIP_GATEWAY} ipv4.dns ${FSCIP_DNS_SERVER} ipv4.dns-search ${OCP_HOST_NAME}"
  govc vm.keystrokes -vm ${FSCIP_VM_NAME} -c 0x28
  govc vm.keystrokes -vm ${FSCIP_VM_NAME} -s "sudo hostnamectl set-hostname ${FSCIP_NODE_NAME}"
  govc vm.keystrokes -vm ${FSCIP_VM_NAME} -c 0x28
  govc vm.keystrokes -vm ${FSCIP_VM_NAME} -s "nmcli con mod '${OCP_NET_CONNECTION_PROFILE}' ipv6.method disabled"
  govc vm.keystrokes -vm ${FSCIP_VM_NAME} -c 0x28
  govc vm.keystrokes -vm ${FSCIP_VM_NAME} -s "nmcli con down '${OCP_NET_CONNECTION_PROFILE}'"
  govc vm.keystrokes -vm ${FSCIP_VM_NAME} -c 0x28
  govc vm.keystrokes -vm ${FSCIP_VM_NAME} -s "nmcli con up '${OCP_NET_CONNECTION_PROFILE}'"
  govc vm.keystrokes -vm ${FSCIP_VM_NAME} -c 0x28
  govc vm.keystrokes -vm ${FSCIP_VM_NAME} -s ifconfig
  govc vm.keystrokes -vm ${FSCIP_VM_NAME} -c 0x28
}
validateVSphereNodeIP()
{
	VVSNIP_VMNAME=$1
	VVSNIP_NAME_IP=$2
	VVSNIP_NAME_CURRENT_IP=`govc vm.info ${VVSNIP_VMNAME} | grep "IP address" | awk '{print $3 }'`
  if [ "${VVSNIP_NAME_CURRENT_IP}" != "${VVSNIP_NAME_IP}" ] ;then
        echo "${RED_TEXT}Node failed to set IP Config "
        echo "######################################################${RESET_TEXT}"
        echo "The following node ${VVSNIP_VMNAME}, was not able to configure its IP settings."
        echo "It was to set IP address of ${VVSNIP_NAME_IP} but the VM has IP of ${VVSNIP_NAME_CURRENT_IP}."
        echo "Please run the rebuild process from scratch to see if that corrects the issue."
        exit 99
  fi
}
createAllVSphereImages()
{
  printHeaderMessage "Create VSphere Images"
  createVCenterVMClusterMember ${CLUSTER_NAME}-bootstrap ${VM_BOOTSTRAP_VCPU} ${VM_BOOTSTRAP_RAM} ${VM_BOOTSTRAP_DISK1}
  createVCenterVMClusterMember ${CLUSTER_NAME}-master1 ${VM_MASTER_VCPU} ${VM_MASTER_RAM} ${VM_MASTER_DISK1}
  createVCenterVMClusterMember ${CLUSTER_NAME}-master2 ${VM_MASTER_VCPU} ${VM_MASTER_RAM} ${VM_MASTER_DISK1}
  createVCenterVMClusterMember ${CLUSTER_NAME}-master3 ${VM_MASTER_VCPU} ${VM_MASTER_RAM} ${VM_MASTER_DISK1}
  if [ "${VM_BUILD_WORKERS_NODES}" == "true" ]  ;then
      createVCenterVMClusterMember ${CLUSTER_NAME}-worker1 ${VM_WORKER_VCPU} ${VM_WORKER_RAM} ${VM_WORKER_DISK1}
      createVCenterVMClusterMember ${CLUSTER_NAME}-worker2 ${VM_WORKER_VCPU} ${VM_WORKER_RAM} ${VM_WORKER_DISK1}
      createVCenterVMClusterMember ${CLUSTER_NAME}-worker3 ${VM_WORKER_VCPU} ${VM_WORKER_RAM} ${VM_WORKER_DISK1}
  fi
  if [ "${VM_TSHIRT_SIZE}" == "Large" ] ;then
      createVCenterVMClusterMember ${CLUSTER_NAME}-worker4 ${VM_WORKER_VCPU} ${VM_WORKER_RAM} ${VM_WORKER_DISK1}
      createVCenterVMDisk ${CLUSTER_NAME}-worker4 ${IBM_OPENSHIFT_LOCAL_STORAGE_DEVICE_DISK2_NAME} ${VM_WORKER_DISK2} ${VSPHERE_FAST_DISK_DATASTORE}
      createVCenterVMDisk ${CLUSTER_NAME}-worker4 ${IBM_OPENSHIFT_LOCAL_STORAGE_DEVICE_DISK3_NAME}  ${VM_WORKER_DISK3} ${VSPHERE_FAST_DISK_DATASTORE}
      echo ""
      createVCenterVMClusterMember ${CLUSTER_NAME}-worker5 ${VM_WORKER_VCPU} ${VM_WORKER_RAM} ${VM_WORKER_DISK1}
      createVCenterVMDisk ${CLUSTER_NAME}-worker5 ${IBM_OPENSHIFT_LOCAL_STORAGE_DEVICE_DISK2_NAME}  ${VM_WORKER_DISK2} ${VSPHERE_FAST_DISK_DATASTORE}
      createVCenterVMDisk ${CLUSTER_NAME}-worker5 ${IBM_OPENSHIFT_LOCAL_STORAGE_DEVICE_DISK3_NAME} ${VM_WORKER_DISK3} ${VSPHERE_FAST_DISK_DATASTORE}
      echo ""
      createVCenterVMClusterMember ${CLUSTER_NAME}-worker6 ${VM_WORKER_VCPU} ${VM_WORKER_RAM} ${VM_WORKER_DISK1}
      createVCenterVMDisk ${CLUSTER_NAME}-worker6 ${IBM_OPENSHIFT_LOCAL_STORAGE_DEVICE_DISK2_NAME}  ${VM_WORKER_DISK2} ${VSPHERE_FAST_DISK_DATASTORE}
      createVCenterVMDisk ${CLUSTER_NAME}-worker6 ${IBM_OPENSHIFT_LOCAL_STORAGE_DEVICE_DISK3_NAME} ${VM_WORKER_DISK3} ${VSPHERE_FAST_DISK_DATASTORE}
  fi
  echo ""
  echo ""
  echo ""
  echo ""
  blinkWaitMessage "Sleeping for 120 seconds to allow VMs to boot up" 120
  echo ""

}


testVSphereAccess()
{

  printHeaderMessage "Test VSphere access via govc command."
  echo "VSphere Host Name : ${VSPHERE_HOSTNAME}"
  echo "VSphere Userid    : ${VSPHERE_USERNAME}"
  INVALID_GOVC_SETUP=`govc env 2>&1 | grep -c "specify an ESX or vCenter URL"`
  if [ ${INVALID_GOVC_SETUP} -eq 1 ] ;then
      echo "${RED_TEXT}VSphere variables were not setup:${RESET_TEXT}"
      echo "${RED_TEXT}VSPHERE_USERNAME=${VSPHERE_USERNAME}${RESET_TEXT}"
      echo "${RED_TEXT}VSPHERE_PASSWORD=${VSPHERE_PASSWORD}${RESET_TEXT}"
      echo "${RED_TEXT}VSPHERE_HOSTNAME=${VSPHERE_HOSTNAME}${RESET_TEXT}"
      echo "${RED_TEXT}Please update your shell profile for passowrd(~/.profile), and your env(example-env.sh) for others. ${RESET_TEXT}"
      SHOULD_EXIT=1
  else
      GOVC_ACCESS_TEST=`govc datacenter.info 2>&1`
      GOVC_SERVER_FAULT_CODE=`echo ${GOVC_ACCESS_TEST} | grep -c "ServerFaultCode:"`
      if [ ${GOVC_SERVER_FAULT_CODE} -eq 1 ] ;then
        echo "${RED_TEXT}VSphere Connection Issue:${RESET_TEXT}"
        echo "${RED_TEXT}${GOVC_ACCESS_TEST}${RESET_TEXT}"
        echo "${RED_TEXT}Please correct and try again.${RESET_TEXT}"
        echo ""
        exit 1
      else
        GOVC_SERVER_FAULT_CODE=`echo ${GOVC_ACCESS_TEST} | grep -c timeout`
        if [ ${GOVC_SERVER_FAULT_CODE} -eq 1 ] ;then
            echo "${RED_TEXT}VSphere Connection Issue:${RESET_TEXT}"
            echo "${RED_TEXT}${GOVC_ACCESS_TEST}${RESET_TEXT}"
            echo "${RED_TEXT}Please correct and try again.${RESET_TEXT}"
            echo ""
            exit 1
        else
            echo "${BLUE_TEXT}PASSED ${RESET_TEXT} Access for govc commands and VSphere"
            echo ""
        fi
      fi
  fi

}
createVCenterVMClusterMember()
{
  CVCVMC_VM_NAME=$1
  CVCVMC_VM_CPU=$2
  CVCVMC_VM_MEM=$3
  CVCVMC_VM_DISK=$4
  echo "Creating ${CVCVMC_VM_NAME}  -version=${ESXi_HARDWARE_VERSION_VM_CREATE} -on=false -g=${VSPHERE_COREOS_GUEST_ID} -c=${CVCVMC_VM_CPU} -m=${CVCVMC_VM_MEM} -net="${VSPHERE_NETWORK1}" -disk=${CVCVMC_VM_DISK}  -iso-datastore=${VSPHERE_ISO_DATASTORE} -iso=${VSPHERE_ISO_IMAGE_BASE}/${COREOS_ISO_IMAGE}" | tee -a  ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/vsphere-createVM.log
  govc vm.create -version=${ESXi_HARDWARE_VERSION_VM_CREATE} -on=false -g=${VSPHERE_COREOS_GUEST_ID} -c=${CVCVMC_VM_CPU} -m=${CVCVMC_VM_MEM} -net="${VSPHERE_NETWORK1}" -disk=${CVCVMC_VM_DISK} -iso-datastore="${VSPHERE_ISO_DATASTORE}" -iso="${VSPHERE_ISO_IMAGE_BASE}/${COREOS_ISO_IMAGE}" ${CVCVMC_VM_NAME}  | tee -a  ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/vsphere-createVM.log
  if [ "${VSPHERE_SYNC_TIME_WITH_HOST}" == "true"  ]; then
    echo "Enable -sync-time-with-host ${CVCVMC_VM_NAME}" | tee -a  ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/vsphere-createVM.log
    govc vm.change  -vm ${CVCVMC_VM_NAME} -sync-time-with-host | tee -a  ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/vsphere-createVM.log
  fi
  echo "Enable disk.enableUUID=TRUE ${CVCVMC_VM_NAME}" | tee -a  ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/vsphere-createVM.log
  govc vm.change -vm ${CVCVMC_VM_NAME} -e disk.enableUUID=TRUE  >>  ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/vsphere-createVM.log
  #createVCenterVMClusterMemberAdd2ndNetwork ${CVCVMC_VM_NAME} ${VSPHERE_NETWORK2}
  govc vm.power -on ${CVCVMC_VM_NAME} >>  ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/vsphere-createVM.log
  echo ""
}

createVCenterVMDisk()
{
    CVCVMD_VM_NAME=$1
    CVCVMD_VM_DISK_NAME=$2
    CVCVMD_VM_DISK_SIZE=$3
    CVCVMD_DATA_STORE=$4
    if [ -z ${CVCVMD_DATA_STORE} ]; then
      echo "Creating new disk: -vm ${CVCVMD_VM_NAME} -name ${CVCVMD_VM_NAME}/${CVCVMD_VM_DISK_NAME}.vmdk -size ${CVCVMD_VM_DISK_SIZE}" | tee -a  ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/vsphere-createDisk.log
      govc vm.disk.create -vm ${CVCVMD_VM_NAME} -name ${CVCVMD_VM_NAME}/${CVCVMD_VM_DISK_NAME}.vmdk -size ${CVCVMD_VM_DISK_SIZE} >>  ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/vsphere-createDisk.log 2>&1
    else
      echo "Creating new disk: -vm ${CVCVMD_VM_NAME} -name ${CVCVMD_VM_NAME}/${CVCVMD_VM_DISK_NAME}.vmdk -size ${CVCVMD_VM_DISK_SIZE}" -ds="${CVCVMD_DATA_STORE}"| tee -a  ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/vsphere-createDisk.log
      govc vm.disk.create -vm ${CVCVMD_VM_NAME} -name ${CVCVMD_VM_NAME}/${CVCVMD_VM_DISK_NAME}.vmdk -size ${CVCVMD_VM_DISK_SIZE} -ds="${CVCVMD_DATA_STORE}" >>  ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/vsphere-createDisk.log 2>&1
    fi
}

destroyVCenterVMClusterMember()
{
  DVCVMC_VM_NAME=$1
  echo "Destroying ${DVCVMC_VM_NAME}"
  govc vm.destroy ${DVCVMC_VM_NAME}

}
createVCenterVMClusterMemberAdd2ndNetwork()
{
  CVVMCMAN_VM_NAME=$1
  CVVMCMAN_NETWORK_NAME=$2
  if [ -z ${VSPHERE_NETWORK2+x} ] ;then
      NOTHING_TODO=true
  else
    echo "Adding 2nd network - ${CVVMCMAN_VM_NAME} ${CVVMCMAN_NETWORK_NAME}"
    govc vm.network.add -vm ${CVVMCMAN_VM_NAME} -net ${CVVMCMAN_NETWORK_NAME} >>  ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/vsphere-createVM.log
  fi

}

enableDHCPAllCoreOS2ndInterface()
{
  if [ -z ${VSPHERE_NETWORK2+x} ] ;then
      NOTHING_TODO=true
  else
      printHeaderMessage "Enable DHCP on Second Network Interface"
      createVCenterVMClusterMemberAdd2ndNetwork ${CLUSTER_NAME}-master1 ${VSPHERE_NETWORK2}
      sleep 5
      enableDHCPCoreOS master1.${OCP_HOST_NAME} ${VSPHERE_NETWORK2_INTERFACE_NAME}

      createVCenterVMClusterMemberAdd2ndNetwork ${CLUSTER_NAME}-master2 ${VSPHERE_NETWORK2}
      sleep 5
      enableDHCPCoreOS master2.${OCP_HOST_NAME} ${VSPHERE_NETWORK2_INTERFACE_NAME}

      createVCenterVMClusterMemberAdd2ndNetwork ${CLUSTER_NAME}-master3 ${VSPHERE_NETWORK2}
      sleep 5
      enableDHCPCoreOS master3.${OCP_HOST_NAME} ${VSPHERE_NETWORK2_INTERFACE_NAME}
      if [ "${VM_BUILD_WORKERS_NODES}" == "true" ]  ;then
          createVCenterVMClusterMemberAdd2ndNetwork ${CLUSTER_NAME}-worker1 ${VSPHERE_NETWORK2}
          sleep 5
          enableDHCPCoreOS worker1.${OCP_HOST_NAME} ${VSPHERE_NETWORK2_INTERFACE_NAME}

          createVCenterVMClusterMemberAdd2ndNetwork ${CLUSTER_NAME}-worker2 ${VSPHERE_NETWORK2}
          sleep 5
          enableDHCPCoreOS worker2.${OCP_HOST_NAME} ${VSPHERE_NETWORK2_INTERFACE_NAME}

          createVCenterVMClusterMemberAdd2ndNetwork ${CLUSTER_NAME}-worker3 ${VSPHERE_NETWORK2}
          sleep 5
          enableDHCPCoreOS worker3.${OCP_HOST_NAME} ${VSPHERE_NETWORK2_INTERFACE_NAME}
          if [ "${VM_TSHIRT_SIZE}" == "Large" ]  ;then
            createVCenterVMClusterMemberAdd2ndNetwork ${CLUSTER_NAME}-worker4 ${VSPHERE_NETWORK2}
            sleep 5
            enableDHCPCoreOS worker4.${OCP_HOST_NAME} ${VSPHERE_NETWORK2_INTERFACE_NAME}

            createVCenterVMClusterMemberAdd2ndNetwork ${CLUSTER_NAME}-worker5 ${VSPHERE_NETWORK2}
            sleep 5
            enableDHCPCoreOS worker5.${CLUSTER_NAME} ${VSPHERE_NETWORK2_INTERFACE_NAME}

            createVCenterVMClusterMemberAdd2ndNetwork ${CLUSTER_NAME}-worker6 ${VSPHERE_NETWORK2}
            sleep 5
            enableDHCPCoreOS worker6.${CLUSTER_NAME} ${VSPHERE_NETWORK2_INTERFACE_NAME}
          fi
      fi
  fi

}
enableDHCPCoreOS()
{
   EDHCPCOS_HOST_NAME=$1
   EDHCPCOS_INTERFACE_NAME=$2
   printf "\n${EDHCPCOS_HOST_NAME} - ${EDHCPCOS_INTERFACE_NAME} #######################\n\n" >> ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/vsphere-enableVM2ndNetworkDHCP.log
   ssh -oStrictHostKeyChecking=no -i ${SSH_KEY_FILE} core@${EDHCPCOS_HOST_NAME} "sudo dhclient ${EDHCPCOS_INTERFACE_NAME} -v"  2>> ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/vsphere-enableVM2ndNetworkDHCP.log
}
approveVCenterCert()
{
  printHeaderMessage "Approve VCenter Cert (LOG ${LOG_DIR}/${PRODUCT_SHORT_NAME}/update-vcenter-ca-certificates.log)"
  if [ -n ${VSPHERE_HOSTNAME} ]; then
      if [ ${IS_UBUNTU}  -eq 1 ]; then
        if [ ! -f  ${LOCAL_CA_CERT_FOLDER}/${VSPHERE_HOSTNAME}.crt ]; then
            echo "${LOCAL_CA_CERT_FOLDER}/${VSPHERE_HOSTNAME}.crt file does NOT exists, download current one - $VSPHERE_HOSTNAME:$VSPHERE_PORT_NUMBER"
            echo -n | openssl s_client -connect $VSPHERE_HOSTNAME:$VSPHERE_PORT_NUMBER -servername $VSPHERE_HOSTNAME 2> ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/get-vcenter-ca-certificates.log | openssl x509 > ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/$VSPHERE_HOSTNAME.crt
            cp  ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/${VSPHERE_HOSTNAME}.crt ${LOCAL_CA_CERT_FOLDER}
            echo "Update local CA Cert Database via os command - update-ca-certificates (UBUNTU)"
            update-ca-certificates 1>> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/update-vcenter-ca-certificates.log
        fi
      fi
      if [ ${IS_RH} -eq 1 ]; then
          if [ ! -f  ${LOCAL_CA_CERT_FOLDER}/${VSPHERE_HOSTNAME}.zip ]; then
              echo "${LOCAL_CA_CERT_FOLDER}/${VSPHERE_HOSTNAME}.zip file does NOT exists, download current one - https://${VSPHERE_HOSTNAME}/certs/download.zip"
              wget -O ${LOCAL_CA_CERT_FOLDER}/${VSPHERE_HOSTNAME}.zip https://${VSPHERE_HOSTNAME}/certs/download.zip --no-check-certificate &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/update-vcenter-ca-certificates.log
              unzip -d ${LOCAL_CA_CERT_FOLDER} ${LOCAL_CA_CERT_FOLDER}/${VSPHERE_HOSTNAME}.zip 1>> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/update-vcenter-ca-certificates.log
              cp ${LOCAL_CA_CERT_FOLDER}/certs/lin/* ${LOCAL_CA_CERT_FOLDER} >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/update-vcenter-ca-certificates.log 2>&1
              rm -fR ${LOCAL_CA_CERT_FOLDER}/certs 1>> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/update-vcenter-ca-certificates.log
              echo "Update local CA Cert Database via os command - update-ca-trust extract (RHEL)"
              update-ca-trust extract 1>> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/update-vcenter-ca-certificates.log
          fi
      fi
  else
        echo "${RED_TEXT}Missing VSPHERE_HOSTNAME= variable, can not download certs.${RESET_TEXT}"
  fi
  echo ""

}
validateVSpherePermission()
{
  printHeaderMessage "Validate Current User Permission on VCenter"
  case  ${OCP_INSTALL_TYPE} in
    vsphere-*)
          createVMWareFoldersFullPath
          TEST_VM_NAME="test-vm-${CLUSTER_NAME}"
          TEST_FOLDER_NAME="${VSPHERE_FOLDER}/test-folder-${CLUSTER_NAME}"
          govc vm.destroy ${TEST_VM_NAME} &> /dev/null
          govc object.destroy "${TEST_FOLDER_NAME}" &> /dev/null
          FOLDER_CREATE_ERROR=`govc folder.create "${TEST_FOLDER_NAME}" 2>&1 | grep -v "already exists" | grep -c govc:`
          if [ "${FOLDER_CREATE_ERROR}" == "1" ] ;then
             echo "${RED_TEXT}Missing Permission to create Folder in VSphere"
             govc folder.create "${TEST_FOLDER_NAME}"
             SHOULD_EXIT=1
             echo "${RESET_TEXT}"
          else
            echo "${BLUE_TEXT}PASSED ${RESET_TEXT} Folder Create"
            govc object.destroy "${TEST_FOLDER_NAME}" &> /dev/null
            echo "${BLUE_TEXT}PASSED ${RESET_TEXT} Folder Delete"
          fi
          VM_CREATE_ERROR=`govc vm.create -version=${ESXi_HARDWARE_VERSION_VM_CREATE} -on=false -g=${VSPHERE_COREOS_GUEST_ID} -c=1 -m=16000 -net="${VSPHERE_NETWORK1}" -disk=120g -folder="${VSPHERE_FOLDER}"  ${TEST_VM_NAME} 2>&1 | grep -c govc:`
          if [ "${VM_CREATE_ERROR}" == "1" ] ;then
             echo "${RED_TEXT}Missing Permission to create VM in VSphere"
             govc vm.create -version=${ESXi_HARDWARE_VERSION_VM_CREATE} -on=false -g=${VSPHERE_COREOS_GUEST_ID} -c=1 -m=16000 -net="${VSPHERE_NETWORK1}" -disk=120g -folder="${VSPHERE_FOLDER}" ${TEST_VM_NAME}
             echo "One of the of the follwing permissions was not available to current user:"
             echo "FAILED?: VM Edit Inventory Create New"
             echo "FAILED?: VM Change CPU count Permission"
             echo "FAILED?: VM Change Memory Permission"
             echo "FAILED?: VM Add new disk Permission"
             echo "FAILED?: VM Advanced configuration Permission"
             echo "FAILED?: VM Change Settings  Permission"
             echo "FAILED?: Network Assign network"
             echo "FAILED?: Assign virtual machine to resource pool"
             SHOULD_EXIT=1
             echo "${RESET_TEXT}"
          else
            echo "${BLUE_TEXT}PASSED ${RESET_TEXT} VM Edit Inventory Create New"
            echo "${BLUE_TEXT}PASSED ${RESET_TEXT} VM Change CPU count Permission"
            echo "${BLUE_TEXT}PASSED ${RESET_TEXT} VM Change Memory Permission"
            echo "${BLUE_TEXT}PASSED ${RESET_TEXT} VM Add new disk Permission"
            echo "${BLUE_TEXT}PASSED ${RESET_TEXT} VM Advanced configuration Permission"
            echo "${BLUE_TEXT}PASSED ${RESET_TEXT} VM Change Settings  Permission"
            echo "${BLUE_TEXT}PASSED ${RESET_TEXT} Network Assign network"
            echo "${BLUE_TEXT}PASSED ${RESET_TEXT} Assign virtual machine to resource pool"
            VM_SYNC_WITH_HOST_ERROR=`govc vm.change  -vm ${TEST_VM_NAME} -sync-time-with-host  2>&1 | grep -c govc:`
            if [ "${VM_SYNC_WITH_HOST_ERROR}" == "1" ] ;then
              echo "${RED_TEXT}FAILED: VM Change Configuration Advanced configuration${RESET_TEXT}"
              SHOULD_EXIT=1
            else
              echo "${BLUE_TEXT}PASSED ${RESET_TEXT} VM Change Configuration Advanced configuration"
            fi
            VM_DISK_ENBLE_UUID=`govc vm.change  -vm ${TEST_VM_NAME} -e disk.enableUUID=TRUE  2>&1 | grep -c govc:`
            if [ "${VM_DISK_ENBLE_UUID}" == "1" ] ;then
              echo "${RED_TEXT}FAILED: VM Change Configuration Toggle disk change tracking${RESET_TEXT}"
              SHOULD_EXIT=1
            else
              echo "${BLUE_TEXT}PASSED ${RESET_TEXT} VM Change Configuration Toggle disk change tracking "
            fi
            VM_POWER_ON_ERROR=`govc vm.power -on   ${TEST_VM_NAME} 2>&1 | grep -c govc:`
            if [ "${VM_POWER_ON_ERROR}" == "1" ] ;then
              echo "${RED_TEXT}FAILED: VM Interaction Power On${RESET_TEXT}"
              SHOULD_EXIT=1
            else
              echo "${BLUE_TEXT}PASSED ${RESET_TEXT} VM Interaction Power On"
            fi
          fi
          if [ "${OCP_INSTALL_TYPE}" == "vsphere-upi" ]; then
            VM_SEND_KEYSTROKES_ERROR=`govc vm.keystrokes -vm ${TEST_VM_NAME} -s "Test"   ${TEST_VM_NAME} 2>&1 | grep -c govc:`
            if [ "${VM_SEND_KEYSTROKES_ERROR}" == "1" ] ;then
              echo "${RED_TEXT}FAILED: VM Interaction Inject USB HID scan codes${RESET_TEXT}"
              SHOULD_EXIT=1
            else
              echo "${BLUE_TEXT}PASSED ${RESET_TEXT} VM Interaction Inject USB HID scan codes "
            fi
          fi
          if [ "${OCP_INSTALL_TYPE}" == "vsphere-ipi" ]; then
            CATEGORIES_CREATE_ERROR=`govc tags.category.create test-category-${CLUSTER_NAME} 2>&1 | grep -c govc:`
            if [ "${CATEGORIES_CREATE_ERROR}" == "1" ] ;then
               echo "${RED_TEXT}Missing Permission to create Categories in VSphere"
               govc tags.category.create  -d "Test zone" test-zone
               echo "${RESET_TEXT}"
               SHOULD_EXIT=1
            else
              echo "${BLUE_TEXT}PASSED ${RESET_TEXT} vSphere Tagging Create vSphere Tag Category"
              CATEGORIES_DELETE_ERROR=`govc tags.category.rm test-category-${CLUSTER_NAME}  2>&1 | grep -c govc:`
              if [ "${CATEGORIES_DELETE_ERROR}" == "1" ] ;then
                 echo "${RED_TEXT}Missing Permission to delete Categories in VSphere${RESET_TEXT}"
                 SHOULD_EXIT=1
              else
                echo "${BLUE_TEXT}PASSED ${RESET_TEXT} vSphere Tagging Delete vSphere Tag Category"
              fi
            fi
          fi
          ;;
    esac
    VM_POWER_OFF_ERROR=`govc vm.power -off ${TEST_VM_NAME} 2>&1 | grep -c govc:`
    if [ "${VM_POWER_OFF_ERROR}" == "1" ] ;then
      echo "${RED_TEXT}FAILED: VM Interaction Power Off${RESET_TEXT}"
      SHOULD_EXIT=1
    else
      echo "${BLUE_TEXT}PASSED ${RESET_TEXT} VM Interaction Power Off"
      govc vm.power -on   ${TEST_VM_NAME} &> /dev/null
    fi
    VM_SEND_KEYSTROKES_ERROR=`govc vm.destroy ${TEST_VM_NAME} 2>&1 | grep -c govc:`
    if [ "${VM_SEND_KEYSTROKES_ERROR}" == "1" ] ;then
      echo "${RED_TEXT}FAILED: VM Edit Inventory Remove${RESET_TEXT}"
      SHOULD_EXIT=1
    else
      echo "${BLUE_TEXT}PASSED ${RESET_TEXT} VM Edit Inventory Remove"
    fi
}
updateVMWareInstallConfig()
{
  NEW_VM_WORKER_DISK1=`echo ${VM_WORKER_DISK1} |  sed  "s/\([a-zA-Z]\)$//"`
  sed -i'' "s/diskSizeGB: ${VM_WORKER_DISK1}/diskSizeGB: ${NEW_VM_WORKER_DISK1}/" ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/providers/vsphere/install-config.yaml
  NEW_VM_MASTER_DISK1=`echo ${VM_MASTER_DISK1} |  sed  "s/\([a-zA-Z]\)$//"`
  sed -i'' "s/diskSizeGB: ${VM_MASTER_DISK1}/diskSizeGB: ${NEW_VM_MASTER_DISK1}/" ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/providers/vsphere/install-config.yaml
}
createVMWareFoldersFullPath()
{
  case ${OCP_INSTALL_TYPE} in
    vsphere-*)
          printHeaderMessage "Validate/Build VSphere Folders"
          GOVC_FOLDER1=`echo ${GOVC_FOLDER%/*}`
          GOVC_FOLDER2=`echo ${GOVC_FOLDER1%/*}`
          GOVC_FOLDER3=`echo ${GOVC_FOLDER2%/*}`
          GOVC_FOLDER4=`echo ${GOVC_FOLDER3%/*}`
          GOVC_FOLDER5=`echo ${GOVC_FOLDER4%/*}`
          GOVC_FOLDER6=`echo ${GOVC_FOLDER5%/*}`
          GOVC_FOLDER7=`echo ${GOVC_FOLDER6%/*}`
          GOVC_FOLDER8=`echo ${GOVC_FOLDER7%/*}`
          NOT_FOUND=`govc tree $GOVC_FOLDER8 | grep -c "not found"`
          if [ "${NOT_FOUND}" == "1" ];then
                echo "Building ${GOVC_FOLDER8}"
                govc folder.create ${GOVC_FOLDER8} >& /dev/null
          fi
          NOT_FOUND=`govc tree $GOVC_FOLDER7 | grep -c "not found"`
            if [ "${NOT_FOUND}" == "1" ];then
                echo "Building ${GOVC_FOLDER7}"
                govc folder.create ${GOVC_FOLDER7} >& /dev/null
          fi
          NOT_FOUND=`govc tree $GOVC_FOLDER6 | grep -c "not found"`
            if [ "${NOT_FOUND}" == "1" ];then
                echo "Building ${GOVC_FOLDER6}"
                govc folder.create ${GOVC_FOLDER6} >& /dev/null
          fi
          NOT_FOUND=`govc tree $GOVC_FOLDER5 | grep -c "not found"`
            if [ "${NOT_FOUND}" == "1" ];then
                echo "Building ${GOVC_FOLDER5}"
                govc folder.create ${GOVC_FOLDER5} >& /dev/null
          fi
          NOT_FOUND=`govc tree $GOVC_FOLDER4 | grep -c "not found"`
            if [ "${NOT_FOUND}" == "1" ];then
                echo "Building ${GOVC_FOLDER4}"
                govc folder.create ${GOVC_FOLDER4} >& /dev/null
          fi
          NOT_FOUND=`govc tree $GOVC_FOLDER3 | grep -c "not found"`
            if [ "${NOT_FOUND}" == "1" ];then
               echo "Building ${GOVC_FOLDER3}"
                govc folder.create ${GOVC_FOLDER3} >& /dev/null
          fi
          NOT_FOUND=`govc tree $GOVC_FOLDER2 | grep -c "not found"`
            if [ "${NOT_FOUND}" == "1" ];then
                echo "Building ${GOVC_FOLDER2}"
                govc folder.create ${GOVC_FOLDER2} >& /dev/null
          fi
          NOT_FOUND=`govc tree $GOVC_FOLDER1 | grep -c "not found"`
            if [ "${NOT_FOUND}" == "1" ];then
                echo "Building ${GOVC_FOLDER1}"
                govc folder.create ${GOVC_FOLDER1} >& /dev/null
          fi
          NOT_FOUND=`govc tree $GOVC_FOLDER | grep -c "not found"`
            if [ "${NOT_FOUND}" == "1" ];then
                echo "Building ${GOVC_FOLDER}"
                govc folder.create ${GOVC_FOLDER}  >& /dev/null
          fi
    esac
    echo ""
}

vmwareAddOpenShiftContainerStorageDisk()
{
  AVWD_DISK_SIZE=$1
  AVWD_DISK_NAME=$2
  NODE_LIST=`oc get nodes | grep worker | awk '{print $1}'`
  local workerLoop=1
  for WORKER_NODE_NAME in $NODE_LIST
  do
    createVCenterVMDisk ${WORKER_NODE_NAME} ${IBM_OPENSHIFT_LOCAL_STORAGE_DEVICE_DISK2_NAME}  ${VM_WORKER_DISK2} ${VSPHERE_FAST_DISK_DATASTORE}
    createVCenterVMDisk ${WORKER_NODE_NAME} ${IBM_OPENSHIFT_LOCAL_STORAGE_DEVICE_DISK3_NAME}  ${VM_WORKER_DISK3} ${VSPHERE_FAST_DISK_DATASTORE}
    let workerLoop=workerLoop+1
    if [ $workerLoop -gt 3 ]; then
      #only add disk to first three nodes.
      break
    fi
  done
}

validateVSphereUPINodes()
{
  echo ""
  printHeaderMessage "VSPhere-upi Validate Master and Worker Size"
  case  ${VM_TSHIRT_SIZE} in
    Large)
      if [ "${VM_NUMBER_OF_WORKERS_LARGE}"  -eq 6 ]; then
        echo "${BLUE_TEXT}PASSED ${RESET_TEXT} Worker size of 6 is Valid"
      else
        SHOULD_EXIT=1
        echo "${RED_TEXT}FAILED: Unsupported Worker size.  VSphere UPI for large only supports Worker size of 6. Please correct and try again.${RESET_TEXT}"
      fi
      if [ "${VM_NUMBER_OF_MASTERS_LARGE}"  -eq 3 ]; then
        echo "${BLUE_TEXT}PASSED ${RESET_TEXT} Master size of 3 is Valid"
      else
        SHOULD_EXIT=1
        echo "${RED_TEXT}FAILED: Unsupported Master size.  VSphere UPI for large only supports Worker size of 3. Please correct and try again.${RESET_TEXT}"
      fi
      ;;
    Min)
      if [ "${VM_NUMBER_OF_WORKERS_MIN}"  -eq 3 ]; then
        echo "${BLUE_TEXT}PASSED ${RESET_TEXT} Worker size of 3 is Valid"
      else
          SHOULD_EXIT=1
          echo "${RED_TEXT}FAILED: Unsupported Worker size.  VSphere UPI for Min only supports Worker size of 3. Please correct and try again.${RESET_TEXT}"
      fi
      if [ "${VM_NUMBER_OF_MASTERS_MIN}"  -eq 3 ]; then
        echo "${BLUE_TEXT}PASSED ${RESET_TEXT} Master size of 3 is Valid"
      else
        SHOULD_EXIT=1
        echo "${RED_TEXT}FAILED: Unsupported Master size.  VSphere UPI for Min only supports Master size of 3. Please correct and try again.${RESET_TEXT}"
      fi
      ;;
    *)
      SHOULD_EXIT=1
      echo "${RED_TEXT}FAILED: Unsupported T-Shirt Size for VSphere UPI. Min or Large supported only. Please correct and try again.${RESET_TEXT}"
    ;;
esac
echo ""


}


displayVSpherePermissionsNeeded()
{
  case  ${OCP_INSTALL_TYPE} in
    vsphere-upi)
        printHeaderMessage "VSPhere-upi VCenter Permissions Needed"
        echo "
Datastore
    Allocate space
    Browse datastore
    Update virtual machine files
    Update virtual machine metadata
Folder
    Create folder
    Delete folder
Network
    Assign network
Resource
    Assign virtual machine to resource pool
Virtual machine
    Change Configuration
        Add new disk
        Advanced configuration
        Change CPU count
        Change Memory
        Change Settings
        Reset guest information
        Set annotation
        Toggle disk change tracking
        Upgrade virtual machine compatibility
    Edit Inventory
        Create new
        Register
        Remove
        Unregister
    Interaction
        Inject USB HID scan codes
        Power off
        Power on
        Reset"
        ;;
    vsphere-ipi)
        printHeaderMessage "VSPhere-ipi VCenter Permissions Needed"
        echo "
Cns
    Searchable
Datastore
    Allocate space
    Browse datastore
    Low level file operations
Folder
    Create folder
    Delete folder
vSphere Tagging
    Assign or Unassign vSphere Tag
    Create vSphere Tag
    Create vSphere Tag Category
    Delete vSphere Tag
    Delete vSphere Tag Category
Network
    Assign network
Resource
    Assign virtual machine to resource pool
Sessions
    Validate session
Profile-driven storage
    Profile-driven storage view
Storage views
    View
vApp
    Assign resource pool
    Import
Virtual machine
    Change Configuration
        Acquire disk lease
        Add existing disk
        Add new disk
        Add or remove device
        Advanced configuration
        Change CPU count
        Change Memory
        Change Settings
        Change resource
        Extend virtual disk
        Modify device settings
        Remove disk
        Rename
        Reset guest information
        Set annotation
        Upgrade virtual machine compatibility
    Edit Inventory
        Create from existing
        Create new
        Remove
    Interaction
        Power off
        Power on
    Provisioning
        Clone virtual machine"
          ;;
  esac

}
