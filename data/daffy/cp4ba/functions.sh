#!/bin/bash
############################################################
#Author           : Kyle Dawson
#Author email     : Kyle.Dawson@us.ibm.com
#Original Date    : 2022-01-11
#Initial Version  : v2022-02-15
############################################################
validateCP4BAVersion()
{
  case ${CP4BA_VERSION} in
    21.0.3)
        echo "${BLUE_TEXT}PASSED ${RESET_TEXT} Valid version CPBA_VERSION=${CP4BA_VERSION}"
        ;;
     *)
       echo "${RED_TEXT}FAILED ${RESET_TEXT} Invalid version CPBA_VERSION=${CPBA_VERSION}${RESET_TEXT}"
       echo "${RED_TEXT}Current Supported Versions 21.0.3${RESET_TEXT}"
       SHOULD_EXIT=1
       ;;
  esac
if [ ! -z  "${CP4BA_IFIX}" ]; then
     case ${CP4BA_IFIX} in
      IF005|IF007|IF008)
          echo "${BLUE_TEXT}PASSED ${RESET_TEXT} Valid IFIX CP4BA_IFIX=${CP4BA_IFIX}"
          ;;
      *)
          echo "${RED_TEXT}FAILED ${RESET_TEXT} Invalid IFIX CP4BA_IFIX=${CP4BA_IFIX}${RESET_TEXT}"
          echo "Current Supported IFIX - IF005, IF007 or IF008"
          SHOULD_EXIT=1
          ;;
     esac
  fi
  OCP_SERVER_VERSION=`oc version 2> /dev/null| grep Server | awk '{print $3}'`
  if [ -z ${OCP_SERVER_VERSION} ]; then
    OCP_SERVER_VERSION="Not Found"
  fi
  CP4BA_ZEN_VERSION=`timeout 30 oc get ZenService  iaf-zen-cpdservice -n ${CP4BA_AUTO_NAMESPACE} -o jsonpath='{.status.currentVersion} {"\n"}' 2> /dev/null`
  if [ -z ${CP4BA_ZEN_VERSION} ]; then
    CP4BA_ZEN_VERSION="Not Found"
  fi
}
precheckCP4BA()
{
  printHeaderMessage "PreCheck"
  baseValidation
  prepareHost
  cp4baValidateService
  getIBMEntitlementKey
  getOpenShiftTools
  variablePresent ${CP4BA_VERSION} CP4BA_VERSION
  directoryPresent ${DATA_DIR}/${PROJECT_NAME}/db2/jdbc
  validateCP4BAVersion
  case ${OCP_INSTALL_TYPE} in
    roks-msp)
      waitForROKSClusterReady
  esac
  validateOCPAccess
  validateCloudPakSize
  case ${OCP_INSTALL_TYPE} in
    roks-msp)
        validateStorage ${CP4BA_AUTO_STORAGE_CLASS_FAST_ROKS}

        ;;
    *)
        validateStorage ${CP4BA_AUTO_STORAGE_CLASS_OCP}

        ;;
  esac

  installPodman
  shouldExit
  echo ""
  echo "All prechecks passed, lets get to work."
  echo ""

}
prepareCP4BAInputFiles()
{
  printHeaderMessage "Prepare Input Files"
  #rm -fR ${TEMP_DIR}/${PRODUCT_SHORT_NAME} 2>/dev/null
  mkdir -p ${TEMP_DIR}/${PRODUCT_SHORT_NAME}
  rm -fR ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/ops/tmp 2>/dev/null
  cd ${TEMP_DIR}/${PRODUCT_SHORT_NAME}
  cp -fR ${DIR}/templates/* ${TEMP_DIR}/${PRODUCT_SHORT_NAME}
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@CP4BA_VERSION@/$CP4BA_VERSION/g"



}
cp4baClusterAdminSetup()
{
  printHeaderMessage "Cluster Admin setup (LOG -> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/cp4a-clusteradmin-setup.log)"
  cd ${TEMP_DIR}/${PRODUCT_SHORT_NAME}
  echo "wget ${CASE_REPO_PATH}/ibm-cp-automation-${CP4BA_CASE_VERSION}.tgz"
  wget ${CASE_REPO_PATH}/ibm-cp-automation-${CP4BA_CASE_VERSION}.tgz &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/wget-ibm-cp-automation.log
  tar -xvzf ibm-cp-automation-${CP4BA_CASE_VERSION}.tgz &>> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ibm-cp-automation-${CP4BA_CASE_VERSION}.log
  rm -fR ibm-cp-automation-${CP4BA_CASE_VERSION}.tgz &> /dev/null
  mv ibm-cp-automation/inventory/cp4aOperatorSdk/files/deploy/crs/cert-k8s-${CP4BA_VERSION}.tar . &>> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ibm-cp-automation-${CP4BA_CASE_VERSION}.log
  tar -xvzf cert-k8s-${CP4BA_VERSION}.tar &>  /dev/null
  rm -fR cert-k8s-${CP4BA_VERSION}.tar &>> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ibm-cp-automation-${CP4BA_CASE_VERSION}.log
  cp4baValidateOCUser
  echo "Running ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/cert-kubernetes/scripts/cp4a-clusteradmin-setup.sh"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | grep cp4a-clusteradmin-setup.sh| xargs sed -i'' "s/clear/echo ''/g"
  #This will prevent the prompt to ask to install into more then one namespace as we always want that
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | grep cp4a-clusteradmin-setup.sh| xargs sed -i'' 's/                read -rp "" ans/                echo "Yes" | read -rp "" ans/g'
  OCP_LOCAL_ADMIN=`oc whoami 2> /dev/null`
  export CP4BA_AUTO_STORAGE_CLASS_FAST_ROKS=${CP4BA_AUTO_STORAGE_CLASS_FAST_ROKS}
  export CP4BA_AUTO_STORAGE_CLASS_OCP=${CP4BA_AUTO_STORAGE_CLASS_OCP}
  export CP4BA_AUTO_PLATFORM=${CP4BA_AUTO_PLATFORM}
  export CP4BA_AUTO_DEPLOYMENT_TYPE=${CP4BA_AUTO_DEPLOYMENT_TYPE}
  export CP4BA_AUTO_NAMESPACE=${CP4BA_AUTO_NAMESPACE}
  export CP4BA_AUTO_ALL_NAMESPACES=${CP4BA_AUTO_ALL_NAMESPACES}
  export CP4BA_AUTO_CLUSTER_USER=${OCP_LOCAL_ADMIN}
  export CP4BA_AUTO_ENTITLEMENT_KEY="${IBM_ENTITLEMENT_KEY}"

  if [ "${CP4BA_DEBUG}" == "true" ]; then
    ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/cert-kubernetes/scripts/cp4a-clusteradmin-setup.sh | tee ${LOG_DIR}/${PRODUCT_SHORT_NAME}/cp4a-clusteradmin-setup.log
  else
    ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/cert-kubernetes/scripts/cp4a-clusteradmin-setup.sh 2>&1 | tee ${LOG_DIR}/${PRODUCT_SHORT_NAME}/cp4a-clusteradmin-setup.log  | grep "created\|Created\|updated\|updated\|Adding\|valid\|Login\|unchanged\|Applying"
  fi
  local CLUSTER_ADMIN_SETUP_ERRORS=`cat ${LOG_DIR}/${PRODUCT_SHORT_NAME}/cp4a-clusteradmin-setup.log | grep -A1 "Failed\|failed\|Error\|error\|Exit...\|exit..."`
  if [ -n  "${CLUSTER_ADMIN_SETUP_ERRORS}"  ]; then
    echo "${RED_TEXT}${CLUSTER_ADMIN_SETUP_ERRORS}${RESET_TEXT}"
    local PV_ERROR_COUNT=`echo ${CLUSTER_ADMIN_SETUP_ERRORS} | grep -c "Failed to allocate the persistent volumes" `
    if [  ${PV_ERROR_COUNT} -ge 1 ]; then
        if [[ ${OCP_INSTALL_TYPE} == "roks-msp" ]]; then
            echo "${RED_TEXT}FAILED  ${RESET_TEXT}To create PVC but this can be normal in ROKS. Wait some time and rerun command"
        fi
    else
      echo "${RED_TEXT}FAILED  ${RESET_TEXT}Some error occured, please check the log file for more details - cp4a-clusteradmin-setup.log"
    fi
  else
      echo "New project ${CP4BA_AUTO_NAMESPACE} has been setup for CP4BA in your cluster"
  fi
  echo ""

  applyNameSpaceLabels ${CP4BA_AUTO_NAMESPACE} 'IBM Cloud Pak for Business Automation'
  applyNameSpaceLabels ibm-common-services 'IBM Common Services'

  oc apply -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/security/service-account-for-anyuid.yaml -n ${CP4BA_AUTO_NAMESPACE}
  oc adm policy add-scc-to-user anyuid -z ibm-cp4ba-anyuid -n ${CP4BA_AUTO_NAMESPACE}

}

cp4baCopyJDBCFilesToPod()
{
  printHeaderMessage "Copy JDBC Files to ibm-cp4a-operator Pod"
  echo ""
  blinkWaitMessage "Waiting 30 seconds for ibm-cp4a-operator pod to be ready" 30
  local CP4BA_OPERATOR_POD_NAME=$(oc get pod -n ${CP4BA_AUTO_NAMESPACE} 2> /dev/null | grep ibm-cp4a-operator | awk '{print $1}')
  if [ -z  ${CP4BA_OPERATOR_POD_NAME}  ]; then
    echo "${RED_TEXT}FAILED ${RESET_TEXT} Unable to find the ibm-cp4a-operator pod to copy JDBC jars to."
  else
      kubectl cp ${DATA_DIR}/${PROJECT_NAME}/db2/jdbc ${CP4BA_AUTO_NAMESPACE}/${CP4BA_OPERATOR_POD_NAME}:/opt/ansible/share  > ${LOG_DIR}/${PRODUCT_SHORT_NAME}/copy-jdbc.log  2>&1
      local COPY_RESULT_ERROR=`cat ${LOG_DIR}/${PRODUCT_SHORT_NAME}/copy-jdbc.log | grep -c "error\|Error"`
      echo ""
      if [  ${COPY_RESULT_ERROR} -ge 1  ]; then
        blinkWaitMessage "Unable to copy jars, waiting 2 minute before we try again" 120
        kubectl cp ${DATA_DIR}/${PROJECT_NAME}/db2/jdbc ${CP4BA_AUTO_NAMESPACE}/${CP4BA_OPERATOR_POD_NAME}:/opt/ansible/share  > ${LOG_DIR}/${PRODUCT_SHORT_NAME}/copy-jdbc.log  2>&1
        local COPY_RESULT_ERROR=`cat ${LOG_DIR}/${PRODUCT_SHORT_NAME}/copy-jdbc.log | grep -c "error\|Error"`
        if [  ${COPY_RESULT_ERROR} -ge 1  ]; then
              echo "${RED_TEXT}FAILED ${RESET_TEXT} Unable to copied JDBC files -> ${DATA_DIR}/${PROJECT_NAME}/db2/jdbc ${CP4BA_AUTO_NAMESPACE}/$CP4BA_OPERATOR_POD_NAME:/opt/ansible/share"
              echo "Run this command latter to copy JDBC Jars:"
              echo "kubectl cp ${DATA_DIR}/${PROJECT_NAME}/db2/jdbc ${CP4BA_AUTO_NAMESPACE}/$CP4BA_OPERATOR_POD_NAME:/opt/ansible/share"
              echo ""
            fi
      else
        echo "Successfully copied JDBC files -> ${DATA_DIR}/${PROJECT_NAME}/db2/jdbc ${CP4BA_AUTO_NAMESPACE}/$CP4BA_OPERATOR_POD_NAME:/opt/ansible/share"
      fi
  fi
  echo ""
}
cp4baConsole()
{
    printHeaderMessage "Cloud Pak For Business Automation Console Info"
    echo "Not Implemented Yet!"

}
cp4baValidateService()
{
  if [ -n "${CP4BA_DEPLOYMENT_STARTER_SERVICE}" ]; then
    case ${CP4BA_DEPLOYMENT_STARTER_SERVICE} in
          samples|workflow|content-decisions|content|decisions)
          echo "${BLUE_TEXT}PASSED ${RESET_TEXT} Valid Starter Service of ${CP4BA_DEPLOYMENT_STARTER_SERVICE}"
          ;;
      *)
          SHOULD_EXIT=1
          echo "${RED_TEXT}FAILED ${RESET_TEXT} Invalid Starter Service of ${CP4BA_DEPLOYMENT_STARTER_SERVICE}"
          echo "Supported Servicess : samples | workflow | content-decisions | content | decisions"
          ;;
    esac
  else
    echo "${BLUE_TEXT}PASSED ${RESET_TEXT} Optional Starter Service not selected"
  fi
}


cp4baValidateOCUser()
{
  case ${OCP_INSTALL_TYPE} in
    roks-msp)
        local OC_USER_NAME=`oc whoami`
        if [  ${OC_USER_NAME} == "system:admin"  ]; then
            echo "Please login to your cluster console and copy/paste the oc admin login command below:"
            local OCP_CONSOLE=`ibmcloud oc cluster config --cluster ${CLUSTER_NAME} --output yaml 2> /dev/null| grep server: |  awk '{print $2}'`
            echo "${BLUE_TEXT}${OCP_CONSOLE}${RESET_TEXT}"
            read -p "" OC_ADMIN_TOKEN_COMMAND
            ${OC_ADMIN_TOKEN_COMMAND}
            OCP_LOCAL_ADMIN=`oc whoami 2> /dev/null`
            cp4baValidateOCUser
        fi
        ;;
  esac
}
cp4baListSamples()
{
      printHeaderMessage "List all avaiable CP4BA Sample Deployment Custom Resources(CR)"
      echo "${DIR}/templates/services/samples ---->"
      ls  ${DIR}/templates/services/samples/*.yaml |  sed 's/.yaml//g' | sed 's/.*\///g'

}
