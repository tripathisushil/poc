#!/bin/bash
############################################################
#Author           : Kyle Dawson
#Author email     : Kyle.Dawson@us.ibm.com
#Original Date    : 2021-08-10
#Initial Version  : v2021-12-01
############################################################
#Setup Variables
############################################################
DIR="$( cd "$( dirname "$0" )" && pwd )"
PRODUCT_SHORT_NAME=ocp
PRODUCT_FUNCTION=cleanup
ENVIRONMENT_FILE=${1}
source ${DIR}/../env/${1}-env.sh &> /dev/null
source ${DIR}/env.sh
source ${DIR}/../env.sh
source ${DIR}/../functions.sh
source ${DIR}/functions.sh
start=$SECONDS

#Source other functions
#############################################
source ${DATA_DIR}/${PROJECT_NAME}/util/providers/vmware.sh
source ${DATA_DIR}/${PROJECT_NAME}/util/providers/gcp.sh
source ${DATA_DIR}/${PROJECT_NAME}/util/providers/azure.sh
source ${DATA_DIR}/${PROJECT_NAME}/util/providers/aws.sh
#source ${DATA_DIR}/${PROJECT_NAME}/util/providers/rosa.sh
source ${DATA_DIR}/${PROJECT_NAME}/util/ibmcloud.sh
source ${DATA_DIR}/${PROJECT_NAME}/util/tshirt.sh
source ${DATA_DIR}/${PROJECT_NAME}/util/providers/macos.sh
mkdir -p ${LOG_DIR}/${PRODUCT_SHORT_NAME}

OS
if [ "$MAC" == true ]; then
   macCheckOCP
   macPrepareHost
   macSetupContainer
   macGetDaffy
   macCopyEnvFile
   case ${2} in
     --*)
        echo "Running container with podman exec -it daffy /bin/bash -c "/data/daffy/ocp/cleanup.sh ${ENVIRONMENT_FILE} ${2}""
        echo "${RESET_TEXT}"
        echo ""
        podman exec -it daffy /bin/bash -c "/data/daffy/ocp/cleanup.sh ${ENVIRONMENT_FILE} ${2}"
        exit 99 # Exiting script due to work being done in container
        ;;
   esac
fi

case ${2} in
  confirm)
       DAFFY_LIVE_ON_THE_EDGE="true"
       ;;
  --help|--?|?|-?|help|-help)
       printHeaderMessage "Help Menu for cleanup flags"
       echo "No Help system for cleanup."
       exit 0
       ;;
   --*|-*)
       echo "${RED_TEXT}Unsupported flag in command line - ${2}. ${RESET_TEXT}"
       echo ""
       exit 9
       ;;
esac

updateDaffyStats
#PreTest Check for required files
########################
SHOULD_EXIT=0
mkdir -p ${TEMP_DIR}/${PRODUCT_SHORT_NAME}
if [ "$MAC" == true ]; then
   macOCPCleanup
   exit 99 #Exiting script due to work being done in container
fi
if [ "${DAFFY_LIVE_ON_THE_EDGE}" != "true" ] ;then
    read -p "${RED_TEXT}Are you sure you want to destroy the ENTIRE cluster ?( Enter Yes to confirm)    :  ${RESET_TEXT}" CONFIRM_DESTROY
    if [ ${CONFIRM_DESTROY} != "Yes" ] ;then
      echo "FAILED - Will NOT destroy cluster, Exiting Script!!!!!!!!!!!!!!!!!!!"
      exit 1
    fi
fi
preChecksOCP

if [ ${SHOULD_EXIT} == 1 ] ;then
  echo ""
  echo ""
  echo "${RED_TEXT}Missing above required resources/permissions. Exiting Script!!!!!!!${RESET_TEXT}"
  echo ""
  echo ""
  exit 1
fi
printHeaderMessage "Cleanup VM Systems" ${RED_TEXT}
case "${OCP_INSTALL_TYPE}" in
  kvm-upi)
        virsh destroy bootstrap  2> /dev/null
        virsh undefine bootstrap 2> /dev/null
        virsh destroy master1 2> /dev/null
        virsh undefine master1 2> /dev/null
        virsh destroy master2 2> /dev/null
        virsh undefine master2 2> /dev/null
        virsh destroy master3 2> /dev/null
        virsh undefine master3 2> /dev/null
        virsh destroy worker1 2> /dev/null
        virsh undefine worker1 2> /dev/null
        virsh destroy worker2 2> /dev/null
        virsh undefine worker2 2> /dev/null
        virsh destroy worker3 2> /dev/null
        virsh undefine worker3 2> /dev/null
        virsh destroy worker4 2> /dev/null
        virsh undefine worker4 2> /dev/null
        virsh destroy worker5 2> /dev/null
        virsh undefine worker5 2> /dev/null
        virsh destroy worker6 2> /dev/null
        virsh undefine worker6 2> /dev/null
        virsh destroy worker7 2> /dev/null
        virsh undefine worker7 2> /dev/null
        virsh destroy worker8 2> /dev/null
        virsh undefine worker8 2> /dev/null
        virsh destroy worker9 2> /dev/null
        virsh undefine worker9 2> /dev/null
        virsh destroy nfs-server 2> /dev/null
        virsh undefine nfs-server 2> /dev/null
        ;;
