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
#https://www.ibm.com/docs/en/cloud-paks/cp-data/4.0?topic=learning-installing-watson-machine
cp4dServiceWML()
{
  local CONTINUE_SERVICE_INSTALL=true
  if [ "${1}" = "delete" ]; then
      printHeaderMessage "Cloud Pak for Data Service - Watson Machine Learning" ${RED_TEXT}
  else
      printHeaderMessage "Cloud Pak for Data Service - Watson Machine Learning"
  fi
  if [ "${CP4D_ENABLE_SERVICE_WML}" == "true" ]; then
      if [ ${1} == "apply" ]; then
        echo "Enabling Subscriptions"
        cp4dServiceWMLCaseSetup
        if [ "${CONTINUE_SERVICE_INSTALL}" == "true" ]; then
            oc apply -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/subscriptions/ibm-cpd-wml-operator-subscription/subscription.yaml
            echo ""
            let  LOOP_COUNT=1
            WML_KIND_READY="NOT_READY"
            while [ "${WML_KIND_READY}" != "1"  ]
            do
                  blinkWaitMessage "Waiting for Watson Machine Learning Opertor to be installed before we create instance" 10
                  WML_KIND_READY=`oc get crd | grep -c wmlbases.wml.cpd.ibm.com`
                  if [ "${WML_KIND_READY}" == "1" ]  ;then
                          echo "${BLUE_TEXT}COMPLETE ${RESET_TEXT}Watson Machine Learning Operator installed"
                          oc ${1} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/customresource/wml.yaml
                          echo ""
                          echo "Your request to install the service has been submitted.  It can take 2 hours or more."
                          echo "You can check status via this command:"
                          echo "             ${DATA_DIR}/${PROJECT_NAME}/${PRODUCT_SHORT_NAME}/service.sh  ${ENV_FILE_NAME} --WMLStatus"
                          echo ""
                  fi
                  if [ $LOOP_COUNT -ge 60 ] ;then
                      echo "${RED_TEXT}FAILED:IBM Watson Machine Learning instance could not be installed${RESET_TEXT}"
                      echo "After some time, you can run the following command to finsish the setup"
                      echo "            ${RED_TEXT}oc ${1} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/customresource/wml.yaml${RESET_TEXT}"
                      echo ""
                      break
                  fi
                  let LOOP_COUNT=LOOP_COUNT+1
            done
        fi
      else
        if [ ${1} == "delete" ]; then
              echo "Removing Operand Request"
              oc delete operandrequest wml-requests-ccs  -n ${CP4D_INSTANCE_NAMESPACE} 2> /dev/null
              echo ""
              echo "Removing Custom Resource"
              oc patch WmlBase wml-cr -n ${CP4D_INSTANCE_NAMESPACE} -p '{"metadata":{"finalizers":[]}}' --type=merge  2> /dev/null
              oc delete --grace-period=0 --force --ignore-not-found=true --include-uninitialized=true --timeout=30s -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/customresource/wml.yaml 2> /dev/null
              oc delete crd wmlbases.wml.cpd.ibm.com 2> /dev/null
              echo ""
              echo "Removing Subscription"
              oc delete -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/subscriptions/ibm-cpd-wml-operator-subscription/subscription.yaml 2> /dev/null
              echo ""
              echo "Removing Cluster Service Version"
              local WML_VERSION_CSV=`oc get csv -n ${CP4D_OPERATORS_NAMESPACE} | grep ibm-cpd-wml-operator | awk '{print $5}'`
              oc delete csv ibm-cpd-wml-operator.v${WML_VERSION_CSV} -n ${CP4D_OPERATORS_NAMESPACE} 2> /dev/null
        fi
      fi
  fi
  echo ""
}

