############################################################
#Author           : Kyle Dawson
#Author email     : Kyle.Dawson@us.ibm.com
#Original Date    : 2022-03-28
#Initial Version  : v2022-03-31
############################################################
#Setup Variables
############################################################
#https://www.ibm.com/docs/en/cloud-paks/cp-data/4.0
#https://www.ibm.com/docs/en/cloud-paks/cp-data/4.0?topic=tasks-creating-operator-subscriptions
#https://www.ibm.com/docs/en/cloud-paks/cp-data/4.0?topic=services-datastage
cp4dServiceDataStage()
{
  local CONTINUE_SERVICE_INSTALL=true
  if [ "${1}" = "delete" ]; then
    printHeaderMessage "Cloud Pak for Data Service - DataStage" ${RED_TEXT}
  else
    printHeaderMessage "Cloud Pak for Data Service - DataStage"
  fi
  if [ "${CP4D_ENABLE_SERVICE_DATASTAGE}" == "true" ]; then
      if [ ${1} == "apply" ]; then
            echo "Enabling Subscriptions"
            cp4dServiceDataStageCaseSetup
            if [ "${CONTINUE_SERVICE_INSTALL}" == "true" ]; then
                oc apply -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/subscriptions/ibm-cpd-datastage-operator-subscription/subscription.yaml
                echo ""
                let  LOOP_COUNT=1
                DATASTAGE_KIND_READY="NOT_READY"
                while [ "${DATASTAGE_KIND_READY}" != "1"  ]
                do
                      blinkWaitMessage "Waiting for DataStage Operator to be installed before we create instance" 10
                      DATASTAGE_KIND_READY=`oc get crd | grep -c datastages.ds.cpd.ibm.com`
                      if [ "${DATASTAGE_KIND_READY}" == "1" ]  ;then
                              echo "${BLUE_TEXT}COMPLETE ${RESET_TEXT} DataStage Operator installed"
                              oc ${1} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/customresource/datastage.yaml
                              echo ""
                              echo "Your request to install the service has been submitted.  It can take 2 hours or more."
                              echo "You can check status via this command: "
                              echo "            ${DATA_DIR}/${PROJECT_NAME}/${PRODUCT_SHORT_NAME}/service.sh  ${ENV_FILE_NAME} --DataStageStatus"
                              echo ""
                      fi
                      if [ $LOOP_COUNT -ge 60 ] ;then
                          echo "IBM DataStage instance could not be installed"
                          echo "After some time, you can run the following command to finsish the setup"
                          echo "                           ${RED_TEXT}oc ${1} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/customresource/datastage.yaml${RESET_TEXT}"
                          echo ""
                          break
                      fi
                      let LOOP_COUNT=LOOP_COUNT+1
                done
            fi
      else
        if [ ${1} == "delete" ]; then
              echo "Removing Custom Resource"
              oc delete DataStage datastage  -n ${CP4D_INSTANCE_NAMESPACE}
              echo ""
              echo "Removing PXRuntime instances"
              oc delete PXRuntime -n project-name `oc get pxruntime -n project-name --no-headers | awk '{print $1}'`
              echo ""
              echo "For the last part, you must delete from the CP4D Console:${BLUE_TEXT}
1) Log in to the Cloud Pak for Data web client as an administrator.
2) From the menu, select Services > Instances.
3) Filter the list to show only ds instances.
4) Delete each ds instance.${RESET_TEXT}"
        fi
      fi
  fi
  echo ""
}

cp4dServiceDataStageCaseSetup()
{
  if [ ${CP4D_CLOUDCTL_CASE_BUILD_OUT} = "true" ]; then
    echo "Downloading DataStage Catalog Case version ${CP4D_CASE_DATASTAGE_VERSION}  (LOG ->  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ibm-datastage-save.log)"
    cloudctl case save \
    --repo ${CASE_REPO_PATH} \
    --case ibm-datastage \
    --version ${CP4D_CASE_DATASTAGE_VERSION} \
    --outputdir ${CASE_REPO_OFFLINE_DIR} &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ibm-datastage-save.log

    echo "Installing DataStage Catalog Case version ${CP4D_CASE_DATASTAGE_VERSION}   (LOG ->  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ibm-datastage-launch.log)"
    cloudctl case launch \
      --case ${CASE_REPO_OFFLINE_DIR}/ibm-datastage-${CP4D_CASE_DATASTAGE_VERSION}.tgz \
      --inventory dsOperatorSetup  \
      --namespace openshift-marketplace \
      --action install-catalog \
        --args "--inputDir ${CASE_REPO_OFFLINE_DIR} --recursive " &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ibm-datastage-launch.log
    echo "${BLUE_TEXT}COMPLETE ${RESET_TEXT}cloudclt Launch command finished"
    echo ""
    local DATASTAGE_CATALOG_READY=`oc get catalogsource -n openshift-marketplace ibm-cpd-datastage-operator-catalog  -o jsonpath='{.status.connectionState.lastObservedState} {"\n"}' 2> /dev/null | sed 's/ *$//g'`
    let  LOOP_COUNT=1
    while [ "${DATASTAGE_CATALOG_READY}" != "READY"  ]
    do
        blinkWaitMessage "Waiting for DataStage to be ready.    (waiting for up to 10 min)" 60
        DATASTAGE_CATALOG_READY=`oc get catalogsource -n openshift-marketplace ibm-cpd-datastage-operator-catalog  -o jsonpath='{.status.connectionState.lastObservedState} {"\n"}' 2> /dev/null | sed 's/ *$//g'`
        let LOOP_COUNT=LOOP_COUNT+1
        if [ $LOOP_COUNT -ge 10 ] ;then
            echo "${RED_TEXT}FAILED ${RESET_TEXT} DataStage catalog could not be installed"
            echo ""
            CONTINUE_SERVICE_INSTALL=false
            break
        fi
    done
    if [  "${DATASTAGE_CATALOG_READY}" == "READY"  ]; then
      echo "${BLUE_TEXT}COMPLETE ${RESET_TEXT}Successfully installed DataStage catalog"
    fi

  fi
}


