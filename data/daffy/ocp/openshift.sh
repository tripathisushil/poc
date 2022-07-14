#!/bin/bash
############################################################
#Author           : Kyle Dawson
#Author email     : Kyle.Dawson@us.ibm.com
#Original Date    : 2021-08-15
#Initial Version  : v2021-12-01
############################################################
approveADMCerts()
{
  if [[ ${RUN_CSR_APPROVE_PROCESS} == "true" ]]; then
      printHeaderMessage "Approve Pending CSR in OpenShift"
      export KUBECONFIG=${TEMP_DIR}/${PRODUCT_SHORT_NAME}/ocp-install/auth/kubeconfig
      echo ""
      if [[ "$1" == "NoWait" ]]; then
         echo "Will run command to approve with no waiting."
      else
        blinkWaitMessage "Waiting for worker nodes to come online to approve their CSR approx 10 mins" 300
      fi
      #oc get csr -o go-template='{{range .items}}{{if not .status}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}' | xargs oc adm certificate approve  &> /dev/null
      #Get number of VM that were built, minus the Bootstrap VM
      (( GET_APPROVED = ${VM_NUMBER_OF_IMAGES} - 1 ))
      APPROVE_CSR_LOOP_COUNT=0
      APPROVED_CSR=`oc get csr 2> /dev/null | grep system:node | grep -c Approved`
      while [ ${APPROVED_CSR} -lt ${GET_APPROVED} ]
      do
        APPROVED_CSR=`oc get csr  2> /dev/null | grep system:node | grep -c Approved`
        if   [ ${APPROVED_CSR} -ge ${GET_APPROVED} ] ; then
            echo "${BLUE_TEXT}COMPLETE ${RESET_TEXT} All CSR's have been approved."
            break
        fi
        blinkWaitMessage "Waiting for Approved CSR's (${APPROVED_CSR} of ${GET_APPROVED})" 30
        oc get csr -o go-template='{{range .items}}{{if not .status}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}'  2> /dev/null | xargs oc adm certificate approve  &> /dev/null
        let  APPROVE_CSR_LOOP_COUNT=APPROVE_CSR_LOOP_COUNT+1
        if [ $APPROVE_CSR_LOOP_COUNT -ge 120 ] ;then
          echo ""
          echo "${RED_TEXT}All node CSR were not requested and approved"
          echo "######################################################${RESET_TEXT}"
          echo "It looks like one or more of the nodes did not come online in a timely manner."
          echo "Script will continue with install, but you should resolve after cluster is up."
          oc get csr | grep system:node |  awk '{print $4 "  --->   " $5} '| sort
          oc get nodes
          echo "Run this after install completes, if there is a need to approve any pending CSR"
          echo "${DATA_DIR}/${PROJECT_NAME}/${PRODUCT_SHORT_NAME}/build.sh ${ENV_FILE_NAME} --approveCSR"
          echo ""
          break
        fi
      done
      echo ""
    fi
}
createIgnitionFiles()
{
  printHeaderMessage "Create Ignition Files (LOG -> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/create-ignitionFiles.log )"
  OPENSHFIT_INSTALL_DIR=${TEMP_DIR}/${PRODUCT_SHORT_NAME}/ocp-install
  mkdir -p ${OPENSHFIT_INSTALL_DIR}
  cd ${OPENSHFIT_INSTALL_DIR}
  echo "Running openshift-install create ignition-configs --dir=${OPENSHFIT_INSTALL_DIR}"
  unbuffer openshift-install create ignition-configs --dir=${OPENSHFIT_INSTALL_DIR} 2>&1 | tee  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/create-ignitionFiles.log 2>&1
  local ERROR_OCCURED=`cat ${LOG_DIR}/${PRODUCT_SHORT_NAME}/create-ignitionFiles.log | grep -c "FATAL\|failed"`
  if [ ${ERROR_OCCURED} -ge 1 ]; then
    echo ""
    echo ""
    echo "${RED_TEXT}Exiting Script!!!!!!!!!!!!!!!!!!!!!${RESET_TEXT}"
    echo ""
    echo ""
    echo ""
    exit 99
  fi
}

