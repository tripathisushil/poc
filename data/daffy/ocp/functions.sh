#!/bin/bash
############################################################
#Author           : Kyle Dawson
#Author email     : Kyle.Dawson@us.ibm.com
#Original Date    : 2021-08-15
#Initial Version  : v2021-12-01
############################################################

preChecksOCP()
{
  #PreTest Check for required files
  ########################
  SHOULD_EXIT=0
  defineVMTShirtSize
  printHeaderMessage "Prechecks"
  prepareHost
  echo ""
  resourcePresent ${DIR}/templates/matchbox/profiles/bootstrap.json
  resourcePresent ${DIR}/templates/matchbox/profiles/worker.json
  resourcePresent ${DIR}/templates/matchbox/profiles/master.json
  resourcePresent ${DIR}/templates/matchbox/groups/bootstrap.json
  resourcePresent ${DIR}/templates/matchbox/groups/master1.json
  resourcePresent ${DIR}/templates/matchbox/groups/master2.json
  resourcePresent ${DIR}/templates/matchbox/groups/master3.json
  resourcePresent ${DIR}/templates/matchbox/groups/worker1.json
  resourcePresent ${DIR}/templates/matchbox/groups/worker2.json
  resourcePresent ${DIR}/templates/matchbox/groups/worker3.json
  resourcePresent ${DIR}/templates/matchbox/groups/worker4.json
  resourcePresent ${DIR}/templates/matchbox/groups/worker5.json
  resourcePresent ${DIR}/templates/matchbox/groups/worker6.json
  resourcePresent ${DIR}/templates/matchbox/groups/worker6.json
  resourcePresent ${DIR}/templates/image-registry/persistentvolumeclaim.yaml
  resourcePresent ${DIR}/templates/nfs/class.yaml
  resourcePresent ${DIR}/templates/nfs/deployment.yaml
  resourcePresent ${DIR}/templates/nfs/rbac.yaml
  resourcePresent ${DIR}/templates/storage/Large/local-bulk.yaml
  resourcePresent ${DIR}/templates/storage/Large/local.yaml
  resourcePresent ${DIR}/templates/storage/operator-container-storage-cluster.yaml
  resourcePresent ${DIR}/templates/operators/openshift-container-storage/operatorgroup.yaml
  resourcePresent ${DIR}/templates/operators/openshift-container-storage/subscription.yaml
  resourcePresent ${DIR}/templates/operators/openshift-local-storage/operatorgroup.yaml
  resourcePresent ${DIR}/templates/operators/openshift-local-storage/subscription.yaml
  resourcePresent ${DIR}/templates/dnsmasq/Min/cluster.conf
  resourcePresent ${DIR}/templates/haproxy/Min/haproxy.cfg
  resourcePresent ${DIR}/templates/dnsmasq/Large/cluster.conf
  resourcePresent ${DIR}/templates/haproxy/Large/haproxy.cfg
  resourcePresent ${DIR}/templates/dnsmasq/dnsmasq.conf
  resourcePresent ${DIR}/templates/dnsmasq/daffy.dnsmasq.sh
  resourcePresent ${DIR}/templates/install-config.yaml
  resourcePresent ${DIR}/templates/providers/aws/install-config.yaml
  resourcePresent ${DIR}/templates/providers/aws/credentials
  resourcePresent ${DIR}/templates/providers/vsphere/install-config.yaml
  resourcePresent ${DIR}/templates/providers/vsphere/install-config.yaml
  resourcePresent ${DIR}/templates/providers/azure/install-config.yaml
  resourcePresent ${DIR}/templates/providers/azure/osServicePrincipal.json
  #resourcePresent ${DIR}/templates/providers/azure/azure-cli.repo
  resourcePresent ${DIR}/templates/providers/gcp/install-config.yaml
  #resourcePresent ${DIR}/templates/providers/gcp/google-cloud-sdk.repo
  resourcePresent ${DIR}/templates/coreos-installer/install-bootstrap.sh
  resourcePresent ${DIR}/templates/coreos-installer/install-master.sh
  resourcePresent ${DIR}/templates/coreos-installer/install-worker.sh
  resourcePresent ${DIR}/templates/virsh/net_ocp.xml
  if [[ "${CURRENT_SCRIPT_NAME}" == *build.sh ]];then
      getPullSecretviaAPI
      getPullSecret
      variablePresent ${PULL_SECRET} "PULL_SECRET"
      validPullSecret ${PULL_SECRET}
      getCustomOpenShiftInstaller
  fi
  baseValidation
  validOCPVersion
  printHeaderMessage "Validate Install Type Settings"
  case ${OCP_INSTALL_TYPE} in
    kvm-upi)
        precheckDNSBuild
        if [ "${IS_RH}" == "1"  ]; then
          echo "${RED_TEXT}FAILED ${RESET_TEXT} Unsupported bastion OS for ${OCP_INSTALL_TYPE}. Only Ubuntu is supported"
          echo "Exiting Script!!!!!!!"
          exit 99
        fi
        variablePresent ${OCP_INSTALL_GATEWAY} OCP_INSTALL_GATEWAY
        variablePresent ${OCP_KUBECONFIG_DIR} OCP_KUBECONFIG_DIR
        variablePresent ${OCP_INSTALLBOOTSTRAP_IP} OCP_INSTALLBOOTSTRAP_IP
        variablePresent ${OCP_INSTALL_MASTER1_IP} OCP_INSTALL_MASTER1_IP
        variablePresent ${OCP_INSTALL_MASTER2_IP} OCP_INSTALL_MASTER2_IP
        variablePresent ${OCP_INSTALL_MASTER3_IP} OCP_INSTALL_MASTER3_IP
        if [ "${VM_BUILD_WORKERS_NODES}" == "true" ]  ;then
            variablePresent ${OCP_INSTALL_WORKER1_IP} OCP_INSTALL_WORKER1_IP
            variablePresent ${OCP_INSTALL_WORKER2_IP} OCP_INSTALL_WORKER2_IP
            variablePresent ${OCP_INSTALL_WORKER3_IP} OCP_INSTALL_WORKER3_IP
            if [ "${VM_TSHIRT_SIZE}" == "Large" ] ;then
                variablePresent ${OCP_INSTALL_WORKER4_IP} OCP_INSTALL_WORKER4_IP
                variablePresent ${OCP_INSTALL_WORKER5_IP} OCP_INSTALL_WORKER5_IP
                variablePresent ${OCP_INSTALL_WORKER6_IP} OCP_INSTALL_WORKER6_IP
            fi
        fi
        variablePresent ${VM_IMAGE_ROOT_PATH} VM_IMAGE_ROOT_PATH
        variablePresent ${VM_VOL_STORAGE_POOL} VM_VOL_STORAGE_POOL
        variablePresent ${OCP_INSTALL_DHCP_RANGE_START} OCP_INSTALL_DHCP_RANGE_START
        variablePresent ${OCP_INSTALL_DHCP_RANGE_STOP} OCP_INSTALL_DHCP_RANGE_STOP
        apachePortsReassignment
        if [[ "${CURRENT_SCRIPT_NAME}" == *build.sh ]];then
           if [ "${HAPROXY_BUILD}" == "true"  ];then
              localPortInuse 443
              localPortInuse 22623
              localPortInuse 6443
           fi
              localPortInuse 80
              echo ""
              printHeaderMessage "KVM Hardware Validation"
              kvmCheckDiskSpaceAvailable
              kvmCheckCPUAvailable
              kvmCheckMemoryAvailable
              kvmValidateBastionIP
              if [ ${VM_NUMBER_OF_WORKERS_LARGE} -gt 9 ]; then
                echo "${RED_TEXT}FAILED  ${RESET_TEXT}KVM Large worker must be less then or equal to 9"
                echo "${RED_TEXT}FAILED  ${RESET_TEXT}VM_NUMBER_OF_WORKERS_LARGE=${VM_NUMBER_OF_WORKERS_LARGE}"
                SHOULD_EXIT=1
              fi
        fi
        ;;
    vsphere-upi)
        precheckDNSBuild
        variablePresent ${VSPHERE_HOSTNAME} VSPHERE_HOSTNAME
        getVSpherePassword
        variablePresent ${VSPHERE_PASSWORD} VSPHERE_PASSWORD
        variablePresent ${VSPHERE_USERNAME} VSPHERE_USERNAME
        variablePresent ${VSPHERE_DATASTORE} VSPHERE_DATASTORE
        variablePresent ${VSPHERE_NETWORK1} VSPHERE_NETWORK1
        variablePresent ${VSPHERE_FOLDER} VSPHERE_FOLDER
        variablePresent ${VSPHERE_DATACENTER} VSPHERE_DATACENTER
        variablePresent ${VSPHERE_RESOURCE_POOL} VSPHERE_RESOURCE_POOL
        variablePresent ${BASTION_HOST} BASTION_HOST
        variablePresent ${BASTION_USER} BASTION_USER
        getBastionPassword
        variablePresent ${BASTION_PASSWORD} BASTION_PASSWORD
        variablePresent ${OCP_INSTALL_DNS} OCP_INSTALL_DNS
        variablePresent ${OCP_NODE_SUBNET_MASK} OCP_NODE_SUBNET_MASK
        apachePortsReassignment
        if [ "${CURRENT_SCRIPT_NAME}" == *build.sh ];then
           if [ "${HAPROXY_BUILD}" == "true"  ];then

              localPortInuse 443
              localPortInuse 22623
              localPortInuse 6443
            fi
            localPortInuse 80
            localPortInuse 8080
            validateVSphereUPINodes
        fi
        ;;
    vsphere-ipi)
        variablePresent ${VSPHERE_HOSTNAME} VSPHERE_HOSTNAME
        getVSpherePassword
        variablePresent ${VSPHERE_PASSWORD} VSPHERE_PASSWORD
        variablePresent ${VSPHERE_USERNAME} VSPHERE_USERNAME
        variablePresent ${VSPHERE_DATASTORE} VSPHERE_DATASTORE
        variablePresent ${VSPHERE_NETWORK1} VSPHERE_NETWORK1
        variablePresent ${VSPHERE_FOLDER} VSPHERE_FOLDER
        variablePresent ${VSPHERE_DATACENTER} VSPHERE_DATACENTER
        variablePresent ${VSPHERE_RESOURCE_POOL} VSPHERE_RESOURCE_POOL
        variablePresent ${VSPHERE_CLUSTER} VSPHERE_CLUSTER
        variablePresent ${VSPHERE_API_VIP} VSPHERE_API_VIP
        validIPAddressNotInUse ${VSPHERE_API_VIP} VSPHERE_API_VIP
        variablePresent ${VSPHERE_INGRESS_VIP} VSPHERE_INGRESS_VIP
        validIPAddressNotInUse ${VSPHERE_INGRESS_VIP} VSPHERE_INGRESS_VIP
        ;;
    aws-ipi)
        variablePresent ${AWS_REGION} AWS_REGION
        variablePresent ${AWS_ACCESS_KEY_ID} AWS_ACCESS_KEY_ID
        saveAWSCredentials
        awsInstallCommandline
        awsAccountPermissions
        if [[ "${CURRENT_SCRIPT_NAME}" == *build.sh ]];then
          awsValidateQuota
          awsValidDNSHostedZone
          awsGetKMSKey
          awsCheckSubnets
        fi
        ;;
    azure-ipi)
        variablePresent ${AZURE_SUBSCRIPTION_ID} AZURE_SUBSCRIPTION_ID
        variablePresent ${AZURE_CLIENT_ID} AZURE_CLIENT_ID
        variablePresent ${AZURE_TENANT_ID} AZURE_TENANT_ID
        variablePresent ${AZURE_BASE_DOMAIN_RESOURCE_GROUP_NAME} AZURE_BASE_DOMAIN_RESOURCE_GROUP_NAME
        variablePresent ${AZURE_REGION} AZURE_REGION
        variablePresent ${AZURE_VCPU_QUOTA_NAME} AZURE_VCPU_QUOTA_NAME
        azInstallCommandline
        saveAzureCredentials
        azLogincli
        azValidateDNSZone
        azValidateAccessLevel
        azValidateQuota
        if [[ "${CURRENT_SCRIPT_NAME}" == *build.sh ]];then
          azValidateResourceGroup
        fi
        ;;
    gcp-ipi)
        if [[ "${CURRENT_SCRIPT_NAME}" == *build.sh ]];then
          variablePresent ${GCP_PROJECT_ID} GCP_PROJECT_ID
          variablePresent ${GCP_REGION} GCP_REGION
        fi
        gcpInstallGCloud
        gcpValidateAPIServicesRequired
        gcpValidateRolesRequired
        #gcpValidateConstraintsRequired
        gcpValidateDNSZone
        if [[ "${CURRENT_SCRIPT_NAME}" == *build.sh ]];then
          gcpValidateQuota
        fi
        ;;
    roks-msp)
        printHeaderMessage "Validate ROKS Settings (LOG ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ibm-*.log )"
        testIBMCloudLogin
        if [[ "${CURRENT_SCRIPT_NAME}" == *build.sh ]];then
          if [ "${ROKS_PROVIDER}" == "techzone" ]; then
              SHOULD_EXIT="1"
              echo "${RED_TEXT}FAILED  ${RESET_TEXT}ROKS_PROVIDER=techzone, you will not have IBM Account authority to build a cluster."
          else
            variablePresent ${ROKS_ZONE} ROKS_ZONE
            variablePresent ${ROKS_PROVIDER} ROKS_PROVIDER
            validateIBMVLANPrivatePublic
            validateIBMROKSFlavor
            validROKSHardwareType
            validROKSNumberOfWorkers
            validROKSProviders
            validROKSZone
            validROKSOCPVersion
            ibmCloudROKSClusterDoesNotExist
          fi
        fi
        ;;
    #rosa-msp)
            #variablePresent ${AWS_REGION} AWS_REGION
            #variablePresent ${AWS_ACCESS_KEY_ID} AWS_ACCESS_KEY_ID
            #saveAWSCredentials
            #getRHToken
            #awsInstallCommandline
            #ROSAInstallCommandline
            #ROSAAccountPermissions
        #if [[ "${CURRENT_SCRIPT_NAME}" == *build.sh ]];then
            #awsValidateQuota
            #verifyRosa
        #fi
        #;;
  esac

  echo ""
  if [ "${OCP_CREATE_NFS_STORAGE}" =  "true" ] ;then
       variablePresent ${BASTION_HOST} BASTION_HOST
       echo ""
  fi
  case  ${OCP_INSTALL_TYPE} in
    vsphere-*)
         createIBMCloudDNSEntries
         validHostName ${OCP_HOST_NAME}
         export GOVC_DATASTORE=${VSPHERE_DATASTORE}
         export GOVC_NETWORK=${VSPHERE_NETWORK}
         export GOVC_FOLDER=${VSPHERE_FOLDER}
         export GOVC_DATACENTER=${VSPHERE_DATACENTER}
         export GOVC_RESOURCE_POOL=${VSPHERE_RESOURCE_POOL}
         export GOVC_INSECURE=1
         export GOVC_USERNAME=${VSPHERE_USERNAME}
         export GOVC_PASSWORD=${VSPHERE_PASSWORD}
         export GOVC_URL="${VSPHERE_HOSTNAME}"
         approveVCenterCert
         installGOVC
         testVSphereAccess
         validateVSpherePermission
         if [ "${OCP_CREATE_OPENSHIFT_CONTAINER_STORAGE}" =  "true" ] ;then
             if [ -n "${VSPHERE_FAST_DISK_DATASTORE}" ]; then
                VMWareFastDiskDataStoreValid
             fi
         fi
         ;;
     vsphere-upi)
         if [[ "${CURRENT_SCRIPT_NAME}" == *build.sh ]];then
              VMWareCoreOSISOPresent
         fi
         ;;
     kvm-upi)
          createIBMCloudDNSEntries
          validHostName ${OCP_HOST_NAME}
          ;;
  esac
  if [[ "${CURRENT_SCRIPT_NAME}" == *build.sh ]];then
      if [ "${LOCAL_REGISTRY_ENABLED}" == "true"  ]; then
          getLocalRegistryAuth
          variablePresent  ${LOCAL_REGISTRY_AUTH_INFO} LOCAL_REGISTRY_AUTH_INFO
          resourcePresent ${LOCAL_REGISTRY_CERTS_FOLDER}/${LOCAL_REGISTRY_DNS_NAME}.crt
      fi
      if [ "${OCP_CREATE_OPENSHIFT_CONTAINER_STORAGE}" =  "true" ] ;then
          if [[ ${VM_TSHIRT_SIZE} !=  Large ]] ;then
             echo "${RED_TEXT}Failed OpenShift Container Storage Precheck${RESET_TEXT}"
             echo "${RED_TEXT}#######################################################################${RESET_TEXT}"
             echo "You specifity to create OpenShift Container storage (OCP_CREATE_OPENSHIFT_CONTAINER_STORAGE=${OCP_CREATE_OPENSHIFT_CONTAINER_STORAGE})"
             echo "But this only supports T-Shirt Size of Large with 6 worker nodes or more in cluster."
             echo "Your T-Shirt size is ${VM_TSHIRT_SIZE}"
             echo "Please correct before continuing"
             echo ""
             echo ""
             echo ""
             SHOULD_EXIT=1
          fi
          if [ ${OCP_INSTALL_TYPE} ==  "*-msp" ] ;then
             echo "${RED_TEXT}Failed OpenShift Container Storage Precheck${RESET_TEXT} "
             echo "${RED_TEXT}#######################################################################${RESET_TEXT}"
             echo "You specified to create OpenShift Container storage (OCP_CREATE_OPENSHIFT_CONTAINER_STORAGE=${OCP_CREATE_OPENSHIFT_CONTAINER_STORAGE})"
             echo "But this is not currently supported for ${OCP_INSTALL_TYPE} install type - OCP_INSTALL_TYPE=${OCP_INSTALL_TYPE}"
             echo "Please remove before continuing"
             echo ""
             echo ""
             echo ""
             SHOULD_EXIT=1
          fi
      fi
  fi
  if [ "${OCP_CREATE_OPENSHIFT_CONTAINER_STORAGE}" == true ];then
        OCP_IMAGE_REGISTRY_STORAGE_CLASS=ocs-storagecluster-cephfs
  fi
  shouldExit
  echo "All prechecks passed, lets get to work."
  echo ""

}
prepareOCPInputFiles()
{
  printHeaderMessage "Prepare Input Files"
  mkdir -p ${TEMP_DIR}/${PRODUCT_SHORT_NAME}
  cd ${TEMP_DIR}/${PRODUCT_SHORT_NAME}
  cp -fR ${DIR}/templates/* ${TEMP_DIR}/${PRODUCT_SHORT_NAME}
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s|@DATA_DIR@|$DATA_DIR|g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s|@PROJECT_NAME@|$PROJECT_NAME|g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@OCP_HOST_NAME@/$OCP_HOST_NAME/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@BASE_DOMAIN@/$BASE_DOMAIN/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@CLUSTER_NAME@/$CLUSTER_NAME/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@BASTION_HOST@/$BASTION_HOST/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@OCP_BASE_VERSION@/$OCP_BASE_VERSION/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@OCP_FIPS@/$OCP_FIPS/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@OCP_INSTALL_DHCP_RANGE_START@/$OCP_INSTALL_DHCP_RANGE_START/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@OCP_INSTALL_DHCP_RANGE_STOP@/$OCP_INSTALL_DHCP_RANGE_STOP/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@OCP_INSTALL_GATEWAY@/$OCP_INSTALL_GATEWAY/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@OCP_INSTALL_DNS@/$OCP_INSTALL_DNS/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@OCP_FORWARD_DNS@/$OCP_FORWARD_DNS/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@ORIGINAL_DNS_SERVERS@/$ORIGINAL_DNS_SERVERS/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s|@NFS_FILE_SYSTEM@|$NFS_FILE_SYSTEM|g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@OCP_INSTALLBOOTSTRAP_IP@/$OCP_INSTALLBOOTSTRAP_IP/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@OCP_INSTALL_MASTER1_IP@/$OCP_INSTALL_MASTER1_IP/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@OCP_INSTALL_MASTER2_IP@/$OCP_INSTALL_MASTER2_IP/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@OCP_INSTALL_MASTER3_IP@/$OCP_INSTALL_MASTER3_IP/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@OCP_INSTALL_WORKER1_IP@/$OCP_INSTALL_WORKER1_IP/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@OCP_INSTALL_WORKER2_IP@/$OCP_INSTALL_WORKER2_IP/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@OCP_INSTALL_WORKER3_IP@/$OCP_INSTALL_WORKER3_IP/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@OCP_INSTALL_WORKER4_IP@/$OCP_INSTALL_WORKER4_IP/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@OCP_INSTALL_WORKER5_IP@/$OCP_INSTALL_WORKER5_IP/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@OCP_INSTALL_WORKER6_IP@/$OCP_INSTALL_WORKER6_IP/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@OCP_INSTALL_WORKER7_IP@/$OCP_INSTALL_WORKER7_IP/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@OCP_INSTALL_WORKER8_IP@/$OCP_INSTALL_WORKER8_IP/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@OCP_INSTALL_WORKER9_IP@/$OCP_INSTALL_WORKER9_IP/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@VM_BOOTSTRAP_VCPU@/$VM_BOOTSTRAP_VCPU/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@VM_BOOTSTRAP_RAM@/$VM_BOOTSTRAP_RAM/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@VM_BOOTSTRAP_DISK1@/$VM_BOOTSTRAP_DISK1/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@VM_MASTER_VCPU@/$VM_MASTER_VCPU/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@VM_MASTER_RAM@/$VM_MASTER_RAM/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@VM_MASTER_DISK1@/$VM_MASTER_DISK1/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@VM_WORKER_VCPU@/$VM_WORKER_VCPU/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@VM_WORKER_RAM@/$VM_WORKER_RAM/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@VM_NUMBER_OF_IMAGES@/$VM_NUMBER_OF_IMAGES/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@VM_WORKER_DISK1@/$VM_WORKER_DISK1/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@VM_WORKER_DISK2@/$VM_WORKER_DISK2/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@VM_WORKER_DISK3@/$VM_WORKER_DISK3/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@VM_NUMBER_OF_MASTERS@/$VM_NUMBER_OF_MASTERS/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@VM_NUMBER_OF_WORKERS@/$VM_NUMBER_OF_WORKERS/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@OPEN_SHIFT_CONTAINTER_STORAGE_WORKER_NODE1@/$OPEN_SHIFT_CONTAINTER_STORAGE_WORKER_NODE1/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@OPEN_SHIFT_CONTAINTER_STORAGE_WORKER_NODE2@/$OPEN_SHIFT_CONTAINTER_STORAGE_WORKER_NODE2/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@OPEN_SHIFT_CONTAINTER_STORAGE_WORKER_NODE3@/$OPEN_SHIFT_CONTAINTER_STORAGE_WORKER_NODE3/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@LOCAL_REGISTRY_DNS_NAME@/$LOCAL_REGISTRY_DNS_NAME/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@LOCAL_REGISTRY_PORT@/$LOCAL_REGISTRY_PORT/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@OCS_OPERATOR_VERSION@/$OCS_OPERATOR_VERSION/g"

  #NFS
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s|@OCP_NFS_IMAGE@|$OCP_NFS_IMAGE|g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s|@OCP_NFS_ENV_PROVISIONER_NAME@|$OCP_NFS_ENV_PROVISIONER_NAME|g"

  #Image Registry
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@OCP_IMAGE_REGISTRY_STORAGE_CLASS@/$OCP_IMAGE_REGISTRY_STORAGE_CLASS/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@OCP_IMAGE_REGISTRY_STORAGE_SIZE@/$OCP_IMAGE_REGISTRY_STORAGE_SIZE/g"

  #Proxy
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s|@OCP_PROXY_HTTP_PROXY@|$OCP_PROXY_HTTP_PROXY|g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s|@OCP_PROXY_HTTPS_PROXY@|$OCP_PROXY_HTTPS_PROXY|g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s|@OCP_PROXY_NO_PROXY@|$OCP_PROXY_NO_PROXY|g"
  local SKIP_PROXY=0
  if [ -z "${OCP_PROXY_HTTP_PROXY}"  ]; then
    find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/httpProxy.*//g"
    let SKIP_PROXY=SKIP_PROXY+1
  else
    echo "${BLUE_TEXT}INFO ${RESET_TEXT} Adding HTTP Proxy - ${OCP_PROXY_HTTP_PROXY}"
  fi
  if [ -z "${OCP_PROXY_HTTPS_PROXY}"  ]; then
    find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/httpsProxy.*//g"
    let SKIP_PROXY=SKIP_PROXY+1
  else
    echo "${BLUE_TEXT}INFO ${RESET_TEXT} Adding HTTPS Proxy - ${OCP_PROXY_HTTPS_PROXY}"
  fi
  if [ -z "${OCP_PROXY_NO_PROXY}"  ]; then
    find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/noProxy.*//g"
  else
    echo "${BLUE_TEXT}INFO ${RESET_TEXT} Adding NO Proxy - ${OCP_PROXY_NO_PROXY}"
  fi
  if [ ${SKIP_PROXY} -eq 2 ]; then
    find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/noProxy.*//g"
    find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/proxy.*//g"
  fi

  setClusterPTRRecordFromIP
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@OCP_INSTALL_BOOTSTRAP_PTR_RECORD@/$OCP_INSTALL_BOOTSTRAP_PTR_RECORD/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@OCP_INSTALL_MASTER1_PTR_RECORD@/$OCP_INSTALL_MASTER1_PTR_RECORD/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@OCP_INSTALL_MASTER2_PTR_RECORD@/$OCP_INSTALL_MASTER2_PTR_RECORD/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@OCP_INSTALL_MASTER3_PTR_RECORD@/$OCP_INSTALL_MASTER3_PTR_RECORD/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@OCP_INSTALL_WORKER1_PTR_RECORD@/$OCP_INSTALL_WORKER1_PTR_RECORD/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@OCP_INSTALL_WORKER2_PTR_RECORD@/$OCP_INSTALL_WORKER2_PTR_RECORD/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@OCP_INSTALL_WORKER3_PTR_RECORD@/$OCP_INSTALL_WORKER3_PTR_RECORD/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@OCP_INSTALL_WORKER4_PTR_RECORD@/$OCP_INSTALL_WORKER4_PTR_RECORD/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@OCP_INSTALL_WORKER5_PTR_RECORD@/$OCP_INSTALL_WORKER5_PTR_RECORD/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@OCP_INSTALL_WORKER6_PTR_RECORD@/$OCP_INSTALL_WORKER6_PTR_RECORD/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@OCP_INSTALL_WORKER7_PTR_RECORD@/$OCP_INSTALL_WORKER7_PTR_RECORD/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@OCP_INSTALL_WORKER8_PTR_RECORD@/$OCP_INSTALL_WORKER8_PTR_RECORD/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@OCP_INSTALL_WORKER9_PTR_RECORD@/$OCP_INSTALL_WORKER9_PTR_RECORD/g"
  case ${OCP_INSTALL_TYPE} in
     kvm-upi)
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s|@IBM_OPENSHIFT_LOCAL_STORAGE_DEVICE_PATH@|$IBM_OPENSHIFT_LOCAL_STORAGE_DEVICE_PATH_KVM|g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s|@IBM_OPENSHIFT_LOCAL_BULK_STORAGE_DEVICE_PATH@|$IBM_OPENSHIFT_LOCAL_BULK_STORAGE_DEVICE_PATH_KVM|g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@OCP_OCS_STORAGE_CLASS_BLOCK@/$OCP_OCS_STORAGE_CLASS_BLOCK/g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@OCP_OCS_STORAGE_CLASS_FILE@/$OCP_OCS_STORAGE_CLASS_FILE/g"
        ;;
     azure-ipi)
         updateAzureInstallConfig
         find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s|@IBM_OPENSHIFT_LOCAL_STORAGE_DEVICE_PATH@|$IBM_OPENSHIFT_LOCAL_STORAGE_DEVICE_PATH_AZ|g"
         find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s|@IBM_OPENSHIFT_LOCAL_BULK_STORAGE_DEVICE_PATH@|$IBM_OPENSHIFT_LOCAL_BULK_STORAGE_DEVICE_PATH_AZ|g"
         find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@AZURE_MACHINE_TYPE_MASTER@/$AZURE_MACHINE_TYPE_MASTER/g"
         find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@AZURE_MACHINE_TYPE_WORKER@/$AZURE_MACHINE_TYPE_WORKER/g"
         find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@AZURE_SUBSCRIPTION_ID@/$AZURE_SUBSCRIPTION_ID/g"
         find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@AZURE_CLIENT_ID@/$AZURE_CLIENT_ID/g"
         find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@AZURE_TENANT_ID@/$AZURE_TENANT_ID/g"
         find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s|@AZURE_NETWORKING_CLUSTER_NETWORK_CIDR@|$AZURE_NETWORKING_CLUSTER_NETWORK_CIDR|g"
         find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@AZURE_NETWORKING_CLUSTER_NETWORK_HOST_PREFIX@/$AZURE_NETWORKING_CLUSTER_NETWORK_HOST_PREFIX/g"
         find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s|@AZURE_NETWORKING_MACHINE_NETWORK_CIDR@|$AZURE_NETWORKING_MACHINE_NETWORK_CIDR|g"
         find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s|@AZURE_NETWORKING_NETWORK_TYPE@|$AZURE_NETWORKING_NETWORK_TYPE|g"
         find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s|@AZURE_NETWORKING_SERVICE_NETWORK@|$AZURE_NETWORKING_SERVICE_NETWORK|g"
         find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@AZURE_BASE_DOMAIN_RESOURCE_GROUP_NAME@/$AZURE_BASE_DOMAIN_RESOURCE_GROUP_NAME/g"
         find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@AZURE_RESOURCE_GROUP_NAME@/$AZURE_RESOURCE_GROUP_NAME/g"
         find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@AZURE_OUTBOUND_TYPE@/$AZURE_OUTBOUND_TYPE/g"
         find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@AZURE_REGION@/$AZURE_REGION/g"
         find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@AZURE_ZONE@/$AZURE_ZONE/g"
         find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@AZURE_NETWORK_RESOURCE_GROUP_NAME@/$AZURE_NETWORK_RESOURCE_GROUP_NAME/g"
         find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@AZURE_VIRTUAL_NETWORK@/$AZURE_VIRTUAL_NETWORK/g"
         find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@AZURE_CONTROL_PLANE_SUBNET@/$AZURE_CONTROL_PLANE_SUBNET/g"
         find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@AZURE_COMPUTE_SUBNET@/$AZURE_COMPUTE_SUBNET/g"
         find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@AZURE_CLOUD_NAME@/$AZURE_CLOUD_NAME/g"
         find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@OCP_OCS_STORAGE_CLASS_BLOCK@/$AZURE_OCP_OCS_STORAGE_CLASS_BLOCK/g"
         find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@OCP_OCS_STORAGE_CLASS_FILE@/$AZURE_OCP_OCS_STORAGE_CLASS_FILE/g"
         find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s|@AZURE_INSTALL_PUBLISH@|$AZURE_INSTALL_PUBLISH|g"
         find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s|@AZURE_CREDENTIALS_MODE@|$AZURE_CREDENTIALS_MODE|g"
         ;;
     aws-ipi)
        awsApplySubnetValues
        awsApplyMasterAvailZonesValues
        awsApplyWorkerAvailZonesValues
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@AWS_REGION@/$AWS_REGION/g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@AWS_ACCESS_KEY_ID@/$AWS_ACCESS_KEY_ID/g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@AWS_USER_TAG_MAIN1@/$AWS_USER_TAG_MAIN1/g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@AWS_USER_TAG_MAIN2@/$AWS_USER_TAG_MAIN2/g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@AWS_DISK_VOLUME_IOPS@/$AWS_DISK_VOLUME_IOPS/g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@AWS_DISK_VOLUME_TYPE@/$AWS_DISK_VOLUME_TYPE/g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@AWS_AMI_ID@/$AWS_AMI_ID/g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@AWS_SUBNET1@/$AWS_SUBNET1/g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@AWS_SUBNET2@/$AWS_SUBNET2/g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@AWS_SUBNET3@/$AWS_SUBNET3/g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@AWS_SUBNET4@/$AWS_SUBNET4/g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@AWS_SUBNET5@/$AWS_SUBNET5/g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@AWS_SUBNET6@/$AWS_SUBNET6/g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@AWS_MACHINE_TYPE_MASTER_AVAIL_ZONE1@/$AWS_MACHINE_TYPE_MASTER_AVAIL_ZONE1/g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@AWS_MACHINE_TYPE_MASTER_AVAIL_ZONE2@/$AWS_MACHINE_TYPE_MASTER_AVAIL_ZONE2/g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@AWS_MACHINE_TYPE_MASTER_AVAIL_ZONE3@/$AWS_MACHINE_TYPE_MASTER_AVAIL_ZONE3/g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@AWS_MACHINE_TYPE_WORKER_AVAIL_ZONE1@/$AWS_MACHINE_TYPE_WORKER_AVAIL_ZONE1/g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@AWS_MACHINE_TYPE_WORKER_AVAIL_ZONE2@/$AWS_MACHINE_TYPE_WORKER_AVAIL_ZONE2/g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@AWS_MACHINE_TYPE_WORKER_AVAIL_ZONE3@/$AWS_MACHINE_TYPE_WORKER_AVAIL_ZONE3/g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@AWS_USER_TAG1@/$AWS_USER_TAG1/g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@AWS_USER_TAG2@/$AWS_USER_TAG2/g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@AWS_USER_TAG3@/$AWS_USER_TAG3/g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@AWS_USER_TAG4@/$AWS_USER_TAG4/g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@AWS_USER_TAG5@/$AWS_USER_TAG5/g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s|@AWS_NETWORKING_CLUSTER_NETWORK_CIDR@|$AWS_NETWORKING_CLUSTER_NETWORK_CIDR|g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s|@AWS_NETWORKING_CLUSTER_NETWORK_HOST_PREFIX@|$AWS_NETWORKING_CLUSTER_NETWORK_HOST_PREFIX|g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s|@AWS_NETWORKING_MACHINE_NETWORK_CIDR@|$AWS_NETWORKING_MACHINE_NETWORK_CIDR|g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s|@AWS_NETWORKING_MACHINE_NETWORK@|$AWS_NETWORKING_MACHINE_NETWORK|g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s|@AWS_NETWORKING_SERVICE_NETWORK@|$AWS_NETWORKING_SERVICE_NETWORK|g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s|@AWS_INSTALL_PUBLISH@|$AWS_INSTALL_PUBLISH|g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s|@AWS_MACHINE_TYPE_MASTER@|$AWS_MACHINE_TYPE_MASTER|g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s|@AWS_MACHINE_TYPE_WORKER@|$AWS_MACHINE_TYPE_WORKER|g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s|@IBM_OPENSHIFT_LOCAL_STORAGE_DEVICE_PATH@|$IBM_OPENSHIFT_LOCAL_STORAGE_DEVICE_PATH_AWS|g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s|@IBM_OPENSHIFT_LOCAL_BULK_STORAGE_DEVICE_PATH@|$IBM_OPENSHIFT_LOCAL_BULK_STORAGE_DEVICE_PATH_AWS|g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@OCP_OCS_STORAGE_CLASS_BLOCK@/$AWS_OCP_OCS_STORAGE_CLASS_BLOCK/g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@OCP_OCS_STORAGE_CLASS_FILE@/$AWS_OCP_OCS_STORAGE_CLASS_FILE/g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s|@AWS_WORKER_ROOTVOLUME_KMSKEYARN@|$AWS_WORKER_ROOTVOLUME_KMSKEYARN|g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s|@AWS_CREDENTIALS_MODE@|$AWS_CREDENTIALS_MODE|g"
        updateAWSInstallConfig
        ;;
     vsphere-*)
        updateVMWareInstallConfig
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s|@IBM_OPENSHIFT_LOCAL_STORAGE_DEVICE_PATH@|$IBM_OPENSHIFT_LOCAL_STORAGE_DEVICE_PATH_VSPHERE|g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s|@IBM_OPENSHIFT_LOCAL_BULK_STORAGE_DEVICE_PATH@|$IBM_OPENSHIFT_LOCAL_BULK_STORAGE_DEVICE_PATH_VSPHERE|g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@VSPHERE_HOSTNAME@/$VSPHERE_HOSTNAME/g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@VSPHERE_USERNAME@/$VSPHERE_USERNAME/g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@VSPHERE_PASSWORD@/$VSPHERE_PASSWORD/g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@VSPHERE_DATACENTER@/$VSPHERE_DATACENTER/g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@VSPHERE_DATASTORE@/$VSPHERE_DATASTORE/g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@VSPHERE_NETWORK1@/$VSPHERE_NETWORK1/g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@VSPHERE_NETWORK2@/$VSPHERE_NETWORK2/g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s|@VSPHERE_FOLDER@|$VSPHERE_FOLDER|g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@VSPHERE_API_VIP@/$VSPHERE_API_VIP/g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@VSPHERE_INGRESS_VIP@/$VSPHERE_INGRESS_VIP/g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@VSPHERE_CLUSTER@/$VSPHERE_CLUSTER/g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@VSPHERE_CLUSTER_OS_IMAGE@/$VSPHERE_CLUSTER_OS_IMAGE/g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s|@VSPHERE_NETWORKING_CLUSTERNETWORK_CIDR@|$VSPHERE_NETWORKING_CLUSTERNETWORK_CIDR|g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@VSPHERE_NETWORKING_CLUSTERNETWORK_HOSTPREFIX@/$VSPHERE_NETWORKING_CLUSTERNETWORK_HOSTPREFIX/g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s|@VSPHERE_NETWORKING_NETWORKTYPE@|$VSPHERE_NETWORKING_NETWORKTYPE|g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s|@VSPHERE_NETWORKING_SERVICE_NETWORK@|$VSPHERE_NETWORKING_SERVICE_NETWORK|g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@VSPHERE_INSTALL_PUBLISH@/$VSPHERE_INSTALL_PUBLISH/g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s|@VSPHERE_RESOURCE_POOL@|$VSPHERE_RESOURCE_POOL|g"
        if [ "${OCP_INSTALL_TYPE}" ==  "vsphere-upi" ]; then
          find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@OCP_OCS_STORAGE_CLASS_BLOCK@/$OCP_OCS_STORAGE_CLASS_BLOCK/g"
          find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@OCP_OCS_STORAGE_CLASS_FILE@/$OCP_OCS_STORAGE_CLASS_FILE/g"
          #We do not support 7,8 or 9 nodes, need to cleanup haproxy/dnsmasq
          find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/.*999.999.999.999.*//g"
        fi
        if [ "${OCP_INSTALL_TYPE}" ==  "vsphere-ipi" ]; then
          find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@OCP_OCS_STORAGE_CLASS_BLOCK@/$VSPHERE_OCP_OCS_STORAGE_CLASS_BLOCK/g"
          find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@OCP_OCS_STORAGE_CLASS_FILE@/$VSPHERE_OCP_OCS_STORAGE_CLASS_FILE/g"
        fi
        ;;
     gcp-ipi)
        updateGCPInstallConfig
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s|@IBM_OPENSHIFT_LOCAL_STORAGE_DEVICE_PATH@|$IBM_OPENSHIFT_LOCAL_STORAGE_DEVICE_PATH_GCP|g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s|@IBM_OPENSHIFT_LOCAL_BULK_STORAGE_DEVICE_PATH@|$IBM_OPENSHIFT_LOCAL_BULK_STORAGE_DEVICE_PATH_GCP|g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@GCP_PROJECT_ID@/$GCP_PROJECT_ID/g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@GCP_REGION@/$GCP_REGION/g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@GCP_MACHINE_TYPE_WORKER@/$GCP_MACHINE_TYPE_WORKER/g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@GCP_MACHINE_TYPE_MASTER@/$GCP_MACHINE_TYPE_MASTER/g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s|@GCP_NETWORKING_CLUSTER_NETWORK_CIDR@|$GCP_NETWORKING_CLUSTER_NETWORK_CIDR|g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@GCP_NETWORKING_CLUSTER_NETWORK_HOST_PREFIX@/$GCP_NETWORKING_CLUSTER_NETWORK_HOST_PREFIX/g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s|@GCP_NETWORKING_MACHINE_NETWORK_CIDR@|$GCP_NETWORKING_MACHINE_NETWORK_CIDR|g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@GCP_NETWORKING_MACHINE_NETWORK@/$GCP_NETWORKING_MACHINE_NETWORK/g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s|@GCP_NETWORKING_SERVICE_NETWORK@|$GCP_NETWORKING_SERVICE_NETWORK|g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@GCP_VPC_NETWORK@/$GCP_VPC_NETWORK/g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@GCP_CONTROL_PLANE_SUBNET@/$GCP_CONTROL_PLANE_SUBNET/g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@GCP_COMPUTE_SUBNET@/$GCP_COMPUTE_SUBNET/g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@GCP_INSTALL_PUBLISH@/$GCP_INSTALL_PUBLISH/g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@OCP_OCS_STORAGE_CLASS_BLOCK@/$GCP_OCP_OCS_STORAGE_CLASS_BLOCK/g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@OCP_OCS_STORAGE_CLASS_FILE@/$GCP_OCP_OCS_STORAGE_CLASS_FILE/g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@GCP_CREDENTIALS_MODE@/$GCP_CREDENTIALS_MODE/g"
        ;;
      #rosa-msp)
        #find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@OCP_OCS_STORAGE_CLASS_BLOCK@/$ROSA_OCP_OCS_STORAGE_CLASS_BLOCK/g"
        #find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@OCP_OCS_STORAGE_CLASS_FILE@/$ROSA_OCP_OCS_STORAGE_CLASS_FILE/g"
        #;;
  esac
  echo "${BLUE_TEXT}COMPLETE ${RESET_TEXT}All install files moved to ${TEMP_DIR}/${PRODUCT_SHORT_NAME} and updated based on your environment."
}
displayClusterInfo()
{
  case ${OCP_INSTALL_TYPE} in
    roks-msp)
            testIBMCloudLogin
            local INGRESS_DOMAIN=`ibmcloud ks cluster get --cluster ${CLUSTER_NAME} 2> /dev/null | grep "Ingress Subdomain" | awk '{print $3}'`
            INGRESS_DOMAIN=`echo ${INGRESS_DOMAIN} | sed 's/ //g'`
            ;;
    #rosa-msp)
            #ROSALogin
            #OCP_CONSOLE_URL=`rosa describe cluster -c=${CLUSTER_NAME} | grep "Console URL:" | awk '{print $3}'`
            #OCP_API_URL=`rosa describe cluster -c=${CLUSTER_NAME} | grep "API URL:" | awk '{print $3}'`
            #ROSA_DNS=`rosa describe cluster -c=${CLUSTER_NAME} | grep "DNS:" | awk '{print $3}'`
            #;;
          *)
              OCP_CLUSTER_API_IP=`nslookup api.${CLUSTER_NAME}.${BASE_DOMAIN} ${OCP_INSTALL_DNS} | grep Address | grep -v "#53" | awk '{print $2 }'`
              local IP_LOOP_COUNT=1
              for OCP_CLUSTER_API_IP_ENTRY in $OCP_CLUSTER_API_IP
              do
                  if [ ${IP_LOOP_COUNT} -eq 1 ]; then
                    OCP_CLUSTER_API_IPS=${OCP_CLUSTER_API_IP_ENTRY}
                  else
                    OCP_CLUSTER_API_IPS="${OCP_CLUSTER_API_IPS}, ${OCP_CLUSTER_API_IP_ENTRY}"
                  fi
                  let IP_LOOP_COUNT=IP_LOOP_COUNT+1
              done
              OCP_CLUSTER_API_INT_IP=`nslookup api-int.${CLUSTER_NAME}.${BASE_DOMAIN} ${OCP_INSTALL_DNS} | grep Address | grep -v "#53" | awk '{print $2 }'`
              local INT_IP_LOOP_COUNT=1
              for OCP_CLUSTER_API_INT_IP_ENTRY in $OCP_CLUSTER_API_INT_IP
              do
                  if [ ${INT_IP_LOOP_COUNT} -eq 1 ]; then
                    OCP_CLUSTER_API_INT_IPS=${OCP_CLUSTER_API_INT_IP_ENTRY}
                  else
                    OCP_CLUSTER_API_INT_IPS="${OCP_CLUSTER_API_INT_IPS}, ${OCP_CLUSTER_API_INT_IP_ENTRY}"
                  fi
                  let INT_IP_LOOP_COUNT=INT_IP_LOOP_COUNT+1
              done
              OCP_CLUSTER_APPS_IP=`nslookup myinfo.apps.${CLUSTER_NAME}.${BASE_DOMAIN} ${OCP_INSTALL_DNS} | grep Address | grep -v "#53" | awk '{print $2 }'`
              local IP_LOOP_COUNT=1
              for OCP_CLUSTER_APPS_IP_ENTRY in $OCP_CLUSTER_APPS_IP
              do
                  if [ ${IP_LOOP_COUNT} -eq 1 ]; then
                    OCP_CLUSTER_APPS_IPS=${OCP_CLUSTER_APPS_IP_ENTRY}
                  else
                    OCP_CLUSTER_APPS_IPS="${OCP_CLUSTER_APPS_IPS}, ${OCP_CLUSTER_APPS_IP_ENTRY}"
                  fi
                  let IP_LOOP_COUNT=IP_LOOP_COUNT+1
              done
              ;;
  esac
  getClusterInfo
  echo "${BLUE_TEXT}Here is your cluster info:"
  echo "##########################################################################################################${RESET_TEXT}"
  echo "Daffy Version            :   ${DAFFY_VERSION}"
  echo "Cluster Version          :   ${OC_CLUSTER_VERSION}"
  echo "Bastion OS               :   ${OS_FLAVOR}"
  echo "Platform Install Type    :   ${OCP_INSTALL_TYPE}"
  echo "OpenShift Cluster ID     :   ${OCP_CLUSTER_ID}"
  echo "OpenShift Cluster Name   :   ${CLUSTER_NAME}"
  case ${OCP_INSTALL_TYPE} in
    roks-msp)
        if [ ! -z "${INGRESS_DOMAIN}"  ] && [  -n "${INGRESS_DOMAIN}"  ]  ; then
          local INGRESS_IP=`nslookup ${INGRESS_DOMAIN} | grep Address: | grep -v 127.0.0.53 | awk '{print $2}'`
          echo "api                      :   api.${INGRESS_DOMAIN}                     --->   ${INGRESS_IP}"
          echo "*.apps                   :   *.apps.${INGRESS_DOMAIN}                  --->   ${INGRESS_IP}"
        fi
        ;;
    #rosa-msp)
        #echo "api                      :   ${OCP_API_URL}"
        #echo "*.apps                   :   *.apps.${ROSA_DNS}"
        #;;
    *-ipi)
          echo "api                      :   api.${CLUSTER_NAME}.${BASE_DOMAIN}        --->   ${OCP_CLUSTER_API_IPS}"
          echo "*.apps                   :   *.apps.${CLUSTER_NAME}.${BASE_DOMAIN}     --->   ${OCP_CLUSTER_APPS_IPS}"
        ;;
    *-upi)
          echo "api                      :   api.${CLUSTER_NAME}.${BASE_DOMAIN}        --->   ${OCP_CLUSTER_API_IPS}"
          echo "api-int                  :   api-int.${CLUSTER_NAME}.${BASE_DOMAIN}    --->   ${OCP_CLUSTER_API_INT_IP}"
          echo "*.apps                   :   *.apps.${CLUSTER_NAME}.${BASE_DOMAIN}     --->   ${OCP_CLUSTER_APPS_IP}"
          echo "Bootstrap                :   bootstrap.${CLUSTER_NAME}.${BASE_DOMAIN}  --->   ${OCP_INSTALLBOOTSTRAP_IP}"
          echo "Master1                  :   master1.${CLUSTER_NAME}.${BASE_DOMAIN}    --->   ${OCP_INSTALL_MASTER1_IP}"
          echo "Master2                  :   master2.${CLUSTER_NAME}.${BASE_DOMAIN}    --->   ${OCP_INSTALL_MASTER2_IP}"
          echo "Master3                  :   master3.${CLUSTER_NAME}.${BASE_DOMAIN}    --->   ${OCP_INSTALL_MASTER3_IP}"
          echo "Worker1                  :   worker1.${CLUSTER_NAME}.${BASE_DOMAIN}    --->   ${OCP_INSTALL_WORKER1_IP}"
          echo "Worker2                  :   worker2.${CLUSTER_NAME}.${BASE_DOMAIN}    --->   ${OCP_INSTALL_WORKER2_IP}"
          echo "Worker3                  :   worker3.${CLUSTER_NAME}.${BASE_DOMAIN}    --->   ${OCP_INSTALL_WORKER3_IP}"
          if [ "${VM_TSHIRT_SIZE}" == "Large" ] ;then
            echo "Worker4                  :   worker4.${CLUSTER_NAME}.${BASE_DOMAIN}    --->   ${OCP_INSTALL_WORKER4_IP}"
            echo "Worker5                  :   worker5.${CLUSTER_NAME}.${BASE_DOMAIN}    --->   ${OCP_INSTALL_WORKER5_IP}"
            echo "Worker6                  :   worker6.${CLUSTER_NAME}.${BASE_DOMAIN}    --->   ${OCP_INSTALL_WORKER6_IP}"
            if [ "${VM_TSHIRT_SIZE}" == "Large" ] ;then
              if [ ${VM_NUMBER_OF_WORKERS_LARGE} -ge 7 ];then
                echo "Worker7                  :   worker7.${CLUSTER_NAME}.${BASE_DOMAIN}    --->   ${OCP_INSTALL_WORKER7_IP}"
              fi
              if [ ${VM_NUMBER_OF_WORKERS_LARGE} -ge 8 ];then
                echo "Worker8                  :   worker8.${CLUSTER_NAME}.${BASE_DOMAIN}    --->   ${OCP_INSTALL_WORKER8_IP}"
              fi
              if [ ${VM_NUMBER_OF_WORKERS_LARGE} -ge 9 ];then
                echo "Worker9                  :   worker9.${CLUSTER_NAME}.${BASE_DOMAIN}    --->   ${OCP_INSTALL_WORKER9_IP}"
              fi
            fi
          fi
          printf "\n\n\n${RESET_TEXT}"
          ;;
    esac
    echo ""
}
displayAdminConsoleInfo()
{
  getClusterInfo
  case ${OCP_INSTALL_TYPE} in
    roks-msp)
        testIBMCloudLogin
        OCP_CONSOLE_URL=`ibmcloud oc cluster config --cluster ${CLUSTER_NAME} --output yaml 2> /dev/null| grep server: |  awk '{print $2}'`
        ibmcloud oc cluster config -c ${CLUSTER_NAME} --admin 1> /dev/null
        ;;
    #rosa-msp)
        #ROSALogin
        #OCP_CONSOLE_URL=`rosa describe cluster -c=${CLUSTER_NAME} | grep "Console URL:" | awk '{print $3}'`
        #OCP_LOCAL_ADMIN=`cat ${LOG_DIR}/rosa-admin.log | grep username | awk '{print $5}'`
        #OCP_LOCAL_ADMIN_PASSWORD=`cat ${LOG_DIR}/rosa-admin.log | grep username | awk '{print $7}'`
        #OCP_USER=""
        #OCP_PASSWORD=""
        #OCP_API_URL=`rosa describe cluster -c=${CLUSTER_NAME} | grep "API URL:" | awk '{print $3}'`
       #OCP_COMMAND_LINE=`cat ${LOG_DIR}/rosa-admin.log | grep username | awk '{print}'`
        #;;
  esac
    local OCP_USER_REMOTE=`oc whoami 2> /dev/null`
  getBastionIP
  echo ""
  echo "${BLUE_TEXT}Here is the login info you can use for all services and console:   "
  echo "##########################################################################################################${RESET_TEXT}"
  if [  "${OCP_LOCAL_ADMIN_PASSWORD}" != "" ]; then
    echo "Super User            :      ${OCP_USER}"
    echo "Password              :      ${OCP_PASSWORD}"
    echo "Admin User            :      ${OCP_LOCAL_ADMIN}"
    echo "Password              :      ${OCP_LOCAL_ADMIN_PASSWORD}"
  elif [ "${OCP_LOCAL_ADMIN_PASSWORD}" != "" ] && [ $OCP_INSTALL_TYPE == "rosa-msp" ]; then
    echo "Admin User            :      ${OCP_LOCAL_ADMIN}"
    echo "Password              :      ${OCP_LOCAL_ADMIN_PASSWORD}"
  else
    echo "Current User          :      ${OCP_USER_REMOTE}"
  fi
  echo "OpenShift Web Console :      ${BLUE_TEXT}${OCP_CONSOLE_URL}${RESET_TEXT}"
  if [  "${OCP_LOCAL_ADMIN_PASSWORD}" != "" ] && [ ${OCP_INSTALL_TYPE} == "rosa-msp" ]; then
      echo "OC API URL            :      $OCP_API_URL"
      echo "OC Command line       :      $OCP_COMMAND_LINE --insecure-skip-tls-verify"
  else
      if [ "${OCP_INSTALL_TYPE}" != "roks-msp" ] || [ ${OCP_INSTALL_TYPE} == "rosa-msp" ]; then
        echo "OC Commandline        :      export KUBECONFIG=${OCP_KUBECONFIG_DIR}/${CLUSTER_NAME}/kubeconfig"
        echo "OC Login command      :      oc login https://api.${OCP_HOST_NAME}:6443 -u ${OCP_LOCAL_ADMIN} -p ${OCP_LOCAL_ADMIN_PASSWORD} --insecure-skip-tls-verify"
      fi
  fi
  echo "OC Client Download    :      ${OPENSHIFT_SITE_DOWNLOAD}/pub/openshift-v4/clients/ocp/${OCP_RELEASE}"
  echo "Install Temp Files    :      ${TEMP_DIR}/${PRODUCT_SHORT_NAME}"
  echo "openshift-install Dir :      ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/ocp-install"
  case ${OCP_INSTALL_TYPE} in
    *-upi)
        if [ "${HAPROXY_BUILD}" == "true" ] ;then
            echo "haproxy stats here    :      ${BLUE_TEXT}http://${BASTION_HOST}:9000/stats${RESET_TEXT}"
        fi
        if [ ${VM_DASHBOARD_ENABLED} == "true" ]; then
            vmDashboardDisplayConnectionInfo
        fi
        ;;
  esac
  printf "\n\n\n${RESET_TEXT}"
}

