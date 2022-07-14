############################################################
#Author           : Kyle Dawson
#Author email     : Kyle.Dawson@us.ibm.com
#Original Date    : 2020-10-19
#Initial Version  : v2021-12-01
############################################################
#Setup Variables
############################################################
#https://www.ibm.com/docs/en/cloud-paks/cp-data/4.0?topic=services-watson-studio
#https://www.ibm.com/docs/en/cloud-paks/cp-data/4.0?topic=tasks-creating-operator-subscriptions
cp4dServiceWS()
{
  local CONTINUE_SERVICE_INSTALL=true
  if [ "${1}" = "delete" ]; then
    printHeaderMessage "Cloud Pak for Data Service - Watson Studio" ${RED_TEXT}
  else
    printHeaderMessage "Cloud Pak for Data Service - Watson Studio"
  fi
  if [ "${CP4D_ENABLE_SERVICE_WS}" == "true" ]; then
    if [ ${1} == "apply" ]; then
          echo "Enabling Service now"
          cp4dServiceWSCaseSetup
          if [ "${CONTINUE_SERVICE_INSTALL}" == "true" ]; then
              oc apply -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/subscriptions/ibm-cpd-ws-operator-catalog-subscription/subscription.yaml
              echo ""
              let  LOOP_COUNT=1
              WKS_KIND_READY="NOT_READY"
              while [ "${WKS_KIND_READY}" != "1"  ]
              do
                    blinkWaitMessage "Waiting for Watson Studio Opertor to be installed before we create instance" 10
                    WKS_KIND_READY=`oc get crd | grep -c ws.ws.cpd.ibm.com`
                    if [ "${WKS_KIND_READY}" == "1" ]  ;then
                            echo "${BLUE_TEXT}COMPLETE ${RESET_TEXT}Watson Studio Operator installed"
                            oc ${1} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/customresource/ws.yaml
                            echo ""
                            echo "Your request to install the service has been submitted.  It can take 1 hour or more."
                            echo "To check on the status of your service, you can run the following command:"
                            echo "            ${DATA_DIR}/${PROJECT_NAME}/${PRODUCT_SHORT_NAME}/service.sh ${ENV_FILE_NAME} --WSStatus"
                            echo ""

                    fi
                    if [ $LOOP_COUNT -ge 60 ] ;then
                        echo "${RED_TEXT}FAILED:IBM Watson  Studio instance could not be installed${RESET_TEXT}"
                        echo "After some time, you can run the following command to finsish the setup"
                        echo "            ${RED_TEXT}oc ${1} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/customresource/ws.yaml${RESET_TEXT}"
                        echo ""
                        break
                    fi
                    let LOOP_COUNT=LOOP_COUNT+1
              done
          fi
    else
      if [ ${1} == "delete" ]; then
        local WSL_VERSION_CSV=`oc get csv -n ${CP4D_OPERATORS_NAMESPACE} 2> /dev/null| grep ibm-cpd-wsl | awk '{print $4}'`
        echo "Removing Install Plan"
        local WS_IP_NAME=`oc get ip -n ${CP4D_INSTANCE_NAMESPACE} 2> /dev/null | grep  ibm-cpd-wsl |  awk '{print $1}'`
        oc delete ip ${WS_IP_NAME} -n ${CP4D_INSTANCE_NAMESPACE} 2> /dev/null
        local WS_IP_NAME=`oc get ip -n ${CP4D_INSTANCE_NAMESPACE}  2> /dev/null| grep  ibm-cpd-wsl |  awk '{print $1}'`
        oc delete ip  ${WS_IP_NAME} -n ${CP4D_INSTANCE_NAMESPACE} 2> /dev/null
        local WS_IP_NAME=`oc get ip -n ${CP4D_INSTANCE_NAMESPACE}  2> /dev/null| grep  ibm-cpd-ws-runtimes |  awk '{print $1}'`
        oc delete ip ${WS_IP_NAME} -n ${CP4D_INSTANCE_NAMESPACE} 2> /dev/null
        echo ""
        echo "Removing Custom Resource"
        oc patch WS ws-cr -n ${CP4D_INSTANCE_NAMESPACE} -p '{"metadata":{"finalizers":[]}}' --type=merge  2> /dev/null
        oc delete --grace-period=0 --force --ignore-not-found=true --include-uninitialized=true --timeout=30s -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/customresource/ws.yaml 2> /dev/null
        oc delete crd ws.ws.cpd.ibm.com 2> /dev/null
        echo ""
        echo "Removing Operand Request"
        oc delete operandrequest wsl-requests-ccs -n ${CP4D_INSTANCE_NAMESPACE} 2> /dev/null
        oc delete operandrequest wsl-requests-datarefinery -n ${CP4D_INSTANCE_NAMESPACE} 2> /dev/null
        oc delete operandrequest wsl-requests-nbrt-py37 -n ${CP4D_INSTANCE_NAMESPACE} 2> /dev/null
        oc delete operandrequest wsl-requests-nbrt-py38 -n ${CP4D_INSTANCE_NAMESPACE} 2> /dev/null
        echo ""
        echo "Removing Subscription"
        oc delete -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/subscriptions/ibm-cpd-ws-operator-catalog-subscription/subscription.yaml 2> /dev/null
        echo ""
        echo "Removing Cluster Service Version"
        oc delete csv ibm-cpd-wsl.v${WSL_VERSION_CSV} -n ${CP4D_OPERATORS_NAMESPACE} 2> /dev/null
      fi
    fi
  fi
  echo ""
}

