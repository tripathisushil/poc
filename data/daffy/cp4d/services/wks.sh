############################################################
#Author           : Kyle Dawson
#Author email     : Kyle.Dawson@us.ibm.com
#Original Date    : 2020-10-12
#Initial Version  : v2021-12-01
############################################################
#Setup Variables
############################################################
#https://www.ibm.com/docs/en/cloud-paks/cp-data/4.0
#https://www.ibm.com/docs/en/cloud-paks/cp-data/4.0?topic=tasks-creating-operator-subscriptions
cp4dServiceWKS()
{
  if [ "${1}" = "delete" ]; then
      printHeaderMessage "Cloud Pak for Data Service - Watson Knowledge Studio" ${RED_TEXT}
  else
      printHeaderMessage "Cloud Pak for Data Service - Watson Knowledge Studio"
  fi
  if [ "${CP4D_ENABLE_SERVICE_WKS}" == "true" ]; then
    #Need to check if serice does not exist
    #Is blank oc get wks wks -n ibm-common-services -o jsonpath='{.status.conditions[?(@.type=="Deployed")].status}'
      if [ ${1} == "apply" ]; then
            echo "Enabling Subscriptions"
            cp4dServiceWKSCaseSetup
            oc apply -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/subscriptions/ibm-watson-ks-operator-subscription/subscription.yaml
            oc apply -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/subscriptions/cloud-native-postgresql-catalog-subscription/subscription.yaml
            echo ""
            let  LOOP_COUNT=1
            WKS_KIND_READY="NOT_READY"
            while [ "${WKS_KIND_READY}" != "1"  ]
            do
                  blinkWaitMessage "Waiting for Watson Knowledge Studio Opertor to be installed before we create instance" 10
                  WKS_KIND_READY=`oc get crd | grep -c knowledgestudios.knowledgestudio.watson.ibm.com`
                  if [ "${WKS_KIND_READY}" == "1" ]  ;then
                          echo "${BLUE_TEXT}COMPLETE ${RESET_TEXT}Watson Knowledge Studio Operator installed"
                          oc ${1} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/customresource/knowledgestudio.yaml
                          echo ""
                          echo "Your request to install the service has been submitted.  It can take 30 minutes or more."
                          echo "To check on the status of your service, you can run the following command:"
                          echo "            ${DATA_DIR}/${PROJECT_NAME}/${PRODUCT_SHORT_NAME}/service.sh ${ENV_FILE_NAME} --WKSStatus"
                          echo ""

                  fi
                  if [ $LOOP_COUNT -ge 60 ] ;then
                      echo "${RED_TEXT}FAILED:IBM Watson Knowledge Studio instance could not be installed${RESET_TEXT}"
                      echo "After some time, you can run the following command to finsish the setup"
                      echo "            ${RED_TEXT}oc ${1} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/customresource/knowledgestudio.yaml${RESET_TEXT}"
                      echo ""
                      break
                  fi
                  let LOOP_COUNT=LOOP_COUNT+1
            done
      else
        if [ ${1} == "delete" ]; then
              echo "Removing Install Plan"
              local WKS_IP_NAME=`oc get ip -n ${CP4D_OPERATORS_NAMESPACE}  2> /dev/null| grep  ibm-watson-ks-operator |  awk '{print $1}'`
              oc delete ip ${WKS_IP_NAME} -n ${CP4D_OPERATORS_NAMESPACE} 2> /dev/null
              echo ""
              echo "Removing Custom Resource"
              oc patch KnowledgeStudio wks -n ${CP4D_INSTANCE_NAMESPACE} -p '{"metadata":{"finalizers":[]}}' --type=merge 2> /dev/null
              oc delete --grace-period=0 --force --ignore-not-found=true --timeout=30s -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/customresource/knowledgestudio.yaml 2> /dev/null
              echo ""
              echo "Removing Subscriptions"
              oc delete -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/subscriptions/ibm-watson-ks-operator-subscription/subscription.yaml 2> /dev/null
              echo ""
              echo "Removing Cluster Service Version"
              oc delete csv ibm-watson-ks-operator.v${CP4D_VERSION} -n ${CP4D_OPERATORS_NAMESPACE} 2> /dev/null
              echo ""
              echo "Removing Persistent Volume Claims"
              oc delete pvc -l 'release in (wks,wks-minio,wks-ibm-watson-ks)' -n ${CP4D_INSTANCE_NAMESPACE} 2> /dev/null
              echo ""
              echo "Removing Secrets"
              oc delete secret -l 'release in (wks,wks-minio,wks-ibm-watson-ks)' -n ${CP4D_INSTANCE_NAMESPACE} 2> /dev/null
        fi
      fi
  fi
  echo ""
}
cp4dServiceWKSCaseSetup()
{
  #https://www.ibm.com/docs/en/cloud-paks/cp-data/4.0?topic=ccs-creating-catalog-sources-that-pull-specific-versions-images-from-entitled-registry
  if [ ${CP4D_CLOUDCTL_CASE_BUILD_OUT} = "true" ]; then
    echo "Downloading Watson Knowledge Studio Catalog Case version ${CP4D_CASE_WKS_VERSION} (LOG ->  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ibm-wks-save.log)"
    cloudctl case save \
    --repo ${CASE_REPO_PATH} \
    --case ibm-watson-ks \
    --version ${CP4D_CASE_WKS_VERSION} \
    --outputdir ${CASE_REPO_OFFLINE_DIR} &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ibm-wks-save.log

    echo "Installing Watson Knowledge Studio Catalog Case version ${CP4D_CASE_WKS_VERSION}  (LOG ->  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ibm-wks-launch.log)"
    cloudctl case launch \
      --case ${CASE_REPO_OFFLINE_DIR}/ibm-watson-ks-${CP4D_CASE_WKS_VERSION}.tgz \
      --inventory wksOperatorSetup  \
      --namespace openshift-marketplace \
      --action install-catalog \
        --args "--inputDir ${CASE_REPO_OFFLINE_DIR} --recursive " &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ibm-wks-launch.log
    echo "${BLUE_TEXT}COMPLETE ${RESET_TEXT}cloudclt Launch command finished"
    echo ""
    local WKS_CATALOG_READY=`oc get catalogsource -n openshift-marketplace ibm-watson-ks-operator-catalog  -o jsonpath='{.status.connectionState.lastObservedState} {"\n"}' 2> /dev/null | sed 's/ *$//g'`
    let  LOOP_COUNT=1
    while [ "${WKS_CATALOG_READY}" != "READY"  ]
    do
        blinkWaitMessage "Waiting for Watson Knowledge Studio to be ready.    " 60
        WKS_CATALOG_READY=`oc get catalogsource -n openshift-marketplace ibm-watson-ks-operator-catalog -o jsonpath='{.status.connectionState.lastObservedState} {"\n"}' 2> /dev/null | sed 's/ *$//g'`
        let LOOP_COUNT=LOOP_COUNT+1
        if [ $LOOP_COUNT -ge 10 ] ;then
            echo "${RED_TEXT}FAILED ${RESET_TEXT} Watson Knowledge Studio could not be installed."
            echo ""
            break
        fi
    done
    if [ "${WKS_CATALOG_READY}" == "READY" ]; then
        echo "${BLUE_TEXT}COMPLETE ${RESET_TEXT}Successfully installed Watson Knowledge Studio catalog"
    fi
  fi
}