getOpenShift()
{
    printHeaderMessage "Get OpenShift"
    unset KUBECONFIG
    FOUND_OC_COMMAND=`oc version 2> /dev/null | grep -c "Client Version: ${OCP_RELEASE}"`
    if [ "${FOUND_OC_COMMAND}" == "0"  ] ;then
        echo "Missing correct version of oc command line tools - downloading now "
        echo "wget ${OPENSHIFT_SITE_DOWNLOAD}/pub/openshift-v4/clients/ocp/${OCP_RELEASE}/openshift-client-linux-${OCP_RELEASE}.tar.gz"
        wget ${OPENSHIFT_SITE_DOWNLOAD}/pub/openshift-v4/clients/ocp/${OCP_RELEASE}/openshift-client-linux-${OCP_RELEASE}.tar.gz 2> /dev/null
        if [ ! -f openshift-client-linux-${OCP_RELEASE}.tar.gz ]; then
          echo "${RED_TEXT}Failed to download openshift-client, unable to continue:"
          echo "${OPENSHIFT_SITE_DOWNLOAD}/pub/openshift-v4/clients/ocp/${OCP_RELEASE}/openshift-client-linux-${OCP_RELEASE}.tar.gz${RESET_TEXT}"
          exit 99
        fi
        tar xvf openshift-client-linux-${OCP_RELEASE}.tar.gz 2>&1 > /dev/null
        mv oc /usr/local/bin/
        mv kubectl /usr/local/bin
        rm -rf openshift-client-linux-${OCP_RELEASE}.tar.gz README.md
     else
        echo "Correct version of oc tools found, will not download."
     fi
     oc version 2> /dev/null
     echo ""
     case ${OCP_INSTALL_TYPE} in
       *-upi|*-ipi)
             FOUND_OPENSHIFT_INSTALL_COMMAND=`openshift-install version 2> /dev/null | grep -c "openshift-install ${OCP_RELEASE}"`
             if [ "${FOUND_OPENSHIFT_INSTALL_COMMAND}" == "0" ] ;then
                 echo "Missing correct version of openshift-install command line tool - downloading now "
                 echo "wget ${OPENSHIFT_SITE_DOWNLOAD}/pub/openshift-v4/clients/ocp/${OCP_RELEASE}/openshift-install-linux-${OCP_RELEASE}.tar.gz"
                 wget ${OPENSHIFT_SITE_DOWNLOAD}/pub/openshift-v4/clients/ocp/${OCP_RELEASE}/openshift-install-linux-${OCP_RELEASE}.tar.gz 2> /dev/null
                 if [ ! -f  openshift-install-linux-${OCP_RELEASE}.tar.gz ]; then
                   echo "${RED_TEXT}Failed to download openshift-install, unable to continue:"
                   echo "${OPENSHIFT_SITE_DOWNLOAD}/pub/openshift-v4/clients/ocp/${OCP_RELEASE}/openshift-install-linux-${OCP_RELEASE}.tar.gz${RESET_TEXT}"
                   exit 99
                 fi
                 tar xvf openshift-install-linux-${OCP_RELEASE}.tar.gz 2>&1 >  /dev/null
                 mv openshift-install /usr/local/bin/
                 rm -rf openshift-install-linux-${OCP_RELEASE}.tar.gz README.md
             else
                 echo "Correct version of openshift-install tool found, will not download."
             fi
             openshift-install version | grep "openshift-install ${OCP_RELEASE}"
             echo ""
       esac
}
addTrustBundle()
{
  echo "Add Additional Trust Bundle to install-config.yaml"
  ATB_INSTALL_CONFIG_YAML=${1}
  echo "Adding new trust bundle to ${ATB_INSTALL_CONFIG_YAML}"
  cert_data=$(grep -v '^-----' "${DATA_DIR}/${PROJECT_NAME}/certs/${LOCAL_REGISTRY_DNS_NAME}.crt" | base64 -d | base64 -w 0)
  echo "additionalTrustBundle: |" >> "${ATB_INSTALL_CONFIG_YAML}"
  echo "  -----BEGIN CERTIFICATE-----" >> "${ATB_INSTALL_CONFIG_YAML}"
  echo "  ${cert_data}" >> "${ATB_INSTALL_CONFIG_YAML}"
  echo "  -----END CERTIFICATE-----" >> "${ATB_INSTALL_CONFIG_YAML}"

}
addImageContentSources()
{

  echo ""
  getOpenShift
  unset KUBECONFIG
  OCP_RELEASE_LOCAL_VERSION=`oc version 2> /dev/null | awk '{print $3 }'`
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@OCP_RELEASE_LOCAL_VERSION@/$OCP_RELEASE_LOCAL_VERSION/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/openshift@LOCAL_OCP_REPOSITORY_NAME@/$LOCAL_OCP_REPOSITORY_NAME/g"
  AICS_INSTALL_CONFIG_YAML=${1}
  echo "Add Image Content Sources to install-config.yaml"
  cat ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/registry/imageContentSources.yaml >> ${AICS_INSTALL_CONFIG_YAML}
  echo ""
}
addLocalRegistryAuthInfo()
{
    if [ "${LOCAL_REGISTRY_ENABLED}" == "true"  ]; then
      printHeaderMessage "Add Local Registry AuthInfo(Air Gap)"
      echo "Updated PULL_SECRET with Local Registry Auth Info"
      PULL_SECRET=`echo $PULL_SECRET | jq ".auths += ${LOCAL_REGISTRY_AUTH_INFO}"  | sed ':a;N;$!ba;s/\n/ /g' | sed 's/ //g'`
      echo ""
    fi
}
enableLocalRegistryPull()
{
  if [ "${LOCAL_REGISTRY_ENABLED}" == "true"  ]; then
    printHeaderMessage "Enable Local Registry Pull Info(Air Gap)"
    addTrustBundle ${1}
    addImageContentSources ${1}
    echo ""
  fi
}

