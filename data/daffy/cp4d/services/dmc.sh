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

cp4dServiceDMC()
{
  local CONTINUE_SERVICE_INSTALL=true
  if [ "${1}" = "delete" ]; then
    printHeaderMessage "Cloud Pak for Data Service - DB2 Management Console" ${RED_TEXT}
  else
    printHeaderMessage "Cloud Pak for Data Service - DB2 Management Console"
  fi
  if [ "${CP4D_ENABLE_SERVICE_DMC}" == "true" ]; then
      if [ ${1} == "apply" ]; then
            echo "Enabling Subscriptions"
            cp4dServiceDMCCaseSetup
            if [ "${CONTINUE_SERVICE_INSTALL}" == "true" ]; then
                DMC_KIND_EXIST_ALREAY=`oc get sub -n ${CP4D_OPERATORS_NAMESPACE} | grep -c ibm-databases-dmc-operator-subscription`
                if [ ${DMC_KIND_EXIST_ALREAY} -eq 0 ]; then
                    oc apply -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/subscriptions/ibm-cpd-dmc-operator-catalog-subscription/subscription.yaml
                else
                    echo "${BLUE_TEXT}INFO ${RESET_TEXT} Looks like DB2 Management Console Operator subscription already exist."
                fi
                let  LOOP_COUNT=1
                DMC_KIND_READY="NOT_READY"
                while [ "${DMC_KIND_READY}" != "1"  ]
                do
                      blinkWaitMessage "Waiting for DB2 Management Console Operator Subscription to be installed before we create instance" 10
                      #DMC_KIND_READY=`oc get sub -n ${CP4D_OPERATORS_NAMESPACE} ibm-cpd-dmc-operator-catalog-subscription -o jsonpath='{.status.installedCSV} {"\n"}'`
                      DMC_KIND_READY=`oc get csv -n ${CP4D_OPERATORS_NAMESPACE} | grep -c ibm-databases-dmc`
                      if [ "${DMC_KIND_READY}" == "1" ]  ;then
                              echo "${BLUE_TEXT}COMPLETE ${RESET_TEXT} DB2 Management Console Operator installed"
                              oc ${1} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/customresource/dmc.yaml
                              echo ""
                              echo "Your request to install the service has been submitted.  It can take up to 30 min or more"
                              echo "You can check status via this command: "
                              echo "            ${DATA_DIR}/${PROJECT_NAME}/${PRODUCT_SHORT_NAME}/service.sh  ${ENV_FILE_NAME} --DMCStatus"
                              echo ""
                      fi
                      if [ $LOOP_COUNT -ge 60 ] ;then
                          echo "IBM DB2 Management Console instance could not be installed"
                          echo "After some time, you can run the following command to finsish the setup"
                          echo "                           ${RED_TEXT}oc ${1} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/customresource/dmc.yaml${RESET_TEXT}"
                          echo ""
                          break
                      fi
                      let LOOP_COUNT=LOOP_COUNT+1
                done
            fi
      else
        if [ ${1} == "delete" ]; then
              echo "Removing Operand Request"
              oc delete operandrequest dmc-requests-ccs -n ${CP4D_INSTANCE_NAMESPACE} 2> /dev/null
              oc delete operandrequest dmc-requests-ws -n ${CP4D_INSTANCE_NAMESPACE} 2> /dev/null
              echo ""
              echo "Removing Custom Resource"
              oc patch dmc dmc -n ${CP4D_INSTANCE_NAMESPACE} -p '{"metadata":{"finalizers":[]}}' --type=merge  2> /dev/null
              oc delete --grace-period=0 --force --ignore-not-found=true --include-uninitialized=true --timeout=30s -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/customresource/dmc.yaml 2> /dev/null
              oc delete crd dmc.cpd.ibm.com 2> /dev/null  # Check this.. Not sure I got the name right.
              echo ""
              echo "Removing Service"
              oc delete dmc dmc -n ${CP4D_INSTANCE_NAMESPACE} 2> /dev/null
              echo ""
              echo "Removing Subscriptions"
              oc delete -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/subscriptions/ibm-cpd-dmc-operator-catalog-subscription/subscription.yaml 2> /dev/null
              echo ""
              echo "Removing Cluster Service Version"
              oc delete csv ibm-cpd-dmc.v${CP4D_CASE_DMC_VERSION} -n ${CP4D_OPERATORS_NAMESPACE} 2> /dev/null

        fi
      fi
  fi
  echo ""
}

