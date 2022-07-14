#!/bin/bash
############################################################
#Author           : Kyle Dawson
#Author email     : Kyle.Dawson@us.ibm.com
#Original Date    : 2021-09-25
#Initial Version  : v2021-12-01
############################################################
#https://docs.openshift.com/container-platform/4.8/installing/installing_gcp/installing-gcp-account.html
#https://docs.openshift.com/container-platform/4.6/installing/installing_gcp/installing-gcp-private.html
saveGCPCredentials()
{
  if [ ! -f  ~/.gcp/osServiceAccount.json ]; then
      mkdir -p ~/.gcp
      echo "${RED_TEXT}Missing GCP ~/.gcp/osServiceAccount.json${RESET_TEXT}"
      echo "Please copy your GCP Service account JSON Identity file here :"
      echo "~/.gcp/osServiceAccount.json"
      echo "Once you add the new file, please try again."
      echo ""
      echo ""
      echo "Exiting Script!!!!!!!"
      exit 9
  fi
}

gcpInstallGCloud()
{   #https://cloud.google.com/sdk/docs/install
    printHeaderMessage "Install gcloud command line tool (LOG -> ${LOG_DIR}/gloud-install.log )"
    FOUND_GCLOUD_COMMAND=`which gcloud 2>/dev/null | grep -c "gcloud"`
    if [ ${FOUND_GCLOUD_COMMAND} == 0 ] && [ ${IS_UBUNTU} == 1 ];then
      echo "Missing gcloud command, installing now."
      apt-get install apt-transport-https ca-certificates gnupg &> ${LOG_DIR}/gloud-install.log
      echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
      curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - >> ${LOG_DIR}/gloud-install.log
      echo "apt-get update && apt-get install google-cloud-sdk"
      apt-get update && apt-get install google-cloud-sdk >> ${LOG_DIR}/gloud-install.log
    elif [ ${FOUND_GCLOUD_COMMAND} == 0 ] && [ ${IS_RH} == 1 ];then
      echo "Missing gcloud command, installing now"
      cp ${DATA_DIR}/${PROJECT_NAME}/${PRODUCT_SHORT_NAME}/templates/providers/gcp/google-cloud-sdk.repo /etc/yum.repos.d/
      yum install -y google-cloud-cli &> ${LOG_DIR}/gloud-install.log
    else
      echo "${BLUE_TEXT}PASSED ${RESET_TEXT} gcloud command line tool already installed."
    fi
    FOUND_GCLOUD_COMMAND=`which gcloud 2>/dev/null | grep -c "gcloud"`
    if [ ${FOUND_GCLOUD_COMMAND} == 0 ] ;then
          echo "${RED_TEXT}FAILED: Unable to install gcloud tool.${RESET_TEXT}"
          echo "${RED_TEXT}Unable to continue, exit process now!!!!!!!!${RESET_TEXT}"
          echo ""
          echo "Exiting Script!!!!!!!"
          exit 9
    fi
    saveGCPCredentials
    USER_HOME_DIR=`eval echo "~"`
    gcloud auth activate-service-account --key-file=${USER_HOME_DIR}/.gcp/osServiceAccount.json
    echo "Setting Google Project to ${GCP_PROJECT_ID}"
    gcloud config set project ${GCP_PROJECT_ID} &> /dev/null
    echo ""
}

