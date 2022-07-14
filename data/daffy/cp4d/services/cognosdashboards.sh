############################################################
#Author           : Jeff Imholz
#Author email     : jimholz@us.ibm.com
#Original Date    : 2022-04-12
#Initial Version  : v2022-04-12
############################################################
#Setup Variables
############################################################
#https://www.ibm.com/docs/en/cloud-paks/cp-data/4.0
#https://www.ibm.com/docs/en/cloud-paks/cp-data/4.0?topic=tasks-creating-operator-subscriptions

cp4dServiceCognosDashboards()
{
  local CONTINUE_SERVICE_INSTALL=true
  if [ "${1}" = "delete" ]; then
    printHeaderMessage "Cloud Pak for Data Service - Cognos Dashboards" ${RED_TEXT}
  else
    printHeaderMessage "Cloud Pak for Data Service - Cognos Dashboards"
  fi
  if [ "${CP4D_ENABLE_SERVICE_COGNOS_DASHBOARDS}" == "true" ]; then
      if [ ${1} == "apply" ]; then
            echo "Enabling Subscriptions"
            cp4dServiceCognosDashboardsCaseSetup
            if [ "${CONTINUE_SERVICE_INSTALL}" == "true" ]; then
                oc apply -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/subscriptions/ibm-cde-operator-subscription/subscription.yaml
                let  LOOP_COUNT=1
                COGNOS_KIND_READY="NOT_READY"
                while [ "${COGNOS_KIND_READY}" != "1"  ]
                do
                      blinkWaitMessage "Waiting for Cognos Dashboards Operator to be installed before we create instance" 10
                      COGNOS_KIND_READY=`oc get csv -n ${CP4D_OPERATORS_NAMESPACE} | grep -c "ibm-cpd-cde*"`
                      if [ "${COGNOS_KIND_READY}" == "1" ]  ;then
                              echo "${BLUE_TEXT}COMPLETE ${RESET_TEXT} Cognos Dashboards Operator installed"
                              oc ${1} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/customresource/cognos.yaml
                              echo ""
                              echo "Your request to install the service has been submitted.  It can take up to 2 hours!"
                              echo "You can check status via this command: "
                              echo "            ${DATA_DIR}/${PROJECT_NAME}/${PRODUCT_SHORT_NAME}/service.sh  ${ENV_FILE_NAME} --CognosStatus"
                              echo ""
                      fi
                      if [ $LOOP_COUNT -ge 60 ] ;then
                          echo "${RED_TEXT}FAILED ${RESET_TEXT} Cognos Dashboards Operator could not be installed"
                          echo "After some time, you can run the following command to finsish the setup"
                          echo "                           ${RED_TEXT}oc ${1} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/customresource/cognos.yaml${RESET_TEXT}"
                          echo ""
                          break
                      fi
                      let LOOP_COUNT=LOOP_COUNT+1
                done
            fi
      else
        if [ ${1} == "delete" ]; then
              echo "Removing Operand Request"
              oc delete operandrequest cde-requests-ccs -n ${CP4D_INSTANCE_NAMESPACE} 2> /dev/null
              echo ""
              echo "Removing Custom Resource"
              oc delete --grace-period=0 --force --ignore-not-found=true --include-uninitialized=true --timeout=30s -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/customresource/cognos.yaml 2> /dev/null
              oc delete crd cdeproxyservices.cde.cpd.ibm.com -n ${CP4D_INSTANCE_NAMESPACE} 2> /dev/null  # Check this.. Not sure I got the name right.
              echo ""
              echo "Removing Service"
              oc delete crd cdeproxyservices.cde.cpd.ibm.com -n ${CP4D_INSTANCE_NAMESPACE} 2> /dev/null
              echo ""
              echo "Removing Subscriptions"
              oc delete -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/subscriptions/ibm-cpe-operator-subscription/subscription.yaml 2> /dev/null
        fi
      fi
  fi
  echo ""
}