cp4dServiceWSCaseSetup()
{
  #https://www.ibm.com/docs/en/cloud-paks/cp-data/4.0?topic=ccs-creating-catalog-sources-that-pull-specific-versions-images-from-entitled-registry
  if [ ${CP4D_CLOUDCTL_CASE_BUILD_OUT} = "true" ]; then
    echo "Downloading Watson Studio Catalog Case version ${CP4D_CASE_WS_VERSION} (LOG ->  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ibm-ws-save.log)"
    cloudctl case save \
    --repo ${CASE_REPO_PATH} \
    --case ibm-wsl \
    --version ${CP4D_CASE_WS_VERSION} \
    --outputdir ${CASE_REPO_OFFLINE_DIR} &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ibm-ws-save.log

    echo "Installing Watson StudioCatalog  Case version ${CP4D_CASE_WS_VERSION} (LOG ->  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ibm-ws-launch.log)"
    cloudctl case launch \
      --case ${CASE_REPO_OFFLINE_DIR}/ibm-wsl-${CP4D_CASE_WS_VERSION}.tgz \
      --inventory wslSetup   \
      --namespace openshift-marketplace \
      --action install-catalog \
        --args "--inputDir ${CASE_REPO_OFFLINE_DIR} --recursive " &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ibm-ws-launch.log
    echo "${BLUE_TEXT}COMPLETE ${RESET_TEXT}cloudclt Launch command finished"
    echo ""
    local WS_CATALOG_READY=`oc get catalogsource -n openshift-marketplace ibm-cpd-ws-operator-catalog  -o jsonpath='{.status.connectionState.lastObservedState} {"\n"}' 2> /dev/null | sed 's/ *$//g'`
    let  LOOP_COUNT=1
    while [ "${WS_CATALOG_READY}" != "READY"  ]
    do
        blinkWaitMessage "Waiting for Watson Studio to be ready.    " 60
        WS_CATALOG_READY=`oc get catalogsource -n openshift-marketplace ibm-cpd-ws-operator-catalog -o jsonpath='{.status.connectionState.lastObservedState} {"\n"}' 2> /dev/null | sed 's/ *$//g'`
        let LOOP_COUNT=LOOP_COUNT+1
        if [ $LOOP_COUNT -ge 10 ] ;then
            echo "${RED_TEXT}FAILED:Watson Studio could not be installed.${RESET_TEXT}"
            echo ""
            CONTINUE_SERVICE_INSTALL=false
            break
        fi
    done
    echo "${BLUE_TEXT}COMPLETE ${RESET_TEXT}Successfully installed Watson Studio catalog"
  fi
}

cp4dServiceWSStatus()
{
  printHeaderMessage "Cloud Pak for Data Service - Watson Studio Status"
  validateCP4DVersion &>/dev/null
  echo "Daffy Version                     :  ${DAFFY_VERSION}"
  echo "Bastion OS                        :  ${OS_FLAVOR}"
  echo "Platform Install Type             :  ${OCP_INSTALL_TYPE}"
  echo "OpenShift Version                 :  ${OCP_SERVER_VERSION}"
  echo "Zen Version                       :  ${CP4D_ZEN_VERSION}"
  CP4D_WS_VERSION=`oc get WS ws-cr -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.spec.version} {"\n"}' 2> /dev/null`
  CP4D_WS_STATUS=`oc get WS ws-cr -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.status.wsStatus} {"\n"}' 2> /dev/null`
  if [ -z ${CP4D_WS_VERSION} ]; then
      CP4D_WS_VERSION=""
  fi
  if [ -z ${CP4D_WS_STATUS} ]; then
      CP4D_WS_STATUS="Not Found"
  fi
  echo "Watson Studio                     :  ${CP4D_WS_STATUS} - ${CP4D_WS_VERSION}"
  local WS_CR_STATUS=`oc get WS ws-cr -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.status.wsStatus} {"\n"}' 2>&1`
  local WS_CR_STATUS_ERROR=`oc get WS ws-cr -o jsonpath='{.status.wsStatus} {"\n"}' 2>&1 | grep -c rror`
  if [ ${WS_CR_STATUS_ERROR} == "1" ] || [ -z ${WS_CR_STATUS} ]; then
    WS_CR_STATUS="Not Found"
  fi
  local WS_CCS_STATUS=`oc get CCS ccs-cr -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.status.ccsStatus} {"\n"}' 2> /dev/null`
  local WS_CCS_VERSION=`oc get CCS ccs-cr -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.status.versions.reconciled} {"\n"}' 2> /dev/null`
  if [ -z ${WS_CCS_STATUS} ]; then
    WS_CCS_STATUS="Not Found"
  fi
  echo "      Common Core Services Module :  ${WS_CCS_STATUS} - ${WS_CCS_VERSION}"
  local WS_DR_STATUS=`oc get DataRefinery datarefinery-sample -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.status.datarefineryStatus} {"\n"}' 2> /dev/null`
  local WS_DR_BUILD=`oc get DataRefinery datarefinery-sample -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.status.datarefineryBuildNumber} {"\n"}' 2> /dev/null`
  if [ -z ${WS_DR_STATUS} ]; then
      WS_DR_STATUS="Not Found"
  fi
  echo "      Data Refinery Module        :  ${WS_DR_STATUS} - Build Number ${WS_DR_BUILD}"
  echo "Pods:  "
  oc get pods -A -l 'app.kubernetes.io/managed-by=ibm-cpd-ws-operator '
  echo ""
  oc get pods -A -l 'icpdsupport/addOnId=ws'
  echo ""

}