gcpServiceEnabled()
{
    GCP_SERVICE_NAME=$1
    GCP_SERVICE_LOG=$2
    GCP_API_ENABLED_GCP_SERVICE_NAME=`cat ${GCP_SERVICE_LOG} | grep -c "${GCP_SERVICE_NAME}"`
    if [ ${GCP_API_ENABLED_GCP_SERVICE_NAME} == "0" ]; then
        if [ "${GCP_API_ENABLE_MISSING_SERVICE}" == "true" ]; then
            echo "${BLUE_TEXT}Enabling API Service now: ${GCP_SERVICE_NAME}.${RESET_TEXT}"
            GCP_API_ENABLED_GCP_SERVICE_SUCESS=`gcloud services enable ${GCP_SERVICE_NAME} 2>&1  | grep -c "successfully"`
            if [[ "${GCP_API_ENABLED_GCP_SERVICE_SUCESS}" !=  "1" ]]; then
              echo "${RED_TEXT}Service can not be enabled: ${GCP_SERVICE_NAME}${RESET_TEXT}"
              SHOULD_EXIT=1
            fi
        else
            echo "${RED_TEXT}Service is not enabled: ${GCP_SERVICE_NAME}${RESET_TEXT}"
            SHOULD_EXIT=1
        fi
    else
        echo "Service is enabled: ${GCP_SERVICE_NAME}"
    fi
}
gcpValidateDNSZone()
{
  if [[ "${CURRENT_SCRIPT_NAME}" == *build.sh ]]; then
      printHeaderMessage "Validate GCP DNS Zone"
      GCP_VALID_ZONE=`gcloud dns managed-zones list --filter="visibility=public" | grep -c ${BASE_DOMAIN}`
      if [[ ${GCP_VALID_ZONE} -ge 1 ]]; then
         echo "${BLUE_TEXT}PASSED ${RESET_TEXT} ${BASE_DOMAIN} is existing DNS Zone in Project(${GCP_PROJECT_ID})"
      else
         echo "${RED_TEXT}FAILED: ${BASE_DOMAIN} NO existing DNS Zone in Project(${GCP_PROJECT_ID}) and unable to create new one."
         echo "${RESET_TEXT}"
         SHOULD_EXIT=1
      fi
      GCP_DNS_ZONE=`gcloud dns managed-zones list --filter="visibility=public" | grep "${BASE_DOMAIN}" | awk '{print $1}' `
      GCP_NS_NAME_LIST=`gcloud dns managed-zones describe ${GCP_DNS_ZONE} | grep googledomains.com |  awk '{print $2}'`
      GCP_NS_COUT=0
      for GCP_NS_NAME in $GCP_NS_NAME_LIST
      do
          FOUND_GCP_NS=`dig ${BASE_DOMAIN} NS | grep NS | grep -c ${GCP_NS_NAME}`
          if [ "${FOUND_GCP_NS}"  == "1" ]; then
            let "GCP_NS_COUT=${GCP_NS_COUT}+1"
          fi
      done
      if [ ${GCP_NS_COUT} -ne 4 ]; then
        echo "${RED_TEXT}FAILED: ${BASE_DOMAIN} is NOT pointing to the correct Google NS Servers."
        echo "DNS Zone required NS should be :"
        echo "${GCP_NS_NAME_LIST}"
        echo "Actual DNS NS :"
        dig ${BASE_DOMAIN} NS | grep NS |  grep -v ";" | awk '{print $5}'
        echo "${RESET_TEXT}"
        SHOULD_EXIT=1
      else
         echo "${BLUE_TEXT}PASSED ${RESET_TEXT} ${BASE_DOMAIN} is pointing to the correct Google NS Servers."
      fi
      echo ""
  fi
}
gcpValidateAPIServicesRequired()
{
      printHeaderMessage "Validate GCP API Services Enabled (LOG -> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/gcp.services.log )"
      gcloud services list > ${LOG_DIR}/${PRODUCT_SHORT_NAME}/gcp.services.log
      gcpServiceEnabled "iam.googleapis.com" ${LOG_DIR}/${PRODUCT_SHORT_NAME}/gcp.services.log
      gcpServiceEnabled "deploymentmanager.googleapis.com" ${LOG_DIR}/${PRODUCT_SHORT_NAME}/gcp.services.log
      gcpServiceEnabled "compute.googleapis.com" ${LOG_DIR}/${PRODUCT_SHORT_NAME}/gcp.services.log
      gcpServiceEnabled "cloudapis.googleapis.com" ${LOG_DIR}/${PRODUCT_SHORT_NAME}/gcp.services.log
      gcpServiceEnabled "cloudresourcemanager.googleapis.com" ${LOG_DIR}/${PRODUCT_SHORT_NAME}/gcp.services.log
      gcpServiceEnabled "dns.googleapis.com" ${LOG_DIR}/${PRODUCT_SHORT_NAME}/gcp.services.log
      gcpServiceEnabled "iamcredentials.googleapis.com" ${LOG_DIR}/${PRODUCT_SHORT_NAME}/gcp.services.log
      gcpServiceEnabled "servicemanagement.googleapis.com" ${LOG_DIR}/${PRODUCT_SHORT_NAME}/gcp.services.log
      gcpServiceEnabled "serviceusage.googleapis.com" ${LOG_DIR}/${PRODUCT_SHORT_NAME}/gcp.services.log
      gcpServiceEnabled "storage-api.googleapis.com" ${LOG_DIR}/${PRODUCT_SHORT_NAME}/gcp.services.log
      gcpServiceEnabled "storage-component.googleapis.com" ${LOG_DIR}/${PRODUCT_SHORT_NAME}/gcp.services.log
      gcpServiceEnabled "networksecurity.googleapis.com" ${LOG_DIR}/${PRODUCT_SHORT_NAME}/gcp.services.log
      echo ""
}