createManifestFiles()
{
  printHeaderMessage "Create Manifest Files (LOG -> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/create-manifestFiles.log )"
  OPENSHFIT_INSTALL_DIR=${TEMP_DIR}/${PRODUCT_SHORT_NAME}/ocp-install
  mkdir -p ${OPENSHFIT_INSTALL_DIR}
  cd ${OPENSHFIT_INSTALL_DIR}
  cp ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/install-config.yaml ${OPENSHFIT_INSTALL_DIR}
  echo "Running openshift-install create manifests --dir=${OPENSHFIT_INSTALL_DIR}"
  unbuffer openshift-install create manifests --dir=${OPENSHFIT_INSTALL_DIR} 2>&1 | tee ${LOG_DIR}/${PRODUCT_SHORT_NAME}/create-manifestFiles.log
  local ERROR_OCCURED=`cat ${LOG_DIR}/${PRODUCT_SHORT_NAME}/create-manifestFiles.log | grep -c "FATAL\|failed"`
  if [ ${ERROR_OCCURED} -ge 1 ]; then
    echo ""
    echo ""
    echo "${RED_TEXT}Exiting Script!!!!!!!!!!!!!!!!!!!!!${RESET_TEXT}"
    echo ""
    echo ""
    echo ""
    exit 99
  fi
  echo "Disabling Masters from being Schedulable"
  rm -f ${OPENSHFIT_INSTALL_DIR}/openshift/99_openshift-cluster-api_master-machines-*.yaml ${OPENSHFIT_INSTALL_DIR}/openshift/99_openshift-cluster-api_worker-machineset-*.yaml
  sed -i -e 's/mastersSchedulable.*/mastersSchedulable: false/g' ${OPENSHFIT_INSTALL_DIR}/manifests/cluster-scheduler-02-config.yml
  cp -fR ${OPENSHFIT_INSTALL_DIR} ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/ocp-install-bkp
  sleep 2

}


runOpenShiftInstallerCreateCluster()
{
    printHeaderMessage "Run openshift-install (LOG -> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/create-cluster.log )"
    rm -fR ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/ocp-install 2> /dev/null
    mkdir -p ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/ocp-install
    cp ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/install-config.yaml ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/ocp-install
    cd ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/ocp-install
    echo "Running openshift-install --dir=${TEMP_DIR}/${PRODUCT_SHORT_NAME}/ocp-install create cluster ${OPENSHIFT_INSTALLER_ARGS} in dir  ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/ocp-install"
    unbuffer openshift-install --dir=${TEMP_DIR}/${PRODUCT_SHORT_NAME}/ocp-install create cluster ${OPENSHIFT_INSTALLER_ARGS} 2>&1 | tee ${LOG_DIR}/${PRODUCT_SHORT_NAME}/create-cluster.log
    OCP_CREATE_CLUSTER_FAILED_BOOTSTRAP=`cat ${LOG_DIR}/${PRODUCT_SHORT_NAME}/create-cluster.log | grep -c "Bootstrap failed"`
    OCP_CREATE_CLUSTER_FAILED_INSTALL=`cat ${LOG_DIR}/${PRODUCT_SHORT_NAME}/create-cluster.log | grep -c "failed to initialize the cluster"`
    OCP_CREATE_CLUSTER_FAILED_CONFIGS=`cat ${LOG_DIR}/${PRODUCT_SHORT_NAME}/create-cluster.log | grep -c "failed to fetch"`
    if  [  ${OCP_CREATE_CLUSTER_FAILED_BOOTSTRAP} -ge 1 ] ;then
      echo "Run openshift-install(Bootstrap Complete) again, first time it timed out."
      runOpenShiftInstallerBootstrapComplete
    elif [  ${OCP_CREATE_CLUSTER_FAILED_INSTALL}  -ge 1 ] ;then
      echo "Run openshift-install(Install Complete) again, first time it timed out."
      runOpenShiftInstallerInstallComplete
    elif [ ${OCP_CREATE_CLUSTER_FAILED_CONFIGS} -ge 1 ]; then
      echo "${LOG_DIR}/${PRODUCT_SHORT_NAME}/create-cluster.log contained - failed to fetch."
      echo "${RED_TEXT}FATAL ERROR${RESET_TEXT}"
      echo ""
      echo "Exiting Script!!!!!!!!!!!!!!!!!!!!!"
      exit 99
    fi
    export KUBECONFIG=${TEMP_DIR}/${PRODUCT_SHORT_NAME}/ocp-install/auth/kubeconfig
    echo ""
}

