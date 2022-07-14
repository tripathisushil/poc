############################################################
#Author           : Kyle Dawson
#Author email     : Kyle.Dawson@us.ibm.com
#Original Date    : 2020-10-18
#Initial Version  : v2021-12-01
############################################################
#Setup Variables
############################################################
#https://www.ibm.com/docs/en/cloud-paks/cp-data/4.0?topic=services-data-virtualization
#https://www.ibm.com/docs/en/cloud-paks/cp-data/4.0?topic=tasks-creating-operator-subscriptions
cp4dServiceDV()
{
  local CONTINUE_SERVICE_INSTALL=true
  if [ "${1}" = "delete" ]; then
     printHeaderMessage "Cloud Pak for Data Service - Data Virtualization" ${RED_TEXT}
  else
      printHeaderMessage "Cloud Pak for Data Service - Data Virtualization"
  fi
  if [ "${CP4D_ENABLE_SERVICE_DV}" == "true" ]; then
      if [ ${1} == "apply" ]; then
          echo "Enabling Service now"

          cp4dServiceDVCaseSetup
          if [ "${CONTINUE_SERVICE_INSTALL}" == "true" ]; then
              oc apply -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/subscriptions/ibm-dv-operator-catalog-subscription/subscription.yaml
              echo ""
              let LOOP_COUNT=1
              case ${OCP_INSTALL_TYPE} in
                roks-msp)
                      echo "${RED_TEXT}WARNING ${RESET_TEXT} DV running on roks requires large cluster."
                      echo "${RED_TEXT}WARNING ${RESET_TEXT} If your cluster is not large enough, the DV install will work but the DV instnace will fail."
                      oc apply -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/daemonset/kernelparam.ds.roks.dv.yaml
                      oc apply -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/daemonset/norootsquash_roks_dv.yaml
                      echo ""
                      ;;
              esac
              local DR_IBM_DB2_SUBSCRIPTION_READY="NOT_READY"
              while [ "${DR_IBM_DB2_SUBSCRIPTION_READY}" != "1"  ]
              do
                    blinkWaitMessage "Waiting for DB2U Operator to be installed before we create instance" 10
                    DR_IBM_DB2_SUBSCRIPTION_READY=`oc get csv -n ibm-common-services 2> /dev/null | grep db2u-operator 2> /dev/null | grep -c Succeeded`
                    if [ "${DR_IBM_DB2_SUBSCRIPTION_READY}" == "1" ]  ;then
                              echo "${BLUE_TEXT}COMPLETE ${RESET_TEXT} DB2U Operator installed"
                              local DR_IBM_DV_OPERATOR_SUBSCRIPTION_READY="NOT_READY"
                              while [ "${DR_IBM_DV_OPERATOR_SUBSCRIPTION_READY}" != "1"  ]
                              do
                                    blinkWaitMessage "Waiting for DV Operator to be installed before we create instance" 10
                                    DR_IBM_DV_OPERATOR_SUBSCRIPTION_READY=`oc get csv -n ${CP4D_OPERATORS_NAMESPACE} | grep  ibm-dv-operator 2> /dev/null | grep -c Succeeded`
                                    if [ "${DR_IBM_DV_OPERATOR_SUBSCRIPTION_READY}" == "1" ]  ;then
                                            echo "${BLUE_TEXT}COMPLETE ${RESET_TEXT}DV Operator installed"
                                            oc apply -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/customresource/dvservice.yaml
                                            echo ""
                                            echo "Your requset to install the service has been submitted.  It can take 1 hour or more."
                                            echo "To check on the status of your service, you can run the following command:"
                                            echo "            ${DATA_DIR}/${PROJECT_NAME}/${PRODUCT_SHORT_NAME}/service.sh ${ENV_FILE_NAME} --DVStatus"
                                            echo ""

                                    fi
                                    if [ $LOOP_COUNT -ge 60 ] ;then
                                        echo "${RED_TEXT}FAILED: ibm-dv-operator-catalog-subscription subscription could not be installed. Timeout waiting.${RESET_TEXT}"
                                        echo ""
                                        break
                                    fi
                                      let LOOP_COUNT=LOOP_COUNT+1
                              done
                    fi
                    let LOOP_COUNT=LOOP_COUNT+1
                    if [ $LOOP_COUNT -ge 61 ] ;then
                        echo "${RED_TEXT}FAILED: ibm-db2u-operator subscription could not be installed. Timeout waiting.${RESET_TEXT}"
                        echo "IBM DB2U Operator instance could not be found."
                        echo "After some time, you can run the following command to finsish the setup"
                        echo "            oc apply -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/subscriptions/ibm-dv-operator-catalog-subscription/subscription.yaml"
                        echo "            oc apply -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/customresource/dvservice.yaml"
                        echo ""
                        break
                    fi
                    let LOOP_COUNT=LOOP_COUNT+1
              done
          fi
      else
        if [ ${1} == "delete" ]; then
            echo "Removing Operand Request"
            oc delete operandrequest dv-requests-ccs -n ${CP4D_INSTANCE_NAMESPACE} 2> /dev/null
            echo ""
            echo "Removing Custom Resource"
            oc patch DvService dv-service -n ${CP4D_INSTANCE_NAMESPACE} -p '{"metadata":{"finalizers":[]}}' --type=merge  2> /dev/null
            oc delete --grace-period=0 --force --ignore-not-found=true --include-uninitialized=true --timeout=30s -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/customresource/dvservice.yaml 2> /dev/null
            oc delete crd dvservices.db2u.databases.ibm.com 2> /dev/null
            echo ""
            echo "Removing Service"
            oc delete DvService dv-service -n ${CP4D_INSTANCE_NAMESPACE} 2> /dev/null
            echo ""
            echo "Removing Subscriptions"
            oc delete -f  ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/subscriptions/ibm-dv-operator-catalog-subscription/subscription.yaml 2> /dev/null
            echo ""
            echo "Removing Cluster Service Version"
            oc delete csv ibm-dv-operator.v${CP4D_DV_VERSION} -n ${CP4D_OPERATORS_NAMESPACE} 2> /dev/null

        fi
      fi
  fi
  echo ""
}

