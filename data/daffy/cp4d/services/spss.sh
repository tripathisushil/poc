############################################################
#Author           : Kyle Dawson
#Author email     : Kyle.Dawson@us.ibm.com
#Original Date    : 2021-12-18
#Initial Version  : v2022-01-18
############################################################
#Setup Variables
############################################################
#https://www.ibm.com/docs/en/cloud-paks/cp-data/4.0
#https://www.ibm.com/docs/en/cloud-paks/cp-data/4.0?topic=tasks-creating-operator-subscriptions
#https://www.ibm.com/docs/en/cloud-paks/cp-data/4.0?topic=services-spss-modeler
cp4dServiceSPSS()
{
  local CONTINUE_SERVICE_INSTALL=true
  if [ "${1}" = "delete" ]; then
    printHeaderMessage "Cloud Pak for Data Service - Statistical Package for the Social Sciences(SPSS)" ${RED_TEXT}
  else
    printHeaderMessage "Cloud Pak for Data Service - Statistical Package for the Social Sciences(SPSS)"
  fi
  if [ "${CP4D_ENABLE_SERVICE_SPSS}" == "true" ]; then
      if [ ${1} == "apply" ]; then
            echo "Enabling Subscriptions"
            cp4dServiceSPSSCaseSetup
            if [ "${CONTINUE_SERVICE_INSTALL}" == "true" ]; then
                oc apply -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/subscriptions/ibm-cpd-spss-operator-catalog-subscription/subscription.yaml
                echo ""
                let  LOOP_COUNT=1
                SPSS_KIND_READY="NOT_READY"
                while [ "${SPSS_KIND_READY}" != "1"  ]
                do
                      blinkWaitMessage "Waiting for Statistical Package for the Social Sciences(SPSS) Operator to be installed before we create instance" 10
                      SPSS_KIND_READY=`oc get crd | grep -c spss.spssmodeler.cpd.ibm.com`
                      if [ "${SPSS_KIND_READY}" == "1" ]  ;then
                              echo "${BLUE_TEXT}COMPLETE ${RESET_TEXT} Statistical Package for the Social Sciences(SPSS) Operator installed"
                              oc ${1} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/customresource/spss.yaml
                              echo ""
                              echo "Your request to install the service has been submitted.  It can take 2 hours or more."
                              echo "You can check status via this command: "
                              echo "            ${DATA_DIR}/${PROJECT_NAME}/${PRODUCT_SHORT_NAME}/service.sh  ${ENV_FILE_NAME} --SPSSStatus"
                              echo ""
                      fi
                      if [ $LOOP_COUNT -ge 60 ] ;then
                          echo "IBM Statistical Package for the Social Sciences(SPSS) instance could not be installed"
                          echo "After some time, you can run the following command to finsish the setup"
                          echo "                           ${RED_TEXT}oc ${1} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/customresource/spss.yaml${RESET_TEXT}"
                          echo ""
                          break
                      fi
                      let LOOP_COUNT=LOOP_COUNT+1
                done
            fi
      else
        if [ ${1} == "delete" ]; then
              echo "Removing Operand Request"
              oc delete operandrequest spss-requests-ccs -n ${CP4D_INSTANCE_NAMESPACE} 2> /dev/null
              oc delete operandrequest spss-requests-ws -n ${CP4D_INSTANCE_NAMESPACE} 2> /dev/null
              echo ""
              echo "Removing Custom Resource"
              oc patch Spss spss -n ${CP4D_INSTANCE_NAMESPACE} -p '{"metadata":{"finalizers":[]}}' --type=merge  2> /dev/null
              oc delete --grace-period=0 --force --ignore-not-found=true --include-uninitialized=true --timeout=30s -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/customresource/spss.yaml 2> /dev/null
              oc delete crd spss.spssmodeler.cpd.ibm.com 2> /dev/null
              echo ""
              echo "Removing Service"
              oc delete Spss spss -n ${CP4D_INSTANCE_NAMESPACE} 2> /dev/null
              echo ""
              echo "Removing Subscriptions"
              oc delete -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/subscriptions/ibm-cpd-spss-operator-catalog-subscription/subscription.yaml 2> /dev/null
              echo ""
              echo "Removing Cluster Service Version"
              oc delete csv ibm-cpd-spss.v${CP4D_CASE_SPSS_VERSION} -n ${CP4D_OPERATORS_NAMESPACE} 2> /dev/null

        fi
      fi
  fi
  echo ""
}