runOpenShiftInstallerBootstrapComplete()
{
  printHeaderMessage "Run openshift-install (LOG ->${LOG_DIR}/${PRODUCT_SHORT_NAME}/ocp-bootstrap-complete.log )"
  cd ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/ocp-install
  echo "Running openshift-install --dir=${TEMP_DIR}/${PRODUCT_SHORT_NAME}/ocp-install wait-for bootstrap-complete ${OPENSHIFT_INSTALLER_ARGS} in dir  ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/ocp-install"
  unbuffer openshift-install --dir=${TEMP_DIR}/${PRODUCT_SHORT_NAME}/ocp-install wait-for bootstrap-complete ${OPENSHIFT_INSTALLER_ARGS} 2>&1 | tee  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ocp-bootstrap-complete.log
  OCP_BOOTSTRAP_COMPLETE=`cat ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ocp-bootstrap-complete.log | grep -c "safe to remove the bootstrap resources"`
  if  [  ${OCP_BOOTSTRAP_COMPLETE} -eq 0 ] ;then
    echo "${RED_TEXT}ERROR : ############# Bootstrap Install Not Complete ################################################${RESET_TEXT}"
    echo "${RED_TEXT}Failed waiting for Bootstrap Install to complete${RESET_TEXT}"
    echo "${GREEN_TEXT}To debug the bootstrap process you can use the following commands:${RESET_TEXT}"
    echo "${GREEN_TEXT}Install logs are here : ${BLUE_TEXT}${LOG_DIR}${RESET_TEXT}"
    echo "${GREEN_TEXT}Must Gather command: "
    echo "${BLUE_TEXT}openshift-install gather bootstrap --bootstrap bootstrap.${CLUSTER_NAME}.${BASE_DOMAIN} --master 'master1.${CLUSTER_NAME}.${BASE_DOMAIN} master2.${CLUSTER_NAME}.${BASE_DOMAIN} master3.${CLUSTER_NAME}.${BASE_DOMAIN}' --key ${SSH_KEY_FILE} --log-level debug${RESET_TEXT}"
    echo "${GREEN_TEXT}To run oc commands:${RESET_TEXT}"
    echo "${BLUE_TEXT}                  export  KUBECONFIG=${TEMP_DIR}/${PRODUCT_SHORT_NAME}/ocp-install/auth/kubeconfig${RESET_TEXT}"
    echo "${BLUE_TEXT}                  oc get nodes${RESET_TEXT}"
    echo "${BLUE_TEXT}                  oc get pods --all-namespaces${RESET_TEXT}"
    echo "${GREEN_TEXT}To login to the bootstrap node:${RESET_TEXT}"
    echo "${BLUE_TEXT}                  ssh -oStrictHostKeyChecking=no -i ${SSH_KEY_FILE} core@${OCP_INSTALLBOOTSTRAP_IP}${RESET_TEXT}"
    echo "${GREEN_TEXT}Once logged into the node via SSH,  you can use the following commands:${RESET_TEXT}"
    echo "${BLUE_TEXT}                  journalctl -b -u release-image.service -u bootkube.service${RESET_TEXT}"
    echo "${RED_TEXT}ERROR : ############# Bootstrap Install Not Complete ################################################${RESET_TEXT}"
    echo "Exiting Script!!!!!!!!!!!!!!!!!!!!!"
    exit 99
    echo ""
    echo ""
  fi
  export KUBECONFIG=${TEMP_DIR}/${PRODUCT_SHORT_NAME}/ocp-install/auth/kubeconfig
  echo ""
  approveADMCerts

}
runOpenShiftInstallerInstallComplete()
{
    printHeaderMessage "Run openshift-install (LOG -> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ocp-install-complete.log )"
    cd ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/ocp-install
    echo "Running openshift-install --dir=${TEMP_DIR}/${PRODUCT_SHORT_NAME}/ocp-install wait-for install-complete ${OPENSHIFT_INSTALLER_ARGS} in dir ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/ocp-install"
    unbuffer openshift-install --dir=${TEMP_DIR}/${PRODUCT_SHORT_NAME}/ocp-install wait-for install-complete ${OPENSHIFT_INSTALLER_ARGS} 2>&1 | tee ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ocp-install-complete.log
    OCP_INSTALL_COMPLETE=`cat ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ocp-install-complete.log | grep -c "Install complete"`
    if [ ${OCP_INSTALL_COMPLETE} -eq 0 ] ;then
      echo "${RED_TEXT}ERROR : ############# OCP Install Not Complete ################################################${RESET_TEXT}"
      echo "${RED_TEXT}Failed waiting for OCP Install to complete${RESET_TEXT}"
      echo "${GREEN_TEXT}To debug the install process you can use the following commands:${RESET_TEXT}"
      echo "${BLUE_TEXT}                  Install logs are here : ${TEMP_DIR}/${PRODUCT_SHORT_NAME}${RESET_TEXT}"
      echo "${BLUE_TEXT}                  ssh -oStrictHostKeyChecking=no -i ${SSH_KEY_FILE} core@master1.${CLUSTER_NAME}.${BASE_DOMAIN}${RESET_TEXT}"
      echo "${BLUE_TEXT}                  ssh -oStrictHostKeyChecking=no -i ${SSH_KEY_FILE} core@master2.${CLUSTER_NAME}.${BASE_DOMAIN}${RESET_TEXT}"
      echo "${BLUE_TEXT}                  ssh -oStrictHostKeyChecking=no -i ${SSH_KEY_FILE} core@master3.${CLUSTER_NAME}.${BASE_DOMAIN}${RESET_TEXT}"
      echo "${GREEN_TEXT}To run oc commands for troubleshooting:${RESET_TEXT}"
      echo "${BLUE_TEXT}                  export  KUBECONFIG=${TEMP_DIR}/${PRODUCT_SHORT_NAME}/ocp-install/auth/kubeconfig${RESET_TEXT}"
      echo "${BLUE_TEXT}                  oc get nodes${RESET_TEXT}"
      echo "${BLUE_TEXT}                  oc get pods --all-namespaces${RESET_TEXT}"
      echo "${BLUE_TEXT}                  oc get events -n openshift-console${RESET_TEXT}"
      echo "${GREEN_TEXT}To show wich pods are not in the ready state, you can run this command:${RESET_TEXT}"
      echo "${BLUE_TEXT}                  oc get pods --all-namespaces | grep '0\/' | grep -v Completed${RESET_TEXT}"
      echo "${RED_TEXT}ERROR : ############# OCP Install Not Complete ################################################${RESET_TEXT}"
      exit 99
      echo "Exiting Script!!!!!!!!!!!!!!!!!!!!!"
      echo ""
    fi
    enableDHCPAllCoreOS2ndInterface
    export KUBECONFIG=${TEMP_DIR}/${PRODUCT_SHORT_NAME}/ocp-install/auth/kubeconfig
    echo ""
}