cp4dServiceDVCaseSetup()
{
  #https://www.ibm.com/docs/en/cloud-paks/cp-data/4.0?topic=ccs-creating-catalog-sources-that-pull-specific-versions-images-from-entitled-registry

  if [ ${CP4D_CLOUDCTL_CASE_BUILD_OUT} = "true" ]; then
    echo "Downloading Data Virtualization Catalog Case version ${CP4D_DV_VERSION} (LOG ->  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ibm-dv-save.log)"
    cloudctl case save \
    --repo ${CASE_REPO_PATH} \
    --case ibm-dv-case \
    --version ${CP4D_DV_VERSION} \
    --outputdir ${CASE_REPO_OFFLINE_DIR} &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ibm-dv-save.log

    echo "Installing Data Virtualization Catalog Case version ${CP4D_DV_VERSION}  (LOG ->  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ibm-dv-launch.log)"
    cloudctl case launch \
      --case ${CASE_REPO_OFFLINE_DIR}/ibm-dv-case-${CP4D_DV_VERSION}.tgz \
      --inventory dv \
      --namespace openshift-marketplace \
      --action install-catalog \
        --args "--inputDir ${CASE_REPO_OFFLINE_DIR} --recursive " &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ibm-dv-launch.log
    echo "${BLUE_TEXT}COMPLETE ${RESET_TEXT}cloudclt Launch command finished"
    echo ""
    local DV_CATALOG_READY=`oc get catalogsource -n openshift-marketplace ibm-dv-operator-catalog -o jsonpath='{.status.connectionState.lastObservedState} {"\n"}' 2> /dev/null| sed 's/ *$//g'`
    let  LOOP_COUNT=1
    while [ "${DV_CATALOG_READY}" != "READY"  ]
    do
        blinkWaitMessage "Waiting for Data Virtualization to be ready.    " 60
        DV_CATALOG_READY=`oc get catalogsource -n openshift-marketplace ibm-dv-operator-catalog -o jsonpath='{.status.connectionState.lastObservedState} {"\n"}' 2> /dev/null | sed 's/ *$//g'`
        let LOOP_COUNT=LOOP_COUNT+1
        if [ $LOOP_COUNT -ge 10 ] ;then
            echo "${RED_TEXT}FAILED:Data Virtualization could not be installed${RESET_TEXT}"
            echo ""
            CONTINUE_SERVICE_INSTALL=false
            break
        fi
    done
    echo "${BLUE_TEXT}COMPLETE ${RESET_TEXT}Successfully installed Data Virtualization catalog"
    echo ""
  fi
}