cp4dServiceSPSSCaseSetup()
{
  if [ ${CP4D_CLOUDCTL_CASE_BUILD_OUT} = "true" ]; then
    echo "Downloading Statistical Package for the Social Sciences Catalog Case version ${CP4D_CASE_SPSS_VERSION}  (LOG ->  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ibm-spss-save.log)"
    cloudctl case save \
    --repo ${CASE_REPO_PATH} \
    --case ibm-spss \
    --version ${CP4D_CASE_SPSS_VERSION} \
    --outputdir ${CASE_REPO_OFFLINE_DIR} &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ibm-spss-save.log

    echo "Installing Statistical Package for the Social Sciences Catalog Case version ${CP4D_CASE_SPSS_VERSION}   (LOG ->  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ibm-spss-launch.log)"
    cloudctl case launch \
      --case ${CASE_REPO_OFFLINE_DIR}/ibm-spss-${CP4D_CASE_SPSS_VERSION}.tgz \
      --inventory spssSetup  \
      --namespace openshift-marketplace \
      --action install-catalog \
        --args "--inputDir ${CASE_REPO_OFFLINE_DIR} --recursive " &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ibm-spss-launch.log
    echo "${BLUE_TEXT}COMPLETE ${RESET_TEXT}cloudclt Launch command finished"
    echo ""
    local SPSS_CATALOG_READY=`oc get catalogsource -n openshift-marketplace ibm-cpd-spss-operator-catalog -o jsonpath='{.status.connectionState.lastObservedState} {"\n"}' 2> /dev/null | sed 's/ *$//g'`
    let  LOOP_COUNT=1
    while [ "${SPSS_CATALOG_READY}" != "READY"  ]
    do
        blinkWaitMessage "Waiting for Statistical Package for the Social Sciences to be ready.    " 60
        SPSS_CATALOG_READY=`oc get catalogsource -n openshift-marketplace ibm-cpd-spss-operator-catalog -o jsonpath='{.status.connectionState.lastObservedState} {"\n"}' 2> /dev/null | sed 's/ *$//g'`
        let LOOP_COUNT=LOOP_COUNT+1
        if [ $LOOP_COUNT -ge 10 ] ;then
            echo "${RED_TEXT}FAILED ${RESET_TEXT} Statistical Package for the Social Sciences catalog could not be installed"
            echo ""
            CONTINUE_SERVICE_INSTALL=false
            break
        fi
    done
    if [  "${SPSS_CATALOG_READY}" == "READY" ]; then
      echo "${BLUE_TEXT}COMPLETE ${RESET_TEXT}Successfully installed Statistical Package for the Social Sciences catalog"
    fi

  fi
}


cp4dServiceSPSSStatus()
{
  printHeaderMessage "Cloud Pak for Data Service - Statistical Package for the Social Sciences(SPSS)"
  validateCP4DVersion &>/dev/null
  echo "Daffy Version                     :  ${DAFFY_VERSION}"
  echo "Bastion OS                        :  ${OS_FLAVOR}"
  echo "Platform Install Type             :  ${OCP_INSTALL_TYPE}"
  echo "OpenShift Version                 :  ${OCP_SERVER_VERSION}"
  echo "Zen Version                       :  ${CP4D_ZEN_VERSION}"

  local SPSS_VERSION=`oc get Spss spss -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.spec.version}' 2> /dev/null`
  local SPSS_CR_STATUS=`oc get Spss spss -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.status.spssmodelerStatus} {"\n"}' 2> /dev/null | sed 's/ *$//g'`
  if [ -z ${SPSS_CR_STATUS} ]; then
    SPSS_CR_STATUS="Not Found"
  fi
  echo "SPSS                              :  ${SPSS_CR_STATUS} - ${SPSS_VERSION}"
  local SPSS_CCS_STATUS=`oc get CCS ccs-cr -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.status.ccsStatus} {"\n"}' 2> /dev/null | sed 's/ *$//g'`
  local SPSS_CCS_VERSION=`oc get CCS ccs-cr -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.status.versions.reconciled} {"\n"}' 2> /dev/null`
  if [ -z ${SPSS_CCS_STATUS} ]; then
    SPSS_CCS_STATUS="Not Found"
  fi
  echo "     Common Core Services Module  :  ${SPSS_CCS_STATUS} - ${SPSS_CCS_VERSION}"
  local CP4D_WS_STATUS=`oc get WS ws-cr -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.status.wsStatus}' 2> /dev/null | sed 's/ *$//g'`
  local CP4D_WS_VERSION=`oc get WS ws-cr -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.spec.version} {"\n"}' 2> /dev/null`
  if [ -z "${CP4D_WS_STATUS}" ]; then
    CP4D_WS_STATUS="Not Found"
  fi
  if [ -z "${CP4D_WS_VERSION}" ]; then
      CP4D_WS_VERSION=""
  fi
  echo "     Watson Studio Version        :  ${CP4D_WS_STATUS} - ${CP4D_WS_VERSION}"
  local WKC_DR_STATUS=`oc get DataRefinery datarefinery-sample -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.status.datarefineryStatus} {"\n"}' 2> /dev/null | sed 's/ *$//g'`
  local WKC_DR_BUILD=`oc get DataRefinery datarefinery-sample -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.status.datarefineryBuildNumber} {"\n"}' 2> /dev/null`
  if [ -z ${WKC_DR_STATUS} ]; then
      WKC_DR_STATUS="Not Found"
  fi
  if [ "${WKC_DR_BUILD}" != "" ]; then
      WKC_DR_BUILD="Build ${WKC_DR_BUILD}"
  fi
  echo "     Data Refinery Module         :  ${WKC_DR_STATUS} - ${WKC_DR_BUILD}"

  echo "Pods:  "
  oc get pods -A -l 'app.kubernetes.io/managed-by=ibm-cpd-spss-operator'
  echo ""
  oc get pods -A -l 'release in (spss-modeler)'
  echo ""
}