savekubeconfig()
{
  mkdir -p ${OCP_KUBECONFIG_DIR}/${CLUSTER_NAME}/ignition
  cp -fR ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/ocp-install/*.ign  ${OCP_KUBECONFIG_DIR}/${CLUSTER_NAME}/ignition 2>/dev/null
  cp -fR ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/ocp-install/auth/* ${OCP_KUBECONFIG_DIR}/${CLUSTER_NAME}/
  cp -fR ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/install-config.yaml ${OCP_KUBECONFIG_DIR}/${CLUSTER_NAME}/
}

configureLocalStorge()
{
  LOCAL_STORGE_KIND_READY="NOT_READY"
  LOOP_COUNT=0
  echo ""
  while [ "${LOCAL_STORGE_KIND_READY}" != "1"  ]
  do
    let  LOOP_COUNT=LOOP_COUNT+1
    blinkWaitMessage "Waiting for Local Storage operator to be installed - wait 10 Min(${LOOP_COUNT})" 10
    LOCAL_STORGE_KIND_READY=`oc get crd | grep -c localvolumes.local.storage.openshift.io`
    if [ "${LOCAL_STORGE_KIND_READY}" == "1" ]  ;then
        cp -fR ${DIR}/templates/storage/* ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/storage/
        case ${OCP_INSTALL_TYPE} in
            kvm-upi)
                  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s|@IBM_OPENSHIFT_LOCAL_STORAGE_DEVICE_PATH@|$IBM_OPENSHIFT_LOCAL_STORAGE_DEVICE_PATH_KVM|g"
                  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s|@IBM_OPENSHIFT_LOCAL_BULK_STORAGE_DEVICE_PATH@|$IBM_OPENSHIFT_LOCAL_BULK_STORAGE_DEVICE_PATH_KVM|g"
                  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@OCP_OCS_STORAGE_CLASS_BLOCK@/$OCP_OCS_STORAGE_CLASS_BLOCK/g"
                  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@OCP_OCS_STORAGE_CLASS_FILE@/$OCP_OCS_STORAGE_CLASS_FILE/g"
                  ;;
            vsphere-upi)
                  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s|@IBM_OPENSHIFT_LOCAL_STORAGE_DEVICE_PATH@|$IBM_OPENSHIFT_LOCAL_STORAGE_DEVICE_PATH_VSPHERE|g"
                  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s|@IBM_OPENSHIFT_LOCAL_BULK_STORAGE_DEVICE_PATH@|$IBM_OPENSHIFT_LOCAL_BULK_STORAGE_DEVICE_PATH_VSPHERE|g"
                  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@OCP_OCS_STORAGE_CLASS_BLOCK@/$OCP_OCS_STORAGE_CLASS_BLOCK/g"
                  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@OCP_OCS_STORAGE_CLASS_FILE@/$OCP_OCS_STORAGE_CLASS_FILE/g"
                  ;;
        esac
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@OPEN_SHIFT_CONTAINTER_STORAGE_WORKER_NODE1@/$OPEN_SHIFT_CONTAINTER_STORAGE_WORKER_NODE1/g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@OPEN_SHIFT_CONTAINTER_STORAGE_WORKER_NODE2@/$OPEN_SHIFT_CONTAINTER_STORAGE_WORKER_NODE2/g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@OPEN_SHIFT_CONTAINTER_STORAGE_WORKER_NODE3@/$OPEN_SHIFT_CONTAINTER_STORAGE_WORKER_NODE3/g"
        oc apply -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/storage/${VM_TSHIRT_SIZE}/local.yaml
        oc apply -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/storage/${VM_TSHIRT_SIZE}/local-bulk.yaml
        echo ""
        break
    fi
    if [ $LOOP_COUNT -ge 60 ] ;then
        echo "Local Storage operator could not be installed - ${LOCAL_STORAGE_OPERATOR_STATUS}"
        echo "Once you have it running, you can run the following command to finsish the setup"
        echo "                            ${RED_TEXT} ${DATA_DIR}/${PROJECT_NAME}/${PRODUCT_SHORT_NAME}/build.sh ${ENV_FILE_NAME} --configureLocalStorge${RESET_TEXT}"
        echo ""
        break
    fi
  done
}
configureOpenShiftContainerStorageCluster()
{

  blinkWaitMessage "Waiting for Container Storage Operator to start install" 30
  CONTAINER_STORAGE_OPERATOR_STATUS="NotReady"
  LOOP_COUNT=0
  while [ "${CONTAINER_STORAGE_OPERATOR_STATUS}" != "1"  ]
  do
    let  LOOP_COUNT=LOOP_COUNT+1
    blinkWaitMessage "Waiting for Container Storage Operator to be installed - wait 5 Minutes(${LOOP_COUNT})" 10
    CONTAINER_STORAGE_OPERATOR_STATUS=`oc get crd 2>/dev/null | grep -c storageclusters.ocs.openshift.io`
    if [ "${CONTAINER_STORAGE_OPERATOR_STATUS}" == "1" ]  ;then
        echo "${BLUE_TEXT}COMPLETE ${RESET_TEXT}Container Storage Operator installed"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@VM_WORKER_DISK2@/$VM_WORKER_DISK2/g"
        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@VM_WORKER_DISK3@/$VM_WORKER_DISK3/g"
        sleep 30
        local OCS_APPLY_STORAGE_LOOP=1
        local OCS_APPLY_STORAGE_RESULT=`oc apply -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/storage/operator-container-storage-cluster.yaml`
        local OCS_APPLY_STORAGE_RESULT_ERROR=`echo ${OCS_APPLY_STORAGE_RESULT} | grep -c error`
        while [ "${OCS_APPLY_STORAGE_RESULT_ERROR}" == "1"  ]
        do
            blinkWaitMessage "Waiting for Container Storage Operator to be finish install - wait 10 seconds(${OCS_APPLY_STORAGE_LOOP})" 10
            OCS_APPLY_STORAGE_RESULT=`oc apply -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/storage/operator-container-storage-cluster.yaml`
            OCS_APPLY_STORAGE_RESULT_ERROR=`echo ${OCS_APPLY_STORAGE_RESULT} | grep -c error`
            let  OCS_APPLY_STORAGE_LOOP=OCS_APPLY_STORAGE_LOOP+1
            if [ $LOOP_COUNT -ge 18 ] ;then
                echo "${RED_TEXT}Container Storage Cluster could not be installed/timed out"
                echo "Once you OCP cluster is running, you can run the following command to finsish the setup"
                echo "oc apply -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/storage/operator-container-storage-cluster.yaml${RESET_TEXT}"
                echo ""
                break 2
            fi
        done
        if [ "${OCS_APPLY_STORAGE_RESULT_ERROR}" == "0" ]; then
            echo "${OCS_APPLY_STORAGE_RESULT}"
            echo "${BLUE_TEXT}COMPLETE ${RESET_TEXT}Container Storage Cluster installed"
        else
            echo "${OCS_APPLY_STORAGE_RESULT}"
        fi
        break
    fi
    if [ $LOOP_COUNT -ge 60 ] ;then
        echo "${RED_TEXT}Container Storage Operator could not be installed/timedout"
        echo "Once you have it running, you can run the following command to finish the setup"
        echo "${DATA_DIR}/${PROJECT_NAME}/${PRODUCT_SHORT_NAME}/build.sh ${ENV_FILE_NAME} --createOpenShiftContainerStorage ${RESET_TEXT}"
        echo ""
        break
    fi
  done

}
configureLocalStorageOperator()
{
  echo "${GREEN_TEXT}Setup new Local Storage Operator${RESET_TEXT}"
  oc apply -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/operators/openshift-local-storage/namespace.yaml
  oc apply -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/operators/openshift-local-storage/operatorgroup.yaml
  oc apply -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/operators/openshift-local-storage/subscription.yaml
}
configureOpenShiftStorageOperator()
{
  echo "${GREEN_TEXT}Setup new OpenShift Container Storage Operator${RESET_TEXT}"
  oc apply -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/operators/openshift-container-storage/namespace.yaml
  oc apply -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/operators/openshift-container-storage/operatorgroup.yaml
  #oc apply -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/operators/openshift-container-storage/subscription.yaml
  case ${OCP_BASE_VERSION} in
    4.9|4.10)
      echo "Applying OpenShift Data Foundation for ${OCP_BASE_VERSION}"
      oc apply -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/operators/openshift-container-storage/subscription-odf.yaml
      ;;
    *)
      echo "Applying OpenShift Container Storage for ${OCP_BASE_VERSION}"
      oc apply -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/operators/openshift-container-storage/subscription.yaml
      ;;
  esac
}

configureOpenShiftContainerStorage()
{
  printHeaderMessage "Configure OpenShift Container Storage"
  if [ "${VM_TSHIRT_SIZE}" == "Large" ] ;then
      configureOpenShiftStorageOperator
      case "${OCP_INSTALL_TYPE}" in
        gcp-ipi)
            oc apply -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/providers/gcp/pd-ssd.yaml
            ;;
        kvm-upi|vsphere-upi)
            configureLocalStorageOperator
            configureLocalStorge
            ;;
      esac
      labelOpenShiftContainerStorageNodes
      configureOpenShiftContainerStorageCluster
  else
    echo "Storage is only supported with Large T-Shirt Size. Will not install."
  fi
  echo ""

}
labelOpenShiftContainerStorageNodes()
{
  echo "${GREEN_TEXT}Label worker nodes for storage${RESET_TEXT}"
  NODE_LIST=`oc get nodes | grep worker | awk '{print $1}'`
  case ${OCP_INSTALL_TYPE} in
      aws-ipi|gcp-ipi|azure-ipi|vsphere-ipi)
          local workerLoop=1
          for WORKER_NODE_NAME in $NODE_LIST
          do
            oc label nodes ${WORKER_NODE_NAME} cluster.ocs.openshift.io/openshift-storage=""  --overwrite=true
            oc label nodes ${WORKER_NODE_NAME} topology.rook.io/rack=rack${workerLoop} --overwrite=true
            oc label nodes ${WORKER_NODE_NAME} node-role.kubernetes.io/infra="" --overwrite=true
            oc adm taint nodes ${WORKER_NODE_NAME} node.ocs.openshift.io/storage=true:NoSchedule --overwrite=true
            #oc label nodes ${WORKER_NODE_NAME} node-role.kubernetes.io/worker-
            let workerLoop=workerLoop+1
            if [ $workerLoop -gt 3 ]; then
              #only add disk to first three nodes.
              break
            fi
          done
          restartOpenShiftRouterPods
          ;;
      kvm-upi|vsphere-upi)
          local workerLoop=1
          for WORKER_NODE_NAME in $NODE_LIST
          do
            case ${WORKER_NODE_NAME} in
              *worker4*|*worker5*|*worker6*)
                  oc label nodes ${WORKER_NODE_NAME} cluster.ocs.openshift.io/openshift-storage=""  --overwrite=true
                  oc label nodes ${WORKER_NODE_NAME} topology.rook.io/rack=rack${workerLoop} --overwrite=true
                  oc label nodes ${WORKER_NODE_NAME} node-role.kubernetes.io/infra="" --overwrite=true
                  oc adm taint nodes ${WORKER_NODE_NAME} node.ocs.openshift.io/storage=true:NoSchedule --overwrite=true
                  #oc label nodes ${WORKER_NODE_NAME} node-role.kubernetes.io/worker-
                  let workerLoop=workerLoop+1
                  #Remove Storage Nodes from ingress-workers
                  #find /etc/haproxy/haproxy.cfg -type f | xargs sed -i'' "s/server ${WORKER_NODE_NAME}.*:443.*//g"
                  #find /etc/haproxy/haproxy.cfg -type f | xargs sed -i'' "s/server ${WORKER_NODE_NAME}.*:80.*//g"
                  ;;
            esac
          done
          if [ "${HAPROXY_BUILD}" == "true" ]; then
              sed -i '/^$/d' /etc/haproxy/haproxy.cfg
              sed -i '/^[[:space:]]*$/d' /etc/haproxy/haproxy.cfg
              systemctl restart haproxy
              restartOpenShiftRouterPods
          fi
          ;;
  esac
  echo ""
}