cp4dServiceDVStatus()
{
  printHeaderMessage "Cloud Pak for Data Service - Data Virtualization"
  validateCP4DVersion &>/dev/null
  echo "Daffy Version                            :  ${DAFFY_VERSION}"
  echo "Bastion OS                               :  ${OS_FLAVOR}"
  echo "Platform Install Type                    :  ${OCP_INSTALL_TYPE}"
  echo "OpenShift Version                        :  ${OCP_SERVER_VERSION}"
  echo "Zen Version                              :  ${CP4D_ZEN_VERSION}"
  local DV_VERSION=`oc get DvService dv-service -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.spec.version}' 2> /dev/null`
  if [ -z ${DV_VERSION} ]; then
    DV_VERSION=""
  fi
  #Status good locic, need to test -o jsonpath='{.status.message}'
  local DV_STATUS=`oc get DvService dv-service -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.status.reconcileStatus}' 2> /dev/null`
  if [ -z ${DV_STATUS} ]; then
    DV_STATUS="Not Found"
  fi
  echo "Data Virtualization                      :  ${DV_STATUS} - ${DV_VERSION}"
  local CCS_STATUS=`oc get CCS ccs-cr -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.status.ccsStatus} {"\n"}' 2> /dev/null | sed 's/ *$//g'`
  local CCS_VERSION=`oc get CCS ccs-cr -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.status.versions.reconciled} {"\n"}' 2> /dev/null`
  if [ -z ${CCS_STATUS} ]; then
    CCS_STATUS="Not Found"
  fi
  echo "        Common Core Services Module      :  ${CCS_STATUS} - ${CCS_VERSION}"

  case ${CP4D_VERSION} in
     4.0.2)
        local DMC_STATUS=`oc get Dmc data-management-console -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.status.conditions[0].reason}' 2> /dev/null`
        if [ -z ${DMC_STATUS} ]; then
              DMC_STATUS=`oc get Dmc data-management-console -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.status.conditions[1].reason}' 2> /dev/null`
        fi
        ;;
     *)
        local DMC_STATUS=`oc get Dmc data-management-console -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.status.dmcStatus}' 2> /dev/null`
        ;;
  esac

  local DMC_VERSION=`oc get Dmc data-management-console -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.spec.version} {"\n"}' 2> /dev/null`
  if [ -z ${DMC_STATUS} ]; then
       DMC_STATUS="Not Found"
  fi
  echo "        Data Management Console Version  :  ${DMC_STATUS} - ${DMC_VERSION}"
  local DV_STATUS=`oc get DvService dv-service -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.status.reconcileStatus}' 2> /dev/null`
  local DV_STATUS_ERROR=`oc get DvService dv-service -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.status.reconcileStatus}' 2>&1 | grep -c rror`
  if [ ${DV_STATUS_ERROR} == "1" ] || [ -z ${DV_STATUS} ]; then
    DV_STATUS="Not Found"
  fi
  echo "Pods:  "
  oc get pods -A -l 'app.kubernetes.io/instance=ibm-dv-operator'
  echo ""
  oc get pods -A -l 'release in (dv)'
  echo ""
}