cp4dServiceWKSStatus()
{
  printHeaderMessage "Cloud Pak for Data Service - Watson Knowledge Studio Status"
  validateCP4DVersion &>/dev/null
  echo "Daffy Version                     :  ${DAFFY_VERSION}"
  echo "Bastion OS                        :  ${OS_FLAVOR}"
  echo "Platform Install Type             :  ${OCP_INSTALL_TYPE}"
  echo "OpenShift Version                 :  ${OCP_SERVER_VERSION}"
  echo "Zen Version                       :  ${CP4D_ZEN_VERSION}"
  local WKS_CR_STATUS=`oc get wks wks -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.status.conditions[?(@.type=="Deployed")].status}' 2> /dev/null`
  local WKS_CR_STATUS_ERROR=`oc get wks wks -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.status.conditions[?(@.type=="ReleaseFailed")].reason}' 2> /dev/null`
  if [ "${WKS_CR_STATUS_ERROR}" != "" ]; then
    WKS_CR_STATUS=${WKS_CR_STATUS_ERROR}
  fi
  if [ -z ${WKS_CR_STATUS} ]; then
    WKS_CR_STATUS="Not Found"
  fi
  local WKS_VERSION=`oc get wks wks -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.spec.version}' 2> /dev/null`
  if [ -z ${WKS_VERSION} ]; then
    WKS_VERSION=""
  fi

  echo "Watson Knowledge Studio           :  ${WKS_CR_STATUS} - ${WKS_VERSION}"
  echo "Pods:  "
  oc get pods -A -l 'app.kubernetes.io/name=ibm-watson-ks-operator'
  echo ""
  oc get pods -A -l 'release in (wks,wks-minio,wks-ibm-watson-ks)' --sort-by=.status.startTime | awk 'NR == 1; NR > 1 {print $0 | "tac"}'
  echo ""
}