createVMDashboard()
{
      if [ ${OCP_INSTALL_TYPE} == "kvm-upi" ]; then
        if [ ${VM_DASHBOARD_ENABLED} == "true" ]; then
            printHeaderMessage "Create VMDashboard"
            vmDashboardInstallTools
            vmDashboardSetUser
            vmDashboardSetWebserver
            vmDashboardSetDB
            vmDashboardDisplayConnectionInfo
            echo ""
        fi
    fi
}
createImageRegistry()
{ #https://access.redhat.com/documentation/en-us/red_hat_openshift_container_storage/4.4/html-single/managing_openshift_container_storage/index
  case ${OCP_INSTALL_TYPE} in
     *-upi|vsphere*)
        if [ "${OCP_CREATE_OPENSHIFT_CONTAINER_STORAGE}" == "true" ] ||  [ "${OCP_CREATE_NFS_STORAGE}" == "true"  ]; then
            printHeaderMessage "Creating OpenShift Image Registry"
            oc apply -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/image-registry/persistentvolumeclaim.yaml
            case ${OCP_INSTALL_TYPE} in
               *-upi)
                  oc patch configs.imageregistry.operator.openshift.io cluster --type merge --patch '{"spec":{"managementState":"Managed"}}'
                  ;;
            esac
            oc patch configs.imageregistry.operator.openshift.io cluster --type merge --patch '{"spec":{"storage":{"pvc":{"claim":"image-registry-pvc"}}}}'
            echo ""
         fi
         ;;
  esac

}
createImageRegistryPostInstall()
{
    if [ "${OCP_CREATE_OPENSHIFT_CONTAINER_STORAGE}" == true ];then
          OCP_IMAGE_REGISTRY_STORAGE_CLASS=ocs-storagecluster-cephfs
    fi
    #Image Registry
    cp -fR ${DIR}/templates/image-registry* ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/image-registry
    find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@OCP_IMAGE_REGISTRY_STORAGE_CLASS@/$OCP_IMAGE_REGISTRY_STORAGE_CLASS/g"
    find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@OCP_IMAGE_REGISTRY_STORAGE_SIZE@/$OCP_IMAGE_REGISTRY_STORAGE_SIZE/g"
    createImageRegistry
}
setClusterPTRRecordFromIP()
{
  OCP_INSTALL_DNS_PTR_RECORD=`echo ${OCP_INSTALL_DNS} | awk 'BEGIN{FS="."}{print $4"."$3"."$2"."$1".in-addr.arpa"}'`
  OCP_INSTALL_BOOTSTRAP_PTR_RECORD=`echo ${OCP_INSTALLBOOTSTRAP_IP} | awk 'BEGIN{FS="."}{print $4"."$3"."$2"."$1".in-addr.arpa"}'`
  OCP_INSTALL_MASTER1_PTR_RECORD=`echo ${OCP_INSTALL_MASTER1_IP} | awk 'BEGIN{FS="."}{print $4"."$3"."$2"."$1".in-addr.arpa"}'`
  OCP_INSTALL_MASTER2_PTR_RECORD=`echo ${OCP_INSTALL_MASTER2_IP} | awk 'BEGIN{FS="."}{print $4"."$3"."$2"."$1".in-addr.arpa"}'`
  OCP_INSTALL_MASTER3_PTR_RECORD=`echo ${OCP_INSTALL_MASTER3_IP} | awk 'BEGIN{FS="."}{print $4"."$3"."$2"."$1".in-addr.arpa"}'`
  OCP_INSTALL_WORKER1_PTR_RECORD=`echo ${OCP_INSTALL_WORKER1_IP} | awk 'BEGIN{FS="."}{print $4"."$3"."$2"."$1".in-addr.arpa"}'`
  OCP_INSTALL_WORKER2_PTR_RECORD=`echo ${OCP_INSTALL_WORKER2_IP} | awk 'BEGIN{FS="."}{print $4"."$3"."$2"."$1".in-addr.arpa"}'`
  OCP_INSTALL_WORKER3_PTR_RECORD=`echo ${OCP_INSTALL_WORKER3_IP} | awk 'BEGIN{FS="."}{print $4"."$3"."$2"."$1".in-addr.arpa"}'`
  OCP_INSTALL_WORKER4_PTR_RECORD=`echo ${OCP_INSTALL_WORKER4_IP} | awk 'BEGIN{FS="."}{print $4"."$3"."$2"."$1".in-addr.arpa"}'`
  OCP_INSTALL_WORKER5_PTR_RECORD=`echo ${OCP_INSTALL_WORKER5_IP} | awk 'BEGIN{FS="."}{print $4"."$3"."$2"."$1".in-addr.arpa"}'`
  OCP_INSTALL_WORKER6_PTR_RECORD=`echo ${OCP_INSTALL_WORKER6_IP} | awk 'BEGIN{FS="."}{print $4"."$3"."$2"."$1".in-addr.arpa"}'`
  OCP_INSTALL_WORKER7_PTR_RECORD=`echo ${OCP_INSTALL_WORKER7_IP} | awk 'BEGIN{FS="."}{print $4"."$3"."$2"."$1".in-addr.arpa"}'`
  OCP_INSTALL_WORKER8_PTR_RECORD=`echo ${OCP_INSTALL_WORKER8_IP} | awk 'BEGIN{FS="."}{print $4"."$3"."$2"."$1".in-addr.arpa"}'`
  OCP_INSTALL_WORKER9_PTR_RECORD=`echo ${OCP_INSTALL_WORKER9_IP} | awk 'BEGIN{FS="."}{print $4"."$3"."$2"."$1".in-addr.arpa"}'`
}