cp4dServiceCognosDashboardsCaseSetup()
{
  if [ ${CP4D_CLOUDCTL_CASE_BUILD_OUT} = "true" ]; then
    echo "Downloading Cognos Dashboard Catalog Case version ${CP4D_CASE_COGNOS_VERSION}  (LOG ->  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ibm-cognos-save.log)"
    cloudctl case save \
    --repo ${CASE_REPO_PATH} \
    --case ibm-cde \
    --version ${CP4D_CASE_COGNOS_VERSION} \
    --outputdir ${CASE_REPO_OFFLINE_DIR} &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ibm-cognos-save.log

    echo "Installing Cognos Dashboard Catalog Case version ${CP4D_CASE_COGNOS_VERSION}   (LOG ->  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ibm-cognos-launch.log)"
    cloudctl case launch \
      --case ${CASE_REPO_OFFLINE_DIR}/ibm-cde-${CP4D_CASE_COGNOS_VERSION}.tgz \
      --inventory cdeOperatorSetup \
      --namespace openshift-marketplace \
      --action install-catalog \
        --args "--inputDir ${CASE_REPO_OFFLINE_DIR} --recursive " &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ibm-cognos-launch.log
    echo "${BLUE_TEXT}COMPLETE ${RESET_TEXT}cloudclt Launch command finished"
    echo ""
    local COGNOS_CATALOG_READY=`oc get catalogsource ibm-cde-operator-catalog -n openshift-marketplace -o jsonpath='{.status.connectionState.lastObservedState} {"\n"}' 2> /dev/null | sed 's/ *$//g'`
    let  LOOP_COUNT=1
    while [ "${COGNOS_CATALOG_READY}" != "READY"  ]
    do
        blinkWaitMessage "Waiting for Cognos Dashboard to be ready.    " 60
        COGNOS_CATALOG_READY=`oc get catalogsource -n openshift-marketplace ibm-cde-operator-catalog -o jsonpath='{.status.connectionState.lastObservedState} {"\n"}' 2> /dev/null | sed 's/ *$//g'`
        let LOOP_COUNT=LOOP_COUNT+1
        if [ $LOOP_COUNT -ge 10 ] ;then
            echo "${RED_TEXT}FAILED: Cognos Dashboard could not be installed${RESET_TEXT}"
            echo ""
            CONTINUE_SERVICE_INSTALL=false
            break
        fi
    done
    echo "${BLUE_TEXT}COMPLETE ${RESET_TEXT}Successfully installed Cognos Dashboard catalog "
  fi
}


cp4dServiceCognosDashboardsStatus()
{
  printHeaderMessage "Cloud Pak for Data Service - Cognos Dashboard"
  validateCP4DVersion &>/dev/null
  echo "Daffy Version                     :  ${DAFFY_VERSION}"
  echo "Bastion OS                        :  ${OS_FLAVOR}"
  echo "Platform Install Type             :  ${OCP_INSTALL_TYPE}"
  echo "OpenShift Version                 :  ${OCP_SERVER_VERSION}"
  echo "Zen Version                       :  ${CP4D_ZEN_VERSION}"

  local COGNOS_CR_STATUS=`oc get CdeProxyService cdeproxyservice-cr -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.status.cdeStatus} {"\n"}' 2> /dev/null | sed 's/ *$//g'`
  local COGNOS_CR_VERSION=`oc get CdeProxyService cdeproxyservice-cr -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.spec.version} {"\n"}' 2> /dev/null`
  if [ -z ${COGNOS_CR_STATUS} ]; then
    COGNOS_CR_STATUS="Not Found"
  fi
  echo "Cognos Dashboard                  :  ${COGNOS_CR_STATUS} - ${COGNOS_CR_VERSION}"

  local COGNOS_CCS_STATUS=`oc get CCS ccs-cr -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.status.ccsStatus} {"\n"}' 2> /dev/null | sed 's/ *$//g'`
  local COGNOS_CCS_VERSION=`oc get CCS ccs-cr -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.status.versions.reconciled} {"\n"}' 2> /dev/null`
  if [ -z ${COGNOS_CCS_STATUS} ]; then
    COGNOS_CCS_STATUS="Not Found"
  fi
  echo "     Common Core Services Module  :  ${COGNOS_CCS_STATUS} - ${COGNOS_CCS_VERSION}"

  echo ""
  echo "Pods: managed-by=ibm-cde-prod "
  oc get pods -A -l 'app.kubernetes.io/managed-by=ibm-cde-prod'
  echo ""
}