####################################################################################################################
# Documentation Reference:
# https://docs.openshift.com/container-platform/4.6/security/certificates/replacing-default-ingress-certificate.html
#####################################################################################################################
updateIngressCert()
{

  if [ -z "${CERT_API_KEY}" ] || [ -z "${CERT_ID}" ];then
    #echo "CERT_API_KEY or CERT_ID not set, will not Update Ingress Cert"
    SKIP_INGRESS_DNS_CERTS=true
  else
      printHeaderMessage "Update ingress Certs"
      #We need php installed, check if this is installed
      FOUND_PHP_COMMAND=`which php | grep -c "php"`
      if [ ${OS_NAME} = "Linux" ];then
        if [ ${FOUND_PHP_COMMAND} = "0" ];then
            echo "PHP needed for cert processing, Installing PHP now ......."
            ${OS_INSTALL} install php -y > /dev/null 2>&1
        fi
      else
        if [ ${FOUND_PHP_COMMAND} = "0" ];then
            echo "${RED_TEXT}Please install php in order to use custom SSL Certs!!!!!!"
            exit 99
        fi
      fi
      getNewCerts
      if [ -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/tls.crt ] && [ -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/tls.key ] ;then
          ${OCP_KUBCONFIG}
          echo "Installing CA Cert - ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/certificates/${OCP_TRUSTE_CA_FILE}"
          MY_OCP_TRUSTE_CA=${TEMP_DIR}/${PRODUCT_SHORT_NAME}/certificates/${OCP_TRUSTE_CA_FILE}
          MY_OCP_SECRET_NAME=${CLUSTER_NAME}.${BASE_DOMAIN}
          MY_OCP_CERT=${TEMP_DIR}/${PRODUCT_SHORT_NAME}/tls.crt
          MY_OCP_CERT_KEY=${TEMP_DIR}/${PRODUCT_SHORT_NAME}/tls.key
          oc delete configmap ${OCP_TRUSTE_CA_NAME} -n openshift-config  2> /dev/null
          oc create configmap ${OCP_TRUSTE_CA_NAME} --from-file=ca-bundle.crt=${MY_OCP_TRUSTE_CA} -n openshift-config

          # Updated by Dave Krier
          oc patch proxy/cluster --type=merge --patch='{"spec":{"trustedCA":{"name":"'${OCP_TRUSTE_CA_NAME}'"}}}'

          oc delete secret ${MY_OCP_SECRET_NAME} -n openshift-ingress  2> /dev/null
          oc create secret tls ${MY_OCP_SECRET_NAME} --cert=${MY_OCP_CERT} --key=${MY_OCP_CERT_KEY}  -n openshift-ingress

          # Updated by Dave Krier
          oc patch ingresscontroller.operator default --type=merge -p  '{"spec":{"defaultCertificate": {"name": "'${MY_OCP_SECRET_NAME}'"}}}' -n openshift-ingress-operator

      else
          echo "${RED_TEXT} Missing cert files, will not update Ingrees Cert: ${RESET_TEXT}"
          echo "${RED_TEXT}       ${MY_OCP_TRUSTE_CA} ${RESET_TEXT}"
          echo "${RED_TEXT}       ${MY_OCP_CERT} ${RESET_TEXT}"
          echo "${RED_TEXT}       ${MY_OCP_CERT} ${RESET_TEXT}"
          echo "${RED_TEXT}        ${MY_OCP_CERT_KEY} ${RESET_TEXT}"
      fi
      echo ""
  fi
}