validateReserverLookupDNS()
{
  printHeaderMessage "Precheck DNS PTR records(setup outside of Installer)"
  local FOUND_PTR_BOOTSTRAP=`nslookup ${OCP_INSTALLBOOTSTRAP_IP} ${OCP_INSTALL_DNS}| grep -c "bootstrap.${CLUSTER_NAME}.${BASE_DOMAIN}"`
  if [ ${FOUND_PTR_BOOTSTRAP} -eq 1 ]; then
      echo "${BLUE_TEXT}PASSED ${RESET_TEXT} DNS PTR record ${OCP_INSTALLBOOTSTRAP_IP} resolves to bootstrap.${CLUSTER_NAME}.${BASE_DOMAIN}"
  else
      echo "${RED_TEXT}FALED ${RESET_TEXT}  DNS PTR record ${OCP_INSTALLBOOTSTRAP_IP} does ${RED_TEXT}NOT${RESET_TEXT} resolves to bootstrap.${CLUSTER_NAME}.${BASE_DOMAIN}"
      nslookup ${OCP_INSTALLBOOTSTRAP_IP}
      SHOULD_EXIT=1
  fi

  local FOUND_PTR_MASTER1=`nslookup ${OCP_INSTALL_MASTER1_IP} ${OCP_INSTALL_DNS}| grep -c "master1.${CLUSTER_NAME}.${BASE_DOMAIN}"`
  if [ ${FOUND_PTR_MASTER1} -eq 1 ]; then
      echo "${BLUE_TEXT}PASSED ${RESET_TEXT} DNS PTR record ${OCP_INSTALL_MASTER1_IP} resolves to master1.${CLUSTER_NAME}.${BASE_DOMAIN}"
  else
      echo "${RED_TEXT}FALED ${RESET_TEXT}  DNS PTR record ${OCP_INSTALL_MASTER1_IP} does ${RED_TEXT}NOT${RESET_TEXT} resolves to master1.${CLUSTER_NAME}.${BASE_DOMAIN}"
      nslookup ${OCP_INSTALL_MASTER1_IP}
      SHOULD_EXIT=1
  fi
  local FOUND_PTR_MASTER2=`nslookup ${OCP_INSTALL_MASTER2_IP} ${OCP_INSTALL_DNS}| grep -c "master2.${CLUSTER_NAME}.${BASE_DOMAIN}"`
  if [ ${FOUND_PTR_MASTER2} -eq 1 ]; then
      echo "${BLUE_TEXT}PASSED ${RESET_TEXT} DNS PTR record ${OCP_INSTALL_MASTER2_IP} resolves to master2.${CLUSTER_NAME}.${BASE_DOMAIN}"
  else
      echo "${RED_TEXT}FALED ${RESET_TEXT}  DNS PTR record ${OCP_INSTALL_MASTER2_IP} does ${RED_TEXT}NOT${RESET_TEXT} resolves to master2.${CLUSTER_NAME}.${BASE_DOMAIN}"
      nslookup ${OCP_INSTALL_MASTER2_IP}
      SHOULD_EXIT=1
  fi
  local FOUND_PTR_MASTER3=`nslookup ${OCP_INSTALL_MASTER3_IP} ${OCP_INSTALL_DNS}| grep -c "master3.${CLUSTER_NAME}.${BASE_DOMAIN}"`
  if [ ${FOUND_PTR_MASTER3} -eq 1 ]; then
      echo "${BLUE_TEXT}PASSED ${RESET_TEXT} DNS PTR record ${OCP_INSTALL_MASTER3_IP} resolves to master3.${CLUSTER_NAME}.${BASE_DOMAIN}"
  else
      echo "${RED_TEXT}FALED ${RESET_TEXT}  DNS PTR record ${OCP_INSTALL_MASTER3_IP} does ${RED_TEXT}NOT${RESET_TEXT} resolves to master3.${CLUSTER_NAME}.${BASE_DOMAIN}"
      nslookup ${OCP_INSTALL_MASTER3_IP}
      SHOULD_EXIT=1
  fi
  local FOUND_PTR_WORKER1=`nslookup ${OCP_INSTALL_WORKER1_IP} ${OCP_INSTALL_DNS}| grep -c "worker1.${CLUSTER_NAME}.${BASE_DOMAIN}"`
  if [ ${FOUND_PTR_MASTER3} -eq 1 ]; then
      echo "${BLUE_TEXT}PASSED ${RESET_TEXT} DNS PTR record ${OCP_INSTALL_WORKER1_IP} resolves to worker1.${CLUSTER_NAME}.${BASE_DOMAIN}"
  else
      echo "${RED_TEXT}FALED ${RESET_TEXT}  DNS PTR record ${OCP_INSTALL_WORKER1_IP} does ${RED_TEXT}NOT${RESET_TEXT} resolves to worker1.${CLUSTER_NAME}.${BASE_DOMAIN}"
      nslookup ${OCP_INSTALL_WORKER1_IP}
      SHOULD_EXIT=1
  fi
  local FOUND_PTR_WORKER2=`nslookup ${OCP_INSTALL_WORKER2_IP} ${OCP_INSTALL_DNS}| grep -c "worker2.${CLUSTER_NAME}.${BASE_DOMAIN}"`
  if [ ${FOUND_PTR_WORKER2} -eq 1 ]; then
      echo "${BLUE_TEXT}PASSED ${RESET_TEXT} DNS PTR record ${OCP_INSTALL_WORKER2_IP} resolves to worker2.${CLUSTER_NAME}.${BASE_DOMAIN}"
  else
      echo "${RED_TEXT}FALED ${RESET_TEXT}  DNS PTR record ${OCP_INSTALL_WORKER2_IP} does ${RED_TEXT}NOT${RESET_TEXT} resolves to worker2.${CLUSTER_NAME}.${BASE_DOMAIN}"
      nslookup ${OCP_INSTALL_WORKER2_IP}
      SHOULD_EXIT=1
  fi
  local FOUND_PTR_WORKER3=`nslookup ${OCP_INSTALL_WORKER3_IP} ${OCP_INSTALL_DNS}| grep -c "worker3.${CLUSTER_NAME}.${BASE_DOMAIN}"`
  if [ ${FOUND_PTR_WORKER3} -eq 1 ]; then
      echo "${BLUE_TEXT}PASSED ${RESET_TEXT} DNS PTR record ${OCP_INSTALL_WORKER3_IP} resolves to worker3.${CLUSTER_NAME}.${BASE_DOMAIN}"
  else
      echo "${RED_TEXT}FALED ${RESET_TEXT}  DNS PTR record ${OCP_INSTALL_WORKER3_IP} does ${RED_TEXT}NOT${RESET_TEXT} resolves to worker3.${CLUSTER_NAME}.${BASE_DOMAIN}"
      nslookup ${OCP_INSTALL_WORKER3_IP}
      SHOULD_EXIT=1
  fi
  local FOUND_PTR_WORKER4=`nslookup ${OCP_INSTALL_WORKER4_IP} ${OCP_INSTALL_DNS}| grep -c "worker4.${CLUSTER_NAME}.${BASE_DOMAIN}"`
  if [ ${FOUND_PTR_WORKER4} -eq 1 ]; then
      echo "${BLUE_TEXT}PASSED ${RESET_TEXT} DNS PTR record ${OCP_INSTALL_WORKER4_IP} resolves to Worker4.${CLUSTER_NAME}.${BASE_DOMAIN}"
  else
      echo "${RED_TEXT}FALED ${RESET_TEXT}  DNS PTR record ${OCP_INSTALL_WORKER4_IP} does ${RED_TEXT}NOT${RESET_TEXT} resolves to worker4.${CLUSTER_NAME}.${BASE_DOMAIN}"
      nslookup ${OCP_INSTALL_WORKER4_IP}
      SHOULD_EXIT=1
  fi
  local FOUND_PTR_WORKER5=`nslookup ${OCP_INSTALL_WORKER5_IP} ${OCP_INSTALL_DNS}| grep -c "worker5.${CLUSTER_NAME}.${BASE_DOMAIN}"`
  if [ ${FOUND_PTR_WORKER5} -eq 1 ]; then
      echo "${BLUE_TEXT}PASSED ${RESET_TEXT} DNS PTR record ${OCP_INSTALL_WORKER5_IP} resolves to worker5.${CLUSTER_NAME}.${BASE_DOMAIN}"
  else
      echo "${RED_TEXT}FALED ${RESET_TEXT}  DNS PTR record ${OCP_INSTALL_WORKER5_IP} does ${RED_TEXT}NOT${RESET_TEXT} resolves to worker5.${CLUSTER_NAME}.${BASE_DOMAIN}"
      nslookup ${OCP_INSTALL_WORKER5_IP}
      SHOULD_EXIT=1
  fi
  local FOUND_PTR_WORKER6=`nslookup ${OCP_INSTALL_WORKER6_IP} ${OCP_INSTALL_DNS}| grep -c "worker6.${CLUSTER_NAME}.${BASE_DOMAIN}"`
  if [ ${FOUND_PTR_WORKER6} -eq 1 ]; then
      echo "${BLUE_TEXT}PASSED ${RESET_TEXT} DNS PTR record ${OCP_INSTALL_WORKER6_IP} resolves to worker6.${CLUSTER_NAME}.${BASE_DOMAIN}"
  else
      echo "${RED_TEXT}FALED ${RESET_TEXT}  DNS PTR record ${OCP_INSTALL_WORKER6_IP} does ${RED_TEXT}NOT${RESET_TEXT} resolves to worker6.${CLUSTER_NAME}.${BASE_DOMAIN}"
      nslookup ${OCP_INSTALL_WORKER6_IP}
      SHOULD_EXIT=1
  fi
  if [ ${VM_NUMBER_OF_WORKERS_LARGE} -ge 7 ] ; then
      if [ -z ${OCP_INSTALL_WORKER7_IP} ]; then
          echo "${RED_TEXT}FALED ${RESET_TEXT} Missing IP for OCP_INSTALL_WORKER7_IP="
      else
          local FOUND_PTR_WORKER7=`nslookup ${OCP_INSTALL_WORKER7_IP} ${OCP_INSTALL_DNS}| grep -c "worker7.${CLUSTER_NAME}.${BASE_DOMAIN}"`
          if [ ${FOUND_PTR_WORKER7} -eq 1 ]; then
              echo "${BLUE_TEXT}PASSED ${RESET_TEXT} DNS PTR record ${OCP_INSTALL_WORKER7_IP} resolves to worker7.${CLUSTER_NAME}.${BASE_DOMAIN}"
          else
              echo "${RED_TEXT}FALED ${RESET_TEXT}  DNS PTR record ${OCP_INSTALL_WORKER7_IP} does ${RED_TEXT}NOT${RESET_TEXT} resolves to worker7.${CLUSTER_NAME}.${BASE_DOMAIN}"
              nslookup ${OCP_INSTALL_WORKER7_IP}
              SHOULD_EXIT=1
          fi
      fi
  fi
  if [ ${VM_NUMBER_OF_WORKERS_LARGE} -ge 8 ]; then
    if [ -z ${OCP_INSTALL_WORKER8_IP} ]; then
        echo "${RED_TEXT}FALED ${RESET_TEXT} Missing IP for OCP_INSTALL_WORKER8_IP="
    else
        local FOUND_PTR_WORKER8=`nslookup ${OCP_INSTALL_WORKER8_IP} ${OCP_INSTALL_DNS}| grep -c "worker8.${CLUSTER_NAME}.${BASE_DOMAIN}"`
        if [ ${FOUND_PTR_WORKER8} -eq 1 ]; then
            echo "${BLUE_TEXT}PASSED ${RESET_TEXT} DNS PTR record ${OCP_INSTALL_WORKER8_IP} resolves to worker8.${CLUSTER_NAME}.${BASE_DOMAIN}"
        else
            echo "${RED_TEXT}FALED ${RESET_TEXT}  DNS PTR record ${OCP_INSTALL_WORKER8_IP} does ${RED_TEXT}NOT${RESET_TEXT} resolves to worker8.${CLUSTER_NAME}.${BASE_DOMAIN}"
            nslookup ${OCP_INSTALL_WORKER8_IP}
            SHOULD_EXIT=1
        fi
    fi
  fi
  if [ ${VM_NUMBER_OF_WORKERS_LARGE} -ge 9 ]; then
    if [ -z ${OCP_INSTALL_WORKER9_IP} ]; then
      echo "${RED_TEXT}FALED ${RESET_TEXT} Missing IP for OCP_INSTALL_WORKER9_IP="
    else
      local FOUND_PTR_WORKER9=`nslookup ${OCP_INSTALL_WORKER9_IP} ${OCP_INSTALL_DNS}| grep -c "worker9.${CLUSTER_NAME}.${BASE_DOMAIN}"`
      if [ ${FOUND_PTR_WORKER9} -eq 1 ]; then
          echo "${BLUE_TEXT}PASSED ${RESET_TEXT} DNS PTR record ${OCP_INSTALL_WORKER9_IP} resolves to worker9.${CLUSTER_NAME}.${BASE_DOMAIN}"
      else
          echo "${RED_TEXT}FALED ${RESET_TEXT}  DNS PTR record ${OCP_INSTALL_WORKER9_IP} does ${RED_TEXT}NOT${RESET_TEXT} resolves to worker9.${CLUSTER_NAME}.${BASE_DOMAIN}"
          nslookup ${OCP_INSTALL_WORKER9_IP}
          SHOULD_EXIT=1
      fi
    fi
  fi
}
precheckDNSBuild()
{
  if [ "${DNSMASQ_BUILD}" == "true" ]; then
    variablePresent ${OCP_FORWARD_DNS} OCP_FORWARD_DNS
  else
    validateReserverLookupDNS
  fi
}