gcpValidateConstraintsRequired()
{
  printHeaderMessage "Validate GCP Constraints"
  echo "Not Implemented yet!!!!!!!!!!!!"
  #Not sure I need this, not documnted on OpenShift Doc site
  #constraints/compute.vmExternalIpAccess
  #constraints/compute.restrictLoadBalancerCreationForTypes
  echo ""

}
gcpValidateSingleRole()
{
   local GCP_ROLE=$1 #roles/compute.admin
   local GPC_ROLE_FILE=$2 #${LOG_DIR}/${PRODUCT_SHORT_NAME}/gcp-currentRoles.log
   local GCP_FOUND_MEMBER_IN_POLICY="false"
   GCPGCP_FOUND_MEMBER_IN_POLICY_AVAIL=`cat ${GPC_ROLE_FILE} | grep -c "roles/${GCP_ROLE}$"`
   if [[ ${GCPGCP_FOUND_MEMBER_IN_POLICY_AVAIL} == "0" ]]; then
      SHOULD_EXIT=1
      echo "${RED_TEXT}FAILED: Required Role ${GCP_ROLE} not found.${RESET_TEXT}"
   else
       echo "${BLUE_TEXT}PASSED ${RESET_TEXT} Required Role found ${GCP_ROLE}."
   fi

}
gcpValidateRolesRequired()
{
  printHeaderMessage "Validate GCP Roles (LOG -> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/gcp-currentRoles.log)"
  GCP_CLIENT_EMAIL=`cat ~/.gcp/osServiceAccount.json | grep client_email | awk '{print $2}' | sed "s/,//g" |  sed "s/\"//g"`
  gcloud projects get-iam-policy ${GCP_PROJECT_ID} \
    --flatten="bindings[].members" \
    --format="table(bindings.role)" \
    --filter="bindings.members:${GCP_CLIENT_EMAIL}" &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/gcp-currentRoles.log
  gcpValidateSingleRole "compute.admin" ${LOG_DIR}/${PRODUCT_SHORT_NAME}/gcp-currentRoles.log
  gcpValidateSingleRole "iam.securityAdmin" ${LOG_DIR}/${PRODUCT_SHORT_NAME}/gcp-currentRoles.log
  gcpValidateSingleRole "iam.serviceAccountAdmin" ${LOG_DIR}/${PRODUCT_SHORT_NAME}/gcp-currentRoles.log
  gcpValidateSingleRole "iam.serviceAccountUser" ${LOG_DIR}/${PRODUCT_SHORT_NAME}/gcp-currentRoles.log
  gcpValidateSingleRole "iam.serviceAccountKeyAdmin" ${LOG_DIR}/${PRODUCT_SHORT_NAME}/gcp-currentRoles.log
  gcpValidateSingleRole "storage.admin" ${LOG_DIR}/${PRODUCT_SHORT_NAME}/gcp-currentRoles.log
  gcpValidateSingleRole "dns.admin" ${LOG_DIR}/${PRODUCT_SHORT_NAME}/gcp-currentRoles.log
  echo ""

}
gcpGetAvailableQuota()
{
  GCP_METRIC_NAME=$1 #CPUS_ALL_REGIONS
  GCP_QUOTA_NEEDED=$2
  GCP_PROJECT_QUOTA_LOG=$3

  GCP_METRIC_LINE=`awk "/${GCP_METRIC_NAME}/{ print NR; exit }"  ${GCP_PROJECT_QUOTA_LOG}`
  let GCP_LIMIT_LINE=GCP_METRIC_LINE-1
  GCP_LIMIT=`head -n ${GCP_LIMIT_LINE} ${GCP_PROJECT_QUOTA_LOG} | tail -1 | awk '{print $3}' | sed "s/\.0//g"`
  let GCP_USAGE_LINE=GCP_METRIC_LINE+1
  GCP_USAGE=`head -n ${GCP_USAGE_LINE} ${GCP_PROJECT_QUOTA_LOG} | tail -1 | awk '{print $2}' | sed "s/\.0//g"`
  let GCP_AVAIL=GCP_LIMIT-GCP_USAGE
  let GCP_NET_USE=GCP_AVAIL-GCP_QUOTA_NEEDED
  if [[ ${GCP_AVAIL} -le ${GCP_QUOTA_NEEDED} ]]; then
     SHOULD_EXIT=1
     echo "${RED_TEXT}FAILED: Quota requirements for ${GCP_METRIC_NAME} - Shortage: ${GCP_NET_USE}${RESET_TEXT}"
  else
      echo "${BLUE_TEXT}PASSED ${RESET_TEXT} Quota requirements for ${GCP_METRIC_NAME}(Need ${GCP_QUOTA_NEEDED}) - Post Deployment Available: ${GCP_NET_USE}"
  fi

}