ocpCreateAdminAccount()
{
  printHeaderMessage "Create OAuth -  Local Admin user via htpasswd"
  mkdir -p ${OCP_KUBECONFIG_DIR}/${CLUSTER_NAME}
  OCP_LOCAL_ADMIN_PASSWORD=`tr -dc A-Za-z0-9 </dev/urandom | head -c 20 ; echo ''`
  htpasswd -bBc ${OCP_KUBECONFIG_DIR}/${CLUSTER_NAME}/oauth.htpasswd ${OCP_LOCAL_ADMIN} ${OCP_LOCAL_ADMIN_PASSWORD}
  rm -fr  ${OCP_KUBECONFIG_DIR}/${CLUSTER_NAME}/${OCP_LOCAL_ADMIN}-password &> /dev/null
  echo "${OCP_LOCAL_ADMIN_PASSWORD}" > ${OCP_KUBECONFIG_DIR}/${CLUSTER_NAME}/${OCP_LOCAL_ADMIN}-password
  oc adm policy add-cluster-role-to-user cluster-admin ${OCP_LOCAL_ADMIN} --rolebinding-name=cluster-admin 2> /dev/null
  oc create secret generic htpasswd-secret --from-file=htpasswd=${OCP_KUBECONFIG_DIR}/${CLUSTER_NAME}/oauth.htpasswd -n openshift-config
  oc apply -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/security/htpasswd.yaml 2> /dev/null
  echo ""
}

