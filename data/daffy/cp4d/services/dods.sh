############################################################
#Author           : Dave Krier
#Author email     : dakrier@us.ibm.com
#Original Date    : 2022-03-28
#Initial Version  : v2022-03-28
############################################################
#Setup Variables
############################################################
#https://www.ibm.com/docs/en/cloud-paks/cp-data/4.0
#https://www.ibm.com/docs/en/cloud-paks/cp-data/4.0?topic=tasks-creating-operator-subscriptions

cp4dServiceDODS()
{
  local CONTINUE_SERVICE_INSTALL=true
  if [ "${1}" = "delete" ]; then
    printHeaderMessage "Cloud Pak for Data Service - Decision Optimization" ${RED_TEXT}
  else
    printHeaderMessage "Cloud Pak for Data Service - Decision Optimization"
  fi
  if [ "${CP4D_ENABLE_SERVICE_DODS}" == "true" ]; then
      if [ ${1} == "apply" ]; then
            echo "Enabling Subscriptions"
            cp4dServiceDODSCaseSetup
            if [ "${CONTINUE_SERVICE_INSTALL}" == "true" ]; then
                oc apply -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/subscriptions/ibm-cpd-dods-operator-catalog-subscription/subscription.yaml
                let  LOOP_COUNT=1
                DODS_KIND_READY="NOT_READY"
                while [ "${DODS_KIND_READY}" != "1"  ]
                do
                      blinkWaitMessage "Waiting for Decision Optimization Operator to be installed before we create instance" 10
                      DODS_KIND_READY=`oc get csv -n ${CP4D_OPERATORS_NAMESPACE} | grep -c ibm-cpd-dods`
                      if [ "${DODS_KIND_READY}" == "1" ]  ;then
                              echo "${BLUE_TEXT}COMPLETE ${RESET_TEXT} Decision Optimization Operator installed"
                              oc ${1} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/customresource/dods.yaml
                              echo ""
                              echo "Your request to install the service has been submitted.  It can take up to 3 hours!"
                              echo "You can check status via this command: "
                              echo "            ${DATA_DIR}/${PROJECT_NAME}/${PRODUCT_SHORT_NAME}/service.sh  ${ENV_FILE_NAME} --DODSStatus"
                              echo ""
                      fi
                      if [ $LOOP_COUNT -ge 60 ] ;then
                          echo "IBM Decision Optimization instance could not be installed"
                          echo "After some time, you can run the following command to finsish the setup"
                          echo "                           ${RED_TEXT}oc ${1} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/customresource/dods.yaml${RESET_TEXT}"
                          echo ""
                          break
                      fi
                      let LOOP_COUNT=LOOP_COUNT+1
                done
            fi
      else
        if [ ${1} == "delete" ]; then
              echo "Removing Operand Request"
              oc delete operandrequest dods-requests-ccs -n ${CP4D_INSTANCE_NAMESPACE} 2> /dev/null
              oc delete operandrequest dods-requests-ws -n ${CP4D_INSTANCE_NAMESPACE} 2> /dev/null
              echo ""
              echo "Removing Custom Resource"
              oc patch dods dods -n ${CP4D_INSTANCE_NAMESPACE} -p '{"metadata":{"finalizers":[]}}' --type=merge  2> /dev/null
              oc delete --grace-period=0 --force --ignore-not-found=true --include-uninitialized=true --timeout=30s -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/customresource/dods.yaml 2> /dev/null
              oc delete crd dods.cpd.ibm.com 2> /dev/null  # Check this.. Not sure I got the name right.
              echo ""
              echo "Removing Service"
              oc delete dods dods -n ${CP4D_INSTANCE_NAMESPACE} 2> /dev/null
              echo ""
              echo "Removing Subscriptions"
              oc delete -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/subscriptions/ibm-cpd-dods-operator-catalog-subscription/subscription.yaml 2> /dev/null
              echo ""
              echo "Removing Cluster Service Version"
              oc delete csv ibm-cpd-dods.v${CP4D_CASE_DODS_VERSION} -n ${CP4D_OPERATORS_NAMESPACE} 2> /dev/null

        fi
      fi
  fi
  echo ""
}