cp4dServiceDMCCaseSetup()
{
  if [ ${CP4D_CLOUDCTL_CASE_BUILD_OUT} = "true" ]; then
    echo "Downloading DB2 Data Management Console Catalog Case version ${CP4D_CASE_DMC_VERSION}  (LOG ->  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ibm-dmc-save.log)"
    cloudctl case save \
    --repo ${CASE_REPO_PATH} \
    --case ibm-dmc \
    --version ${CP4D_CASE_DMC_VERSION} \
    --outputdir ${CASE_REPO_OFFLINE_DIR} &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ibm-dmc-save.log

    echo "Installing DB2 Data Management Console Case version ${CP4D_CASE_DMC_VERSION}   (LOG ->  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ibm-dmc-launch.log)"
    cloudctl case launch \
      --case ${CASE_REPO_OFFLINE_DIR}/ibm-dmc-${CP4D_CASE_DMC_VERSION}.tgz \
      --inventory dmcOperatorSetup \
      --namespace openshift-marketplace \
      --action install-catalog \
        --args "--inputDir ${CASE_REPO_OFFLINE_DIR} --recursive " &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ibm-dmc-launch.log
    echo "${BLUE_TEXT}COMPLETE ${RESET_TEXT}cloudctl Launch command finished"
    echo ""
    local DMC_CATALOG_READY=`oc get catalogsource -n openshift-marketplace ibm-dmc-operator-catalog -o jsonpath='{.status.connectionState.lastObservedState} {"\n"}' 2> /dev/null | sed 's/ *$//g'`
    let  LOOP_COUNT=1
    while [ "${DMC_CATALOG_READY}" != "READY"  ]
    do
        blinkWaitMessage "Waiting for DB2 Management Console Catalog to be ready.    " 60
        DMC_CATALOG_READY=`oc get catalogsource -n openshift-marketplace ibm-dmc-operator-catalog -o jsonpath='{.status.connectionState.lastObservedState} {"\n"}' 2> /dev/null | sed 's/ *$//g'`
        let LOOP_COUNT=LOOP_COUNT+1
        if [ $LOOP_COUNT -ge 10 ] ;then
            echo "${RED_TEXT}FAILED ${RESET_TEXT} DB2 Management Console Catalog could not be installed"
            echo ""
            CONTINUE_SERVICE_INSTALL=false
            break
        fi
    done
    if [ "${DMC_CATALOG_READY}" ==  "READY" ]; then
        echo "${BLUE_TEXT}COMPLETE ${RESET_TEXT}Successfully installed DB2 Managment Console catalog subscription"
    fi
  fi
}

cp4dServiceDMCStatus()
{
  printHeaderMessage "Cloud Pak for Data Service - DB2 Management Console"
  validateCP4DVersion &>/dev/null
  echo "Daffy Version                     :  ${DAFFY_VERSION}"
  echo "Bastion OS                        :  ${OS_FLAVOR}"
  echo "Platform Install Type             :  ${OCP_INSTALL_TYPE}"
  echo "OpenShift Version                 :  ${OCP_SERVER_VERSION}"
  echo "Zen Version                       :  ${CP4D_ZEN_VERSION}"

  local DMC_CR_STATUS=`oc get Dmcaddon dmc-cr -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.status.dmcAddonStatus} {"\n"}' 2> /dev/null | sed 's/ *$//g'`
  local DMC_CR_VERSION=`oc get Dmcaddon dmc-cr -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.spec.version} {"\n"}' 2> /dev/null`
  if [ -z ${DMC_CR_STATUS} ]; then
    DMC_CR_STATUS="Not Found"
  fi
  echo "DB2 Management Console            :  ${DMC_CR_STATUS} - ${DMC_CR_VERSION}"

#  local CP4D_WS_STATUS=`oc get WS ws-cr -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.status.wsStatus}' 2> /dev/null | sed 's/ *$//g'`
#  local CP4D_WS_VERSION=`oc get WS ws-cr -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.spec.version} {"\n"}' 2> /dev/null`
#  if [ -z "${CP4D_WS_STATUS}" ]; then
#    CP4D_WS_STATUS="Not Found"
#  fi
#  if [ -z "${CP4D_WS_VERSION}" ]; then
#      CP4D_WS_VERSION=""
#  fi
#  echo "     Watson Studio Version        :  ${CP4D_WS_STATUS} - ${CP4D_WS_VERSION}"

#  local WML_VERSION=`oc get WmlBase wml-cr -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.spec.version}' 2> /dev/null`
#  local WML_CR_STATUS=`oc get WmlBase wml-cr -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.status.wmlStatus} {"\n"}' 2> /dev/null | sed 's/ *$//g'`
#  if [ -z ${WML_CR_STATUS} ]; then
#    WML_CR_STATUS="Not Found"
#  fi
#  echo "     Watson Machine Learning      :  ${WML_CR_STATUS} - ${WML_VERSION}"
#
#  local DMC_CCS_STATUS=`oc get CCS ccs-cr -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.status.ccsStatus} {"\n"}' 2> /dev/null | sed 's/ *$//g'`
#  local DMC_CCS_VERSION=`oc get CCS ccs-cr -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.status.versions.reconciled} {"\n"}' 2> /dev/null`
#  if [ -z ${DMC_CCS_STATUS} ]; then
#    DMC_CCS_STATUS="Not Found"
#  fi
#  echo "     Common Core Services Module  :  ${DMC_CCS_STATUS} - ${DMC_CCS_VERSION}"

  echo ""
  #echo ""
  echo "Pods Managed By: ibm-dmc-operator"
  oc get pods -A -l 'app.kubernetes.io/managed-by=ibm-dmc-operator'
  echo ""
  echo "Pods Managed By: ibm-dmc-addon"
  oc get pods -A -l 'app.kubernetes.io/managed-by=ibm-dmc-addon'
  echo ""
}