vsphere-upi )
        export GOVC_INSECURE=1
        export GOVC_USERNAME=${VSPHERE_USERNAME}
        export GOVC_PASSWORD=${VSPHERE_PASSWORD}
        export GOVC_URL="${VSPHERE_HOSTNAME}"
        echo "GOVC_URL=${GOVC_URL}"
        destroyVCenterVMClusterMember ${CLUSTER_NAME}-bootstrap
        destroyVCenterVMClusterMember ${CLUSTER_NAME}-master1
        destroyVCenterVMClusterMember ${CLUSTER_NAME}-master2
        destroyVCenterVMClusterMember ${CLUSTER_NAME}-master3
        destroyVCenterVMClusterMember ${CLUSTER_NAME}-worker1
        destroyVCenterVMClusterMember ${CLUSTER_NAME}-worker2
        destroyVCenterVMClusterMember ${CLUSTER_NAME}-worker3
        destroyVCenterVMClusterMember ${CLUSTER_NAME}-worker4
        destroyVCenterVMClusterMember ${CLUSTER_NAME}-worker5
        destroyVCenterVMClusterMember ${CLUSTER_NAME}-worker6
        ;;
  *-ipi )
        if [  -d "${TEMP_DIR}/${PRODUCT_SHORT_NAME}/ocp-install" ]; then
            cd ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/ocp-install
            openshift-install destroy cluster
        fi
        ;;
  roks-msp )
        echo "ibmcloud ks cluster rm --cluster ${CLUSTER_NAME} -f --force-delete-storage -q --skip-advance-permissions-check "
        ibmcloud ks cluster rm --cluster ${CLUSTER_NAME} -f --force-delete-storage -q --skip-advance-permissions-check | tee ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ibm-roks-delete-cluster.log
        waitForROKSClusterDeleted
        ;;
  #rosa-msp )
        #echo "rosa delete cluster --cluster=${CLUSTER_NAME} -y"
        #rosa delete cluster --cluster=${CLUSTER_NAME} -y
        #waitForROSAClusterDeleted
        #;;
esac
echo ""

