#!/bin/bash
############################################################
#Author           : Kyle Dawson
#Author email     : Kyle.Dawson@us.ibm.com
#Original Date    : 2021-09-25
#Initial Version  : v2021-12-01
############################################################
#VM T-Shirt Sizing
##################################################

defineVMTShirtSize()
{
  echo ""
  printHeaderMessage "Current T-Shirt Sizing Info"
  if [[ "${CURRENT_SCRIPT_NAME}" == *build.sh ]];then
    case ${VM_TSHIRT_SIZE} in
      "Min")
        echo "Setting VM T-Shirt Size to Minimum"
        VM_CURRENT_TSHIRT_SIZE_TAG=MIN
        VM_BOOTSTRAP_VCPU=${VM_BOOTSTRAP_VCPU_MIN}
        VM_BOOTSTRAP_RAM=${VM_BOOTSTRAP_RAM_MIN}
        VM_BOOTSTRAP_DISK1=${VM_BOOTSTRAP_DISK1_MIN}
        VM_NUMBER_OF_MASTERS=${VM_NUMBER_OF_MASTERS_MIN}
        VM_MASTER_VCPU=${VM_MASTER_VCPU_MIN}
        VM_MASTER_RAM=${VM_MASTER_RAM_MIN}
        VM_MASTER_DISK1=${VM_MASTER_DISK1_MIN}
        VM_WORKER_VCPU=${VM_WORKER_VCPU_MIN}
        VM_WORKER_RAM=${VM_WORKER_RAM_MIN}
        VM_WORKER_DISK1=${VM_WORKER_DISK1_MIN}
        VM_NUMBER_OF_WORKERS=${VM_NUMBER_OF_WORKERS_MIN}
        if [  "${VM_BUILD_WORKERS_NODES}"  == "true" ]; then
          let VM_NUMBER_OF_IMAGES=${VM_NUMBER_OF_WORKERS_MIN}+4
        else
          let VM_NUMBER_OF_IMAGES=4
        fi
        GCP_MACHINE_TYPE_BOOTSTRAP=${GCP_MACHINE_TYPE_BOOTSTRAP_MIN}-${GCP_MACHINE_TYPE_BOOTSTRAP_CPU_MIN}
        GCP_MACHINE_TYPE_MASTER=${GCP_MACHINE_TYPE_MASTER_MIN}-${GCP_MACHINE_TYPE_MASTER_CPU_MIN}
        GCP_MACHINE_TYPE_WORKER=${GCP_MACHINE_TYPE_WORKER_MIN}-${GCP_MACHINE_TYPE_WORKER_CPU_MIN}
        GCP_MACHINE_TYPE_BOOTSTRAP_CPU=${GCP_MACHINE_TYPE_BOOTSTRAP_CPU_MIN}
        GCP_MACHINE_TYPE_MASTER_CPU=${GCP_MACHINE_TYPE_MASTER_CPU_MIN}
        GCP_MACHINE_TYPE_WORKER_CPU=${GCP_MACHINE_TYPE_WORKER_CPU_MIN}
        AZURE_MACHINE_TYPE_BOOTSTRAP=${AZURE_MACHINE_TYPE_MASTER_MIN}
        AZURE_MACHINE_TYPE_MASTER=${AZURE_MACHINE_TYPE_MASTER_MIN}
        AZURE_MACHINE_TYPE_WORKER=${AZURE_MACHINE_TYPE_WORKER_MIN}
        AZURE_MACHINE_TYPE_BOOTSTRAP_CPU=${AZURE_MACHINE_TYPE_MASTER_CPU_MIN}
        AZURE_MACHINE_TYPE_MASTER_CPU=${AZURE_MACHINE_TYPE_MASTER_CPU_MIN}
        AZURE_MACHINE_TYPE_WORKER_CPU=${AZURE_MACHINE_TYPE_WORKER_CPU_MIN}
        AWS_MACHINE_TYPE_BOOTSTRAP=${AWS_MACHINE_TYPE_MASTER_MIN}
        AWS_MACHINE_TYPE_MASTER=${AWS_MACHINE_TYPE_MASTER_MIN}
        AWS_MACHINE_TYPE_WORKER=${AWS_MACHINE_TYPE_WORKER_MIN}
        AWS_MACHINE_TYPE_BOOTSTRAP_CPU=${AWS_MACHINE_TYPE_MASTER_CPU_MIN}
        AWS_MACHINE_TYPE_MASTER_CPU=${AWS_MACHINE_TYPE_MASTER_CPU_MIN}
        AWS_MACHINE_TYPE_WORKER_CPU=${AWS_MACHINE_TYPE_WORKER_CPU_MIN}
        ROKS_FLAVOR=${ROKS_FLAVOR_MIN}
        ROKS_WORKERS=${VM_NUMBER_OF_WORKERS_MIN}
        ROSA_FLAVOR=${ROSA_FLAVOR_MIN}
        ROSA_WORKERS=${VM_NUMBER_OF_WORKERS_MIN}
        ROSA_MACHINE_TYPE_CPU=${ROSA_MACHINE_TYPE_CPU_MIN}
        displayTShirtSizeInfo
        ;;
      "Large")
        echo "Setting VM T-Shirt Size to Large"
        VM_CURRENT_TSHIRT_SIZE_TAG=LARGE
        VM_BOOTSTRAP_VCPU=${VM_BOOTSTRAP_VCPU_LARGE}
        VM_BOOTSTRAP_RAM=${VM_BOOTSTRAP_RAM_LARGE}
        VM_BOOTSTRAP_DISK1=${VM_BOOTSTRAP_DISK1_LARGE}
        VM_NUMBER_OF_MASTERS=${VM_NUMBER_OF_MASTERS_LARGE}
        VM_MASTER_VCPU=${VM_MASTER_VCPU_LARGE}
        VM_MASTER_RAM=${VM_MASTER_RAM_LARGE}
        VM_MASTER_DISK1=${VM_MASTER_DISK1_LARGE}
        VM_WORKER_VCPU=${VM_WORKER_VCPU_LARGE}
        VM_WORKER_RAM=${VM_WORKER_RAM_LARGE}
        VM_WORKER_DISK1=${VM_WORKER_DISK1_LARGE}
        VM_WORKER_DISK2=${VM_WORKER_DISK2_LARGE}
        VM_WORKER_DISK3=${VM_WORKER_DISK3_LARGE}
        VM_NUMBER_OF_WORKERS=${VM_NUMBER_OF_WORKERS_LARGE}
        if [  "${VM_BUILD_WORKERS_NODES}"  == "true" ]; then
          let VM_NUMBER_OF_IMAGES=${VM_NUMBER_OF_WORKERS_LARGE}+4
        else
          let VM_NUMBER_OF_IMAGES=4
        fi
        GCP_MACHINE_TYPE_BOOTSTRAP=${GCP_MACHINE_TYPE_BOOTSTRAP_LARGE}-${GCP_MACHINE_TYPE_BOOTSTRAP_CPU_LARGE}
        GCP_MACHINE_TYPE_MASTER=${GCP_MACHINE_TYPE_MASTER_LARGE}-${GCP_MACHINE_TYPE_MASTER_CPU_LARGE}
        GCP_MACHINE_TYPE_WORKER=${GCP_MACHINE_TYPE_WORKER_LARGE}-${GCP_MACHINE_TYPE_WORKER_CPU_LARGE}
        GCP_MACHINE_TYPE_BOOTSTRAP_CPU=${GCP_MACHINE_TYPE_BOOTSTRAP_CPU_LARGE}
        GCP_MACHINE_TYPE_MASTER_CPU=${GCP_MACHINE_TYPE_MASTER_CPU_LARGE}
        GCP_MACHINE_TYPE_WORKER_CPU=${GCP_MACHINE_TYPE_WORKER_CPU_LARGE}
        AZURE_MACHINE_TYPE_BOOTSTRAP=${AZURE_MACHINE_TYPE_MASTER_LARGE}
        AZURE_MACHINE_TYPE_MASTER=${AZURE_MACHINE_TYPE_MASTER_LARGE}
        AZURE_MACHINE_TYPE_WORKER=${AZURE_MACHINE_TYPE_WORKER_LARGE}
        AZURE_MACHINE_TYPE_BOOTSTRAP_CPU=${AZURE_MACHINE_TYPE_MASTER_CPU_LARGE}
        AZURE_MACHINE_TYPE_MASTER_CPU=${AZURE_MACHINE_TYPE_MASTER_CPU_LARGE}
        AZURE_MACHINE_TYPE_WORKER_CPU=${AZURE_MACHINE_TYPE_WORKER_CPU_LARGE}
        AWS_MACHINE_TYPE_BOOTSTRAP=${AWS_MACHINE_TYPE_MASTER_LARGE}
        AWS_MACHINE_TYPE_MASTER=${AWS_MACHINE_TYPE_MASTER_LARGE}
        AWS_MACHINE_TYPE_WORKER=${AWS_MACHINE_TYPE_WORKER_LARGE}
        AWS_MACHINE_TYPE_BOOTSTRAP_CPU=${AWS_MACHINE_TYPE_MASTER_CPU_LARGE}
        AWS_MACHINE_TYPE_MASTER_CPU=${AWS_MACHINE_TYPE_MASTER_CPU_LARGE}
        AWS_MACHINE_TYPE_WORKER_CPU=${AWS_MACHINE_TYPE_WORKER_CPU_LARGE}
        ROKS_FLAVOR=${ROKS_FLAVOR_LARGE}
        ROKS_WORKERS=${VM_NUMBER_OF_WORKERS_LARGE}
        ROSA_FLAVOR=${ROSA_FLAVOR_LARGE}
        ROSA_WORKERS=${VM_NUMBER_OF_WORKERS_LARGE}
        ROSA_MACHINE_TYPE_CPU=${ROSA_MACHINE_TYPE_CPU_LARGE}
        displayTShirtSizeInfo
        ;;
    *)
      SHOULD_EXIT=1
      echo "${RED_TEXT}VM T-Shirt Sizing value blank or not valid${RESET_TEXT}"
      echo "${RED_TEXT}VM_TSHIRT_SIZE=${VM_TSHIRT_SIZE} ${RESET_TEXT}"
      echo "${RED_TEXT}Current Supported Values Min or Large  ${RESET_TEXT}"
    esac
  fi
  echo ""
}
displayTShirtSizeInfo()
{
  case ${VM_TSHIRT_SIZE} in
    "Min")
      VM_CURRENT_TSHIRT_SIZE_TAG=MIN
      ;;
  "Large")
      VM_CURRENT_TSHIRT_SIZE_TAG=LARGE
      ;;
  esac
  case ${OCP_INSTALL_TYPE} in
    kvm-upi)
        echo "KVM Platform:"
        let "KVM_MACHINE_TYPE_CPU_TOTAL = ${VM_NUMBER_OF_MASTERS} * ${VM_MASTER_VCPU}"
        let "KVM_MACHINE_TYPE_CPU_TOTAL = ${KVM_MACHINE_TYPE_CPU_TOTAL} + ${VM_NUMBER_OF_WORKERS} * ${VM_WORKER_VCPU}"
        let "KVM_MACHINE_TYPE_CPU_TOTAL = ${KVM_MACHINE_TYPE_CPU_TOTAL} + ${VM_BOOTSTRAP_VCPU}"
        echo ""
        echo "Bootstrap:"
        echo "--------------------------------------------------"
        echo "VM_BOOTSTRAP_VCPU_${VM_CURRENT_TSHIRT_SIZE_TAG}=${VM_BOOTSTRAP_VCPU}"
        echo "VM_BOOTSTRAP_DISK1_${VM_CURRENT_TSHIRT_SIZE_TAG}=${VM_BOOTSTRAP_DISK1}"
        echo "VM_BOOTSTRAP_RAM_${VM_CURRENT_TSHIRT_SIZE_TAG}=${VM_BOOTSTRAP_RAM}"
        echo ""
        echo "Master:"
        echo "--------------------------------------------------"
        echo "VM_MASTER_VCPU_${VM_CURRENT_TSHIRT_SIZE_TAG}=${VM_MASTER_VCPU}"
        echo "VM_MASTER_RAM_${VM_CURRENT_TSHIRT_SIZE_TAG}=${VM_MASTER_RAM}"
        echo "VM_MASTER_DISK1_${VM_CURRENT_TSHIRT_SIZE_TAG}=${VM_MASTER_DISK1}"
        if [ "${VM_BUILD_WORKERS_NODES}" == "true" ]  ;then
          echo ""
          echo "Workers:"
          echo "--------------------------------------------------"
          echo "VM_NUMBER_OF_WORKERS_${VM_CURRENT_TSHIRT_SIZE_TAG}=${VM_NUMBER_OF_WORKERS_LARGE}"
          echo "VM_WORKER_VCPU_${VM_CURRENT_TSHIRT_SIZE_TAG}=${VM_WORKER_VCPU}"
          echo "VM_WORKER_RAM_${VM_CURRENT_TSHIRT_SIZE_TAG}=${VM_WORKER_RAM}"
          echo "VM_WORKER_DISK1_${VM_CURRENT_TSHIRT_SIZE_TAG}=${VM_WORKER_DISK1}"
          if [ "${VM_TSHIRT_SIZE}" == "Large" ] && [ "${OCP_CREATE_OPENSHIFT_CONTAINER_STORAGE}" == "true" ]  ;then
              echo ""
              echo "OpenShift Storage Cluster Storage(FileSystem):"
              echo "--------------------------------------------------"
              echo "VM_WORKER_DISK2_${VM_CURRENT_TSHIRT_SIZE_TAG}=${VM_WORKER_DISK2}"
              echo ""
              echo "OpenShift Storage Cluster Storage(Block):"
              echo "--------------------------------------------------"
              echo "VM_WORKER_DISK3_${VM_CURRENT_TSHIRT_SIZE_TAG}=${VM_WORKER_DISK3}"
              echo ""
          fi
        else
          echo "VM_BUILD_WORKERS_NODES=_${VM_CURRENT_TSHIRT_SIZE_TAG}${VM_BUILD_WORKERS_NODES}"
          echo "Not building seperate worker nodes."
        fi
        echo "Totals"
        echo "--------------------------------------------------"
        let "KVM_CPU_TOTAL = ${VM_NUMBER_OF_MASTERS} * ${VM_MASTER_VCPU}"
        let "KVM_CPU_TOTAL = ${KVM_CPU_TOTAL} + ${VM_NUMBER_OF_WORKERS} * ${VM_WORKER_VCPU}"
        echo "VCPU = ${KVM_CPU_TOTAL}"
        KVM_STORGE_BOOTSTRAP_DISK1=`echo ${VM_BOOTSTRAP_DISK1} | sed "s/G//g"`
        KVM_STORGE_MASTER_DISK1=`echo ${VM_MASTER_DISK1} | sed "s/G//g"`
        KVM_STORGE_WORKER_DISK1=`echo ${VM_WORKER_DISK1} | sed "s/G//g"`
        KVM_STORGE_WORKER_DISK2=`echo ${VM_WORKER_DISK2} | sed "s/G//g"`
        KVM_STORGE_WORKER_DISK3=`echo ${VM_WORKER_DISK3} | sed "s/G//g"`
        let "KVM_STORGE_TOTAL = ${KVM_STORGE_TOTAL} + ${VM_NUMBER_OF_MASTERS} * ${KVM_STORGE_MASTER_DISK1}"
        let "KVM_STORGE_TOTAL = ${KVM_STORGE_TOTAL} + ${VM_NUMBER_OF_WORKERS} * ${KVM_STORGE_WORKER_DISK1}"
        case ${VM_TSHIRT_SIZE} in
          Large)
              let "KVM_STORGE_TOTAL = ${KVM_STORGE_TOTAL} + 3 * ${KVM_STORGE_WORKER_DISK2}"
              let "KVM_STORGE_TOTAL = ${KVM_STORGE_TOTAL} + 3 * ${KVM_STORGE_WORKER_DISK3}"
              ;;
        esac
        echo "Storage = ${KVM_STORGE_TOTAL}G"

        let "KVM_RAM_TOTAL = ${KVM_RAM_TOTAL} + ${VM_NUMBER_OF_MASTERS} * ${VM_MASTER_RAM}"
        let "KVM_RAM_TOTAL = ${KVM_RAM_TOTAL} + ${VM_NUMBER_OF_WORKERS} * ${VM_WORKER_RAM}"
        echo "RAM = ${KVM_RAM_TOTAL}MB"
        ;;
    vsphere-*)
        echo "VSphere Platform:"
        echo ""
        echo "Bootstrap:"
        echo "--------------------------------------------------"
        echo "VM_BOOTSTRAP_VCPU_${VM_CURRENT_TSHIRT_SIZE_TAG}=${VM_BOOTSTRAP_VCPU}"
        echo "VM_BOOTSTRAP_DISK1_${VM_CURRENT_TSHIRT_SIZE_TAG}=${VM_BOOTSTRAP_DISK1}"
        echo "VM_BOOTSTRAP_RAM_${VM_CURRENT_TSHIRT_SIZE_TAG}=${VM_BOOTSTRAP_RAM}"
        echo ""
        echo "Master:"
        echo "--------------------------------------------------"
        echo "VM_NUMBER_OF_MASTERS_${VM_CURRENT_TSHIRT_SIZE_TAG}=${VM_NUMBER_OF_MASTERS}"
        echo "VM_MASTER_VCPU_${VM_CURRENT_TSHIRT_SIZE_TAG}=${VM_MASTER_VCPU}"
        echo "VM_MASTER_RAM_${VM_CURRENT_TSHIRT_SIZE_TAG}=${VM_MASTER_RAM}"
        echo "VM_MASTER_DISK1_${VM_CURRENT_TSHIRT_SIZE_TAG}=${VM_MASTER_DISK1}"
        echo ""
        if [ "${VM_BUILD_WORKERS_NODES}" == "true" ]  ;then
          echo "Workers:"
          echo "--------------------------------------------------"
          echo "VM_NUMBER_OF_WORKERS_${VM_CURRENT_TSHIRT_SIZE_TAG}=${VM_NUMBER_OF_WORKERS}"
          echo "VM_WORKER_VCPU_${VM_CURRENT_TSHIRT_SIZE_TAG}=${VM_WORKER_VCPU}"
          echo "VM_WORKER_RAM_${VM_CURRENT_TSHIRT_SIZE_TAG}=${VM_WORKER_RAM}"
          echo "VM_WORKER_DISK1_${VM_CURRENT_TSHIRT_SIZE_TAG}=${VM_WORKER_DISK1}"
          echo ""
        else
          echo "VM_BUILD_WORKERS_NODES_${VM_CURRENT_TSHIRT_SIZE_TAG}=${VM_BUILD_WORKERS_NODES}"
          echo "Not building seperate worker nodes."
        fi
        if [ "${VM_TSHIRT_SIZE}" == "Large" ] && [ "${OCP_CREATE_OPENSHIFT_CONTAINER_STORAGE}" == "true" ]  ;then
            echo ""
            echo "OpenShift Storage Cluster Storage(Filesystem):"
            echo "--------------------------------------------------"
            echo "VM_WORKER_DISK2_${VM_CURRENT_TSHIRT_SIZE_TAG}=${VM_WORKER_DISK2}"
            echo ""
            echo "OpenShift Storage Cluster Storage(Block):"
            echo "--------------------------------------------------"
            echo "VM_WORKER_DISK3_${VM_CURRENT_TSHIRT_SIZE_TAG}=${VM_WORKER_DISK3}"
            echo ""
        fi
        echo "Totals"
        echo "--------------------------------------------------"
        let "VSPHERE_CPU_TOTAL = ${VM_NUMBER_OF_MASTERS} * ${VM_MASTER_VCPU}"
        let "VSPHERE_CPU_TOTAL = ${VSPHERE_CPU_TOTAL} + ${VM_NUMBER_OF_WORKERS} * ${VM_WORKER_VCPU}"
        echo "VCPU  = ${VSPHERE_CPU_TOTAL}"
        VSPHERE_STORGE_BOOTSTRAP_DISK1=`echo ${VM_BOOTSTRAP_DISK1} | sed "s/G//g"`
        VSPHERE_STORGE_MASTER_DISK1=`echo ${VM_MASTER_DISK1} | sed "s/G//g"`
        VSPHERE_STORGE_WORKER_DISK1=`echo ${VM_WORKER_DISK1} | sed "s/G//g"`
        VSPHERE_STORGE_WORKER_DISK2=`echo ${VM_WORKER_DISK2} | sed "s/G//g"`
        VSPHERE_STORGE_WORKER_DISK3=`echo ${VM_WORKER_DISK3} | sed "s/G//g"`
        let "VSPHERE_STORGE_TOTAL = ${VSPHERE_STORGE_TOTAL} + ${VM_NUMBER_OF_MASTERS} * ${VSPHERE_STORGE_MASTER_DISK1}"
        let "VSPHERE_STORGE_TOTAL = ${VSPHERE_STORGE_TOTAL} + ${VM_NUMBER_OF_WORKERS} * ${VSPHERE_STORGE_WORKER_DISK1}"
        case ${VM_TSHIRT_SIZE} in
          Large)
              let "VSPHERE_STORGE_TOTAL = ${VSPHERE_STORGE_TOTAL} + 3 * ${VSPHERE_STORGE_WORKER_DISK2}"
              let "VSPHERE_STORGE_TOTAL = ${VSPHERE_STORGE_TOTAL} + 3 * ${VSPHERE_STORGE_WORKER_DISK3}"
              ;;
        esac
        echo "Storage  = ${VSPHERE_STORGE_TOTAL}G"
        let "VSPHERE_RAM_TOTAL = ${VSPHERE_RAM_TOTAL} + ${VM_NUMBER_OF_MASTERS} * ${VM_MASTER_RAM}"
        let "VSPHERE_RAM_TOTAL = ${VSPHERE_RAM_TOTAL} + ${VM_NUMBER_OF_WORKERS} * ${VM_WORKER_RAM}"
        echo "RAM  = ${VSPHERE_RAM_TOTAL} MB"
        ;;
    gcp-ipi)
        echo "Google Cloud Platform:"
        let "GCP_MACHINE_TYPE_CPU_TOTAL = ${VM_NUMBER_OF_MASTERS} * ${GCP_MACHINE_TYPE_MASTER_CPU}"
        let "GCP_MACHINE_TYPE_CPU_TOTAL = ${GCP_MACHINE_TYPE_CPU_TOTAL} + ${VM_NUMBER_OF_WORKERS} * ${GCP_MACHINE_TYPE_WORKER_CPU}"
        let "GCP_MACHINE_TYPE_CPU_TOTAL = ${GCP_MACHINE_TYPE_CPU_TOTAL} + ${GCP_MACHINE_TYPE_BOOTSTRAP_CPU}"
        GCP_STORGE_BOOTSTRAP_DISK1=`echo ${VM_BOOTSTRAP_DISK1} | sed "s/G//g"`
        GCP_STORGE_MASTER_DISK1=`echo ${VM_MASTER_DISK1} | sed "s/G//g"`
        GCP_STORGE_WORKER_DISK1=`echo ${VM_WORKER_DISK1} | sed "s/G//g"`
        GCP_STORGE_WORKER_DISK2=`echo ${VM_WORKER_DISK2} | sed "s/G//g"`
        GCP_STORGE_WORKER_DISK3=`echo ${VM_WORKER_DISK3} | sed "s/G//g"`
        let "GCP_STORGE_TOTAL = ${VM_NUMBER_OF_MASTERS} * ${GCP_STORGE_BOOTSTRAP_DISK1}"
        let "GCP_STORGE_TOTAL = ${GCP_STORGE_TOTAL} + ${VM_NUMBER_OF_MASTERS} * ${GCP_STORGE_MASTER_DISK1}"
        let "GCP_STORGE_TOTAL = ${GCP_STORGE_TOTAL} + ${VM_NUMBER_OF_WORKERS} * ${GCP_STORGE_WORKER_DISK1}"
        case ${VM_TSHIRT_SIZE} in
          Large)
              let "GCP_STORGE_TOTAL = ${GCP_STORGE_TOTAL} + ${VM_NUMBER_OF_WORKERS} * ${GCP_STORGE_WORKER_DISK2}"
              let "GCP_STORGE_TOTAL = ${GCP_STORGE_TOTAL} + ${VM_NUMBER_OF_WORKERS} * ${GCP_STORGE_WORKER_DISK3}"
              ;;
        esac
        echo "Bootstrap Node type = ${GCP_MACHINE_TYPE_BOOTSTRAP}"
        echo "GCP_MACHINE_TYPE_BOOTSTRAP_CPU_${VM_CURRENT_TSHIRT_SIZE_TAG}=${GCP_MACHINE_TYPE_BOOTSTRAP_CPU}"
        echo ""
        echo "Master Nodes:"
        echo "--------------------------------------------------"
        echo "GCP_MACHINE_TYPE_MASTER_${VM_CURRENT_TSHIRT_SIZE_TAG}=${GCP_MACHINE_TYPE_MASTER}"
        echo "VM_NUMBER_OF_MASTERS_${VM_CURRENT_TSHIRT_SIZE_TAG}=${VM_NUMBER_OF_MASTERS}"
        echo "GCP_MACHINE_TYPE_MASTER_CPU_${VM_CURRENT_TSHIRT_SIZE_TAG}=${GCP_MACHINE_TYPE_MASTER_CPU}"
        echo ""
        echo "Worker Nodes:"
        echo "--------------------------------------------------"
        echo "GCP_MACHINE_TYPE_WORKER_${VM_CURRENT_TSHIRT_SIZE_TAG}=${GCP_MACHINE_TYPE_WORKER}"
        echo "VM_NUMBER_OF_WORKERS_${VM_CURRENT_TSHIRT_SIZE_TAG}=${VM_NUMBER_OF_WORKERS}"
        echo "GCP_MACHINE_TYPE_WORKER_CPU_${VM_CURRENT_TSHIRT_SIZE_TAG}=${GCP_MACHINE_TYPE_WORKER_CPU}"
        if [ "${VM_TSHIRT_SIZE}" == "Large" ] && [ "${OCP_CREATE_OPENSHIFT_CONTAINER_STORAGE}" == "true" ]  ;then
            echo ""
            echo "OpenShift Storage Cluster Storage(Block):"
            echo "--------------------------------------------------"
            echo "VM_WORKER_DISK2_${VM_CURRENT_TSHIRT_SIZE_TAG}=${VM_WORKER_DISK2}"
            echo ""
            echo "OpenShift Storage Cluster Storage(Block):"
            echo "--------------------------------------------------"
            echo "VM_WORKER_DISK3_${VM_CURRENT_TSHIRT_SIZE_TAG}=${VM_WORKER_DISK3}"
        fi
        ;;
    azure-ipi)
        echo "Azure Platform:"
        let "AZURE_MACHINE_TYPE_CPU_TOTAL = ${VM_NUMBER_OF_MASTERS} * ${AZURE_MACHINE_TYPE_MASTER_CPU}"
        let "AZURE_MACHINE_TYPE_CPU_TOTAL = ${AZURE_MACHINE_TYPE_CPU_TOTAL} + ${VM_NUMBER_OF_WORKERS} * ${AZURE_MACHINE_TYPE_WORKER_CPU}"
        let "AZURE_MACHINE_TYPE_CPU_TOTAL = ${AZURE_MACHINE_TYPE_CPU_TOTAL} + ${AZURE_MACHINE_TYPE_BOOTSTRAP_CPU}"
        AZURE_STORGE_TOTAL="?????"
        echo "Bootstrap Node type = ${AZURE_MACHINE_TYPE_BOOTSTRAP}(1)"
        echo ""
        echo "Master Nodes:"
        echo "--------------------------------------------------"
        echo "AZURE_MACHINE_TYPE_MASTER_${VM_CURRENT_TSHIRT_SIZE_TAG}=${AZURE_MACHINE_TYPE_MASTER}"
        echo "VM_NUMBER_OF_MASTERS_${VM_CURRENT_TSHIRT_SIZE_TAG}=${VM_NUMBER_OF_MASTERS}"
        echo "AZURE_MACHINE_TYPE_MASTER_CPU_${VM_CURRENT_TSHIRT_SIZE_TAG}=${AZURE_MACHINE_TYPE_MASTER_CPU}"
        echo ""
        echo "Worker Nodes:"
        echo "--------------------------------------------------"
        echo "AZURE_MACHINE_TYPE_WORKER_${VM_CURRENT_TSHIRT_SIZE_TAG}=${AZURE_MACHINE_TYPE_WORKER}"
        echo "VM_NUMBER_OF_WORKERS_${VM_CURRENT_TSHIRT_SIZE_TAG}=${VM_NUMBER_OF_WORKERS}"
        echo "AZURE_MACHINE_TYPE_WORKER_CPU_${VM_CURRENT_TSHIRT_SIZE_TAG}=${AZURE_MACHINE_TYPE_WORKER_CPU}"
        if [ "${VM_TSHIRT_SIZE}" == "Large" ] && [ "${OCP_CREATE_OPENSHIFT_CONTAINER_STORAGE}" == "true" ]  ;then
            echo ""
            echo "OpenShift Storage Cluster Storage(Filesytem):"
            echo "--------------------------------------------------"
            echo "VM_WORKER_DISK2_${VM_CURRENT_TSHIRT_SIZE_TAG}=${VM_WORKER_DISK2}"
            echo ""
            echo "OpenShift Storage Cluster Storage(Block):"
            echo "--------------------------------------------------"
            echo "VM_WORKER_DISK3_${VM_CURRENT_TSHIRT_SIZE_TAG}=${VM_WORKER_DISK3}"
            echo ""
        fi
        ;;
    aws-ipi)
        echo "AWS Platform:"
        let "AWS_MACHINE_TYPE_CPU_TOTAL = ${VM_NUMBER_OF_MASTERS} * ${AWS_MACHINE_TYPE_MASTER_CPU}"
        let "AWS_MACHINE_TYPE_CPU_TOTAL = ${AWS_MACHINE_TYPE_CPU_TOTAL} + ${VM_NUMBER_OF_WORKERS} * ${AWS_MACHINE_TYPE_WORKER_CPU}"
        let "AWS_MACHINE_TYPE_CPU_TOTAL = ${AWS_MACHINE_TYPE_CPU_TOTAL} + ${AWS_MACHINE_TYPE_BOOTSTRAP_CPU}"
        AWS_STORGE_TOTAL="?????"
        VM_WORKER_DISK2=${AWS_OCP_OCS_STORAGE_CLASS_FILE_SIZE}
        VM_WORKER_DISK3=${AWS_OCP_OCS_STORAGE_CLASS_BLOCK_SIZE}
        echo "Bootstrap Node type = ${AWS_MACHINE_TYPE_BOOTSTRAP}"
        echo ""
        echo "Master Nodes:"
        echo "--------------------------------------------------"
        echo "AWS_MACHINE_TYPE_MASTER_${VM_CURRENT_TSHIRT_SIZE_TAG}=${AWS_MACHINE_TYPE_MASTER}"
        echo "VM_NUMBER_OF_MASTERS_${VM_CURRENT_TSHIRT_SIZE_TAG}=${VM_NUMBER_OF_MASTERS}"
        echo "AWS_MACHINE_TYPE_MASTER_CPU_${VM_CURRENT_TSHIRT_SIZE_TAG}=${AWS_MACHINE_TYPE_MASTER_CPU}"
        echo ""
        echo "Worker Nodes"
        echo "--------------------------------------------------"
        echo "AWS_MACHINE_TYPE_WORKER_${VM_CURRENT_TSHIRT_SIZE_TAG}=${AWS_MACHINE_TYPE_WORKER}"
        echo "VM_NUMBER_OF_WORKERS_${VM_CURRENT_TSHIRT_SIZE_TAG}=${VM_NUMBER_OF_WORKERS}"
        echo "AWS_MACHINE_TYPE_WORKER_CPU_${VM_CURRENT_TSHIRT_SIZE_TAG}=${AWS_MACHINE_TYPE_WORKER_CPU}"
        if [ "${VM_TSHIRT_SIZE}" == "Large" ] && [ "${OCP_CREATE_OPENSHIFT_CONTAINER_STORAGE}" == "true" ]  ;then
            echo ""
            echo "OpenShift Storage Cluster Storage(Filesytem):"
            echo "--------------------------------------------------"
            echo "AWS_OCP_OCS_STORAGE_CLASS_FILE_SIZE=${AWS_OCP_OCS_STORAGE_CLASS_FILE_SIZE}"
            echo ""
            echo "OpenShift Storage Cluster Storage(Block):"
            echo "--------------------------------------------------"
            echo "AWS_OCP_OCS_STORAGE_CLASS_BLOCK_SIZE=${AWS_OCP_OCS_STORAGE_CLASS_BLOCK_SIZE}"
        fi
       ;;
   roks-msp)
        echo "ROKS Platform:"
        echo "ROKS_FLAVOR_${VM_CURRENT_TSHIRT_SIZE_TAG}=${ROKS_FLAVOR}"
        echo "VM_NUMBER_OF_WORKERS_${VM_CURRENT_TSHIRT_SIZE_TAG}=${VM_NUMBER_OF_WORKERS}"
        ;;
   rosa-msp)
        echo "ROSA Platform:"
        echo "Worker/Master Node Flavor = ${ROSA_FLAVOR}(${ROSA_WORKERS})"
        let "AWS_MACHINE_TYPE_CPU_TOTAL = 3 * ${ROSA_MACHINE_TYPE_CPU}"
        let "AWS_MACHINE_TYPE_CPU_TOTAL = ${AWS_MACHINE_TYPE_CPU_TOTAL} + ${ROSA_WORKERS} * ${ROSA_MACHINE_TYPE_CPU}"
        let "AWS_MACHINE_TYPE_CPU_TOTAL = ${AWS_MACHINE_TYPE_CPU_TOTAL} + ${ROSA_BOOTSTRAP_CPU}"
        let "AWS_MACHINE_TYPE_CPU_TOTAL = ${AWS_MACHINE_TYPE_CPU_TOTAL} + 2 * ${ROSA_INFRA_CPU}"
        #if [ ${OCP_CREATE_OPENSHIFT_CONTAINER_STORAGE} = "true" ]; then
        #    let "AWS_MACHINE_TYPE_CPU_TOTAL = ${AWS_MACHINE_TYPE_CPU_TOTAL} + ${ROSA_WORKERS} * ${ROSA_MACHINE_TYPE_CPU}"
        #    echo "Total CPU needed = ${AWS_MACHINE_TYPE_CPU_TOTAL}"
        #else
        echo "Total CPU needed = ${AWS_MACHINE_TYPE_CPU_TOTAL}"
        #fi
        ;;
  esac
}