restartOpenShiftRouterPods()
{
    echo "Restart OpenShift Router Pods to move to worker nodes if on new infra nodes."
    local PODS=`oc get pods -n openshift-ingress |  awk '{print $1 }' | grep -v NAME`
		for POD in $PODS
    do
			oc delete pod -n openshift-ingress $POD &> /dev/null &
      sleep 5
	  done
}
getCustomOpenShiftInstaller()
{
  if [ -n "${OCP_CUSTOM_OPENSHIFT_INSTALLER_URL}"  ]; then
      printHeaderMessage "Install Custom openshift-install (LOG ${LOG_DIR}/${PRODUCT_SHORT_NAME}/openshift-install-custom.log)"
      cd ${TEMP_DIR}/${PRODUCT_SHORT_NAME}
      echo "wget ${OCP_CUSTOM_OPENSHIFT_INSTALLER_URL}"
      wget -O openshift-install-linux.tar.gz ${OCP_CUSTOM_OPENSHIFT_INSTALLER_URL} 2> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/openshift-install-custom.log
      if [ ! -f  openshift-install-linux.tar.gz ]; then
        echo "${RED_TEXT}FAILED ${RESET_TEXT} to download custom openshift-install, unable to continue."
        echo "Exiting Script!!!!!!!!!!!!!!!!!!!!!"
        exit 99
      fi
      rm -fR /usr/local/bin/openshift-install 2>&1 > /dev/null
      tar xvf openshift-install-linux.tar.gz 2>&1 >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/openshift-install-custom.log
      if [ ! -f openshift-install ]; then
        echo "${RED_TEXT}FAILED ${RESET_TEXT} to extract custom openshift-install, unable to continue."
        echo "Exiting Script!!!!!!!!!!!!!!!!!!!!!"
        exit 99
      fi
      mv openshift-install /usr/local/bin/
      rm -rf openshift-install-linux.tar.gz README.md
      echo "${BLUE_TEXT}COMPLETE ${RESET_TEXT} Installed custom openshift-install"
      openshift-install version
  fi
}