if [ "${OCP_INSTALL_TYPE}"  ==  "kvm-upi" ] ;then
  printHeaderMessage "Cleanup Storage Pool" ${RED_TEXT}
  echo "VM_VOL_STORAGE_POOL = ${VM_VOL_STORAGE_POOL}"
  echo "VM_IMAGE_ROOT_PATH = ${VM_IMAGE_ROOT_PATH}"
  if [  ${VM_VOL_STORAGE_POOL}  != "uvtool" ] ;then
      virsh pool-destroy ${VM_VOL_STORAGE_POOL}
      virsh pool-undefine ${VM_VOL_STORAGE_POOL}
      rm -f ${VM_IMAGE_ROOT_PATH}/*.*
      virsh pool-list --all
  else
      virsh pool-destroy ${VM_VOL_STORAGE_POOL}
      rm -f ${VM_IMAGE_ROOT_PATH}/*.*
      virsh pool-list --all
  fi
  echo ""

  printHeaderMessage "Cleanup Network" ${RED_TEXT}
  virsh net-undefine ocp 2> /dev/null
  virsh net-destroy ocp 2> /dev/null
  rm -fR /tmp/netplan_* 2> /dev/null
fi
echo ""

if [ "${HAPROXY_BUILD}" == "true"  ];then
    printHeaderMessage "Cleanup haproxy" ${RED_TEXT}
    echo "Stopping haproxy service"
    systemctl stop haproxy > /dev/null 2>&1
    echo "Removing haproxy program"
    apt-get -y remove haproxy > /dev/null 2>&1
    echo "Replace haproxy config file  with template original  - ${DATA_DIR}/${PROJECT_NAME}/${PRODUCT_SHORT_NAME}/templates/haproxy/haproxy.cfg  ----> /etc/haproxy/haproxy.cfg"
    cp -fR ${DATA_DIR}/${PROJECT_NAME}/${PRODUCT_SHORT_NAME}/templates/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg &> /dev/null

    echo ""
fi
if [ "${DNSMASQ_BUILD}" == "true"  ];then
    printHeaderMessage "Cleanup dnsmasq" ${RED_TEXT}
    rm -fR /etc/init.d/daffy.dnsmasq.sh &> /dev/null
    rm -fR /etc/rc5.d/S02daffy.dnsmasq &> /dev/null
    rm -fR /etc/rc6.d/S02daffy.dnsmasq &> /dev/null
fi

if [ "${OCP_INSTALL_TYPE}"  ==  "kvm-upi" ] ;then
  printHeaderMessage "Cleanup Matchbox" ${RED_TEXT}
  systemctl stop matchbox
  userdel matchbox
  if [[ ${MATCHBOX_CLEANUP} == "true" ]]; then
      echo "rm -fR  /usr/local/bin/matchbox${RESET_TEXT}"
      rm -fR  /usr/local/bin/matchbox
      echo "rm -fR /var/lib/matchbox${RESET_TEXT}"
      rm -fR  /var/lib/matchbox
      echo ""
   else
     echo "Skipping Matchbox Cleanup because MATCHBOX_CLEANUP was not true"
     echo "MATCHBOX_CLEANUP=${MATCHBOX_CLEANUP}"
   fi
fi

printHeaderMessage "Cleanup OpenShift Tools" ${RED_TEXT}
if [[ ${OCP_TOOLS_CLEANUP} == "true" ]]; then
  echo "rm -f /usr/local/bin/openshift-install"
  rm -f /usr/local/bin/openshift-install
  echo "rm -f /usr/local/bin/oc"
  rm -f /usr/local/bin/oc
  echo "rm -f /usr/local/bin/kubectl"
  rm -f /usr/local/bin/kubectl
  echo "rm -f /var/lib/matchbox/assets/ocp{4.6,4.7,4.8,4.10}"
  rm -f /var/lib/matchbox/assets/ocp{4.6,4.7,4.8,4.10}
else
    echo "Skipping OpenShift Tools Cleanup because OCP_TOOLS_CLEANUP was not true"
    echo "OCP_TOOLS_CLEANUP=${OCP_TOOLS_CLEANUP}"
fi
rm -fR ${OCP_KUBECONFIG_DIR}/${CLUSTER_NAME}
echo ""

printHeaderMessage "Cleanup Local NFS" ${RED_TEXT}
echo "Remove exports from ${NFS_EXPORTS} - ${NFS_FILE_SYSTEM}"
sed -i'' "s|$NFS_FILE_SYSTEM.*||g"  ${NFS_EXPORTS} > /dev/null 2>&1
sed -i '/^$/d' ${NFS_EXPORTS}> /dev/null 2>&1
if [ "${IS_UBUNTU}" == 1 ]; then
  echo "Stop NFS Service"
  systemctl stop nfs-kernel-server &> /dev/null
  echo "Remove NFS Service"
  ${OS_INSTALL} remove -y nfs-kernel-server nfs-common > /dev/null 2>&1
fi
if [ "${IS_RH}" == 1 ]; then
  echo "Stop NFS Service"
  systemctl disable nfs-server rpcbind &> /dev/null
  echo "Remove NFS Service"
  ${OS_INSTALL} remove -y nfs-utils > /dev/null 2>&1
fi
rm -fR ${NFS_FILE_SYSTEM} > /dev/null 2>&1
echo ""

case "${OCP_INSTALL_TYPE}" in
  kvm-upi)
    printHeaderMessage "Cleanup VMDashboard" ${RED_TEXT}
    echo "apt-get -y remove apache2 mysql-server php libapache2-mod-php php-mysql php-xml php-libvirt-php python"
    apt-get -y remove apache2 mysql-server php libapache2-mod-php php-mysql php-xml php-libvirt-php python  &> /dev/null
    gpasswd -d www-data libvirt &> /dev/null
    rm -fR /var/www/html/vmdashboard  &> /dev/null
    echo ""
    printHeaderMessage "Apt Cleanup" ${RED_TEXT}
    echo "apt-get -y autoremove"
    apt-get -y autoremove &> /dev/null
    echo  ""
    ;;
 esac


printHeaderMessage "Cleanup temp install files" ${RED_TEXT}
#####################
if [ -z ${TEMP_DIR} ]
then
  echo "TEMP_DIR was not set, unable to delete temp command files."
else
  echo   "Remove temp files:"
  echo   "rm -fR ${TEMP_DIR}"
  rm -fR ${TEMP_DIR}
fi
echo "${RESET_TEXT}"
echo ""

echo "##########################################################################################################"
SCRIPT_END_TIME=`date`
echo "End Time: ${SCRIPT_END_TIME}"
if (( $SECONDS > 3600 )) ; then
    let "hours=SECONDS/3600"
    let "minutes=(SECONDS%3600)/60"
    let "seconds=(SECONDS%3600)%60"
    echo "OpenShift Cleanup Completed in $hours hour(s), $minutes minute(s) and $seconds second(s)"
elif (( $SECONDS > 60 )) ; then
    let "minutes=(SECONDS%3600)/60"
    let "seconds=(SECONDS%3600)%60"
    echo "OpenShift Cleanup Completed in $minutes minute(s) and $seconds second(s)"
else
    echo "OpenShift Cleanup Completed in $SECONDS seconds"
fi
echo "##########################################################################################################"
echo ""
echo ""