gcpValidateQuota()
{
  printHeaderMessage "Validate GCP Quota (LOG -> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/gcp.quota.log)"
  if [[ -z "${GCP_REGION}" ]]; then
      echo "${RED_TEXT}Unable to get quota without GCP_REGION variable. ${RESET_TEXT}"
  else
      gcloud compute regions describe ${GCP_REGION} --project ${GCP_PROJECT_ID} > ${LOG_DIR}/${PRODUCT_SHORT_NAME}/gcp.quota.log
      gcpGetAvailableQuota "CPUS" ${GCP_MACHINE_TYPE_CPU_TOTAL} ${LOG_DIR}/${PRODUCT_SHORT_NAME}/gcp.quota.log
      gcpGetAvailableQuota "DISKS_TOTAL_GB" ${GCP_STORGE_TOTAL} ${LOG_DIR}/${PRODUCT_SHORT_NAME}/gcp.quota.log
  fi
  echo ""
}
gpcAddOpenShiftContainerStorageDisk()
{
  printHeaderMessage "Create new Disk for OpenShift Container Storage to VM"
  NODE_LIST=`oc get nodes | grep worker | awk '{print $1}'`
  local workerLoop=1
  for GCP_WORKER_NODE_NAME in $NODE_LIST
  do
       local WORKER_ZONE=`gcloud compute instances list | grep ${GCP_WORKER_NODE_NAME} | awk '{print $2}'`
       echo "Creating new disk - ${GCP_WORKER_NODE_NAME}-${IBM_OPENSHIFT_LOCAL_STORAGE_DEVICE_DISK2_NAME}  --size ${VM_WORKER_DISK2} --type=${GCP_WORKER_DISK2_TYPE}"
       gcloud compute disks create ${GCP_WORKER_NODE_NAME}-${IBM_OPENSHIFT_LOCAL_STORAGE_DEVICE_DISK2_NAME}  --size ${VM_WORKER_DISK2} --zone=${WORKER_ZONE} --type=${GCP_WORKER_DISK2_TYPE} >>  ${LOG_DIR}/gcp.disk1.log 2>&1
       echo "Attaching new disk to VM ${GCP_WORKER_NODE_NAME}"
       gcloud compute instances attach-disk ${GCP_WORKER_NODE_NAME} --disk ${GCP_WORKER_NODE_NAME}-${IBM_OPENSHIFT_LOCAL_STORAGE_DEVICE_DISK2_NAME} --zone=${WORKER_ZONE} >> ${LOG_DIR}/gcp.disk1.log 2>&1

       echo "Creating new disk - ${GCP_WORKER_NODE_NAME}-${IBM_OPENSHIFT_LOCAL_STORAGE_DEVICE_DISK3_NAME} --size ${VM_WORKER_DISK3} --type=${GCP_WORKER_DISK3_TYPE}"
       gcloud compute disks create ${GCP_WORKER_NODE_NAME}-${IBM_OPENSHIFT_LOCAL_STORAGE_DEVICE_DISK3_NAME} --size ${VM_WORKER_DISK3} --zone=${WORKER_ZONE} --type=${GCP_WORKER_DISK3_TYPE} >> ${LOG_DIR}/gcp.disk2.log 2>&1
       echo "Attaching new disk to VM ${GCP_WORKER_NODE_NAME}"
       gcloud compute instances attach-disk ${GCP_WORKER_NODE_NAME} --disk ${GCP_WORKER_NODE_NAME}-${IBM_OPENSHIFT_LOCAL_STORAGE_DEVICE_DISK3_NAME} --zone=${WORKER_ZONE} >> ${LOG_DIR}/gcp.disk2.log 2>&1
       case ${workerLoop} in
           1)
              OPEN_SHIFT_CONTAINTER_STORAGE_WORKER_NODE1=${GCP_WORKER_NODE_NAME}
              ;;
           2)
              OPEN_SHIFT_CONTAINTER_STORAGE_WORKER_NODE2=${GCP_WORKER_NODE_NAME}
              ;;
           3)
              OPEN_SHIFT_CONTAINTER_STORAGE_WORKER_NODE3=${GCP_WORKER_NODE_NAME}
              ;;
       esac
       let workerLoop=workerLoop+1
       if [ $workerLoop -gt 3 ]; then
         #only add disk to first three nodes.
         break
       fi

  done

}
updateGCPInstallConfig()
{
  GCP_VM_WORKER_DISK1=`echo ${VM_WORKER_DISK1} |  sed  "s/\([a-zA-Z]\)$//"`
  sed -i'' "s/@GCP_VM_WORKER_DISK1@/${GCP_VM_WORKER_DISK1}/" ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/providers/gcp/install-config.yaml
  GCP_VM_MASTER_DISK1=`echo ${VM_MASTER_DISK1} |  sed  "s/\([a-zA-Z]\)$//"`
  sed -i'' "s/@GCP_VM_MASTER_DISK1@/${GCP_VM_MASTER_DISK1}/" ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/providers/gcp/install-config.yaml
}