cp4dServiceWMLCaseSetup()
{
  if [ ${CP4D_CLOUDCTL_CASE_BUILD_OUT} = "true" ]; then
    echo "Downloading Watson Machine Learning Catalog Case version ${CP4D_CASE_WML_VERSION} (LOG ->  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ibm-wml-save.log)"
    cloudctl case save \
    --repo ${CASE_REPO_PATH} \
    --case  ibm-wml-cpd \
    --version ${CP4D_CASE_WML_VERSION} \
    --outputdir ${CASE_REPO_OFFLINE_DIR} &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ibm-wml-save.log

    echo "Installing Watson Machine Learning Catalog Case version ${CP4D_CASE_WML_VERSION} (LOG ->  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ibm-wml-launch.log)"
    cloudctl case launch \
      --case ${CASE_REPO_OFFLINE_DIR}/ibm-wml-cpd-${CP4D_CASE_WML_VERSION}.tgz \
      --inventory wmlOperatorSetup   \
      --namespace openshift-marketplace \
      --action install-catalog \
        --args "--inputDir ${CASE_REPO_OFFLINE_DIR} --recursive " &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ibm-wml-launch.log
    echo "${BLUE_TEXT}COMPLETE ${RESET_TEXT}cloudclt Launch command finished"
    echo ""
    local WML_CATALOG_READY=`oc get catalogsource -n openshift-marketplace ibm-cpd-wml-operator-catalog -o jsonpath='{.status.connectionState.lastObservedState} {"\n"}' 2> /dev/null | sed 's/ *$//g'`
    let  LOOP_COUNT=1
    while [ "${WML_CATALOG_READY}" != "READY"  ]
    do
        blinkWaitMessage "Waiting for Watson Machine Learning to be ready.    " 60
        WML_CATALOG_READY=`oc get catalogsource -n openshift-marketplace ibm-cpd-wml-operator-catalog -o jsonpath='{.status.connectionState.lastObservedState} {"\n"}'  2> /dev/null | sed 's/ *$//g'`
        let LOOP_COUNT=LOOP_COUNT+1
        if [ $LOOP_COUNT -ge 10 ] ;then
            echo "${RED_TEXT}FAILED: Watson Machine Learning could not be installed${RESET_TEXT}"
            echo ""
            CONTINUE_SERVICE_INSTALL=false
            break
        fi
    done
    echo "${BLUE_TEXT}COMPLETE ${RESET_TEXT}Successfully installed Watson Machine Learning catalog"
  fi
}


cp4dServiceWMLStatus()
{
  printHeaderMessage "Cloud Pak for Data Service - Watson Machine Learning"
  validateCP4DVersion &>/dev/null
  echo "Daffy Version                     :  ${DAFFY_VERSION}"
  echo "Bastion OS                        :  ${OS_FLAVOR}"
  echo "Platform Install Type             :  ${OCP_INSTALL_TYPE}"
  echo "OpenShift Version                 :  ${OCP_SERVER_VERSION}"
  echo "Zen Version                       :  ${CP4D_ZEN_VERSION}"

  local WML_VERSION=`oc get WmlBase wml-cr -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.spec.version}' 2> /dev/null`
  local WML_CR_STATUS=`oc get WmlBase wml-cr -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.status.wmlStatus} {"\n"}' 2> /dev/null | sed 's/ *$//g'`
  if [ -z ${WML_CR_STATUS} ]; then
    WML_CR_STATUS="Not Found"
  fi
  echo "Watson Machine Learning           :  ${WML_CR_STATUS} - ${WML_VERSION}"
  local WML_CCS_STATUS=`oc get CCS ccs-cr -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.status.ccsStatus} {"\n"}' 2> /dev/null | sed 's/ *$//g'`
  local WML_CCS_VERSION=`oc get CCS ccs-cr -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.status.versions.reconciled} {"\n"}' 2> /dev/null`
  if [ -z ${WML_CCS_STATUS} ]; then
    WML_CCS_STATUS="Not Found"
  fi
  echo "     Common Core Services Module  :  ${WML_CCS_STATUS} - ${WML_CCS_VERSION}"
  echo "Pods:  "
  oc get pods -A -l 'control-plane=ibm-cpd-wml-operator'
  echo ""
  oc get pods -A -l 'release in (wml)'
  echo ""
}