cp4dServiceDataStageStatus()
{
  printHeaderMessage "Cloud Pak for Data Service - DataStage"
  validateCP4DVersion &>/dev/null
  echo "Daffy Version                     :  ${DAFFY_VERSION}"
  echo "Bastion OS                        :  ${OS_FLAVOR}"
  echo "Platform Install Type             :  ${OCP_INSTALL_TYPE}"
  echo "OpenShift Version                 :  ${OCP_SERVER_VERSION}"
  echo "Zen Version                       :  ${CP4D_ZEN_VERSION}"

  local DATASTAGE_VERSION=`oc get DATASTAGE datastage -n ${CP4D_INSTANCE_NAMESPACE}  -o jsonpath='{.spec.version} {"\n"}' 2>/dev/null`
  local DATASTAGE_VERSION_MIN=`oc get DATASTAGE datastage -n ${CP4D_INSTANCE_NAMESPACE}  -o jsonpath='{.status.dsBuildNumber} {"\n"}' 2>/dev/null`
  DATASTAGE_VERSION="${DATASTAGE_VERSION} - ${DATASTAGE_VERSION_MIN}"
  local DATASTAGE_CR_STATUS=`oc get DATASTAGE datastage -n ${CP4D_INSTANCE_NAMESPACE}  -o jsonpath='{.status.dsStatus} {"\n"}' 2>/dev/null | sed 's/ *$//g'`
  if [ -z ${DATASTAGE_CR_STATUS} ]; then
    DATASTAGE_CR_STATUS="Not Found"
  fi
  echo "DataStage                         :  ${DATASTAGE_CR_STATUS} - ${DATASTAGE_VERSION}"
  local CCS_STATUS=`oc get CCS ccs-cr -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.status.ccsStatus} {"\n"}' 2> /dev/null | sed 's/ *$//g'`
  local CCS_VERSION=`oc get CCS ccs-cr -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.status.versions.reconciled} {"\n"}' 2> /dev/null`
  if [ -z ${CCS_STATUS} ]; then
    CCS_STATUS="Not Found"
  fi
  echo "     Common Core Services Module  :  ${CCS_STATUS} - ${CCS_VERSION}"
  local DATASTAGE_PX_VERSION=`oc get pxruntime ds-px-default -n ${CP4D_INSTANCE_NAMESPACE}  -o jsonpath='{.status.dsVersion} {"\n"}' 2>/dev/null`
  local DATASTAGE_PX_VERSION_MIN=`oc get pxruntime ds-px-default -n ${CP4D_INSTANCE_NAMESPACE}  -o jsonpath='{.status.dsBuildNumber} {"\n"}' 2>/dev/null`
  DATASTAGE_PX_VERSION="${DATASTAGE_PX_VERSION} - ${DATASTAGE_PX_VERSION_MIN}"
  local DATASTAGE_PX_CR_STATUS=`oc get pxruntime ds-px-default -n ${CP4D_INSTANCE_NAMESPACE}  -o jsonpath='{.status.dsStatus} {"\n"}' 2>/dev/null | sed 's/ *$//g'`
  if [ -z ${DATASTAGE_PX_CR_STATUS} ]; then
    DATASTAGE_PX_CR_STATUS="Not Found"
  fi
  echo "     PXRuntime                    :  ${DATASTAGE_PX_CR_STATUS} - ${DATASTAGE_PX_VERSION}"
  echo ""
  echo "Pods:  "
  oc get pods -n ${CP4D_INSTANCE_NAMESPACE} -l 'app.kubernetes.io/name=datastage' 2>/dev/null
  echo ""
  oc get pods -n ${CP4D_INSTANCE_NAMESPACE} -l 'app.kubernetes.io/component=px-compute' 2>/dev/null
  echo ""
  oc get pods -n ${CP4D_INSTANCE_NAMESPACE} -l 'app.kubernetes.io/component=px-runtime' 2>/dev/null
  echo ""
}