cp4dServiceDODSCaseSetup()
{
  if [ ${CP4D_CLOUDCTL_CASE_BUILD_OUT} = "true" ]; then
    echo "Downloading Decison Optimization Catalog Case version ${CP4D_CASE_DODS_VERSION}  (LOG ->  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ibm-dods-save.log)"
    cloudctl case save \
    --repo ${CASE_REPO_PATH} \
    --case ibm-dods \
    --version ${CP4D_CASE_DODS_VERSION} \
    --outputdir ${CASE_REPO_OFFLINE_DIR} &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ibm-dods-save.log

    echo "Installing Decison Optimization Catalog Case version ${CP4D_CASE_DODS_VERSION}   (LOG ->  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ibm-dods-launch.log)"
    cloudctl case launch \
      --case ${CASE_REPO_OFFLINE_DIR}/ibm-dods-${CP4D_CASE_DODS_VERSION}.tgz \
      --inventory dodsOperatorSetup \
      --namespace openshift-marketplace \
      --action install-catalog \
        --args "--inputDir ${CASE_REPO_OFFLINE_DIR} --recursive " &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ibm-dods-launch.log
    echo "${BLUE_TEXT}COMPLETE ${RESET_TEXT}cloudclt Launch command finished"
    echo ""
    local DODS_CATALOG_READY=`oc get catalogsource -n openshift-marketplace ibm-cpd-dods-operator-catalog -o jsonpath='{.status.connectionState.lastObservedState} {"\n"}' 2> /dev/null | sed 's/ *$//g'`
    let  LOOP_COUNT=1
    while [ "${DODS_CATALOG_READY}" != "READY"  ]
    do
        blinkWaitMessage "Waiting for Decision Optimization to be ready.    " 60
        DODS_CATALOG_READY=`oc get catalogsource -n openshift-marketplace ibm-cpd-dods-operator-catalog -o jsonpath='{.status.connectionState.lastObservedState} {"\n"}' 2> /dev/null | sed 's/ *$//g'`
        let LOOP_COUNT=LOOP_COUNT+1
        if [ $LOOP_COUNT -ge 10 ] ;then
            echo "${RED_TEXT}FAILED: Decision Optimization could not be installed${RESET_TEXT}"
            echo ""
            CONTINUE_SERVICE_INSTALL=false
            break
        fi
    done
    echo "${BLUE_TEXT}COMPLETE ${RESET_TEXT}Successfully installed Decision Optimization catalog"
  fi
}


cp4dServiceDODSStatus()
{
  printHeaderMessage "Cloud Pak for Data Service - Decision Optimization"
  validateCP4DVersion &>/dev/null
  echo "Daffy Version                     :  ${DAFFY_VERSION}"
  echo "Bastion OS                        :  ${OS_FLAVOR}"
  echo "Platform Install Type             :  ${OCP_INSTALL_TYPE}"
  echo "OpenShift Version                 :  ${OCP_SERVER_VERSION}"
  echo "Zen Version                       :  ${CP4D_ZEN_VERSION}"

  local DODS_CR_STATUS=`oc get DODS dods-cr -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.status.dodsStatus} {"\n"}' 2> /dev/null | sed 's/ *$//g'`
  local DODS_CR_VERSION=`oc get DODS dods-cr -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.spec.version} {"\n"}' 2> /dev/null`
  if [ -z ${DODS_CR_STATUS} ]; then
    DODS_CR_STATUS="Not Found"
  fi
  echo "Decision Optimization             :  ${DODS_CR_STATUS} - ${DODS_CR_VERSION}"

  local CP4D_WS_STATUS=`oc get WS ws-cr -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.status.wsStatus}' 2> /dev/null | sed 's/ *$//g'`
  local CP4D_WS_VERSION=`oc get WS ws-cr -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.spec.version} {"\n"}' 2> /dev/null`
  if [ -z "${CP4D_WS_STATUS}" ]; then
    CP4D_WS_STATUS="Not Found"
  fi
  if [ -z "${CP4D_WS_VERSION}" ]; then
      CP4D_WS_VERSION=""
  fi
  echo "     Watson Studio Version        :  ${CP4D_WS_STATUS} - ${CP4D_WS_VERSION}"

  local WML_VERSION=`oc get WmlBase wml-cr -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.spec.version}' 2> /dev/null`
  local WML_CR_STATUS=`oc get WmlBase wml-cr -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.status.wmlStatus} {"\n"}' 2> /dev/null | sed 's/ *$//g'`
  if [ -z ${WML_CR_STATUS} ]; then
    WML_CR_STATUS="Not Found"
  fi
  echo "     Watson Machine Learning      :  ${WML_CR_STATUS} - ${WML_VERSION}"

  local DODS_CCS_STATUS=`oc get CCS ccs-cr -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.status.ccsStatus} {"\n"}' 2> /dev/null | sed 's/ *$//g'`
  local DODS_CCS_VERSION=`oc get CCS ccs-cr -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.status.versions.reconciled} {"\n"}' 2> /dev/null`
  if [ -z ${DODS_CCS_STATUS} ]; then
    DODS_CCS_STATUS="Not Found"
  fi
  echo "     Common Core Services Module  :  ${DODS_CCS_STATUS} - ${DODS_CCS_VERSION}"

  echo ""
  #echo "Pods: managed-by=ibm-cpd-dods-operator "
  #oc get pods -A -l 'app.kubernetes.io/managed-by=ibm-cpd-dods-operator'
  #echo ""
  echo "Pods: managed-by=ibm-dods "
  oc get pods -A -l 'app.kubernetes.io/managed-by=ibm-dods'
  echo ""
}
