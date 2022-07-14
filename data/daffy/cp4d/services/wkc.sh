############################################################
#Author           : Kyle Dawson
#Author email     : Kyle.Dawson@us.ibm.com
#Original Date    : 2020-10-12
#Initial Version  : v2021-12-01
############################################################
#Setup Variables
############################################################
#https://www.ibm.com/docs/en/cloud-paks/cp-data/4.0?topic=catalog-installing-watson-knowledge
#https://www.ibm.com/docs/en/cloud-paks/cp-data/4.0?topic=tasks-creating-operator-subscriptions
cp4dServiceWKC()
{
  local CONTINUE_SERVICE_INSTALL=true
  if [ "${1}" = "delete" ]; then
      printHeaderMessage "Cloud Pak for Data Service - Watson Knowledge Catalog" ${RED_TEXT}
  else
      printHeaderMessage "Cloud Pak for Data Service - Watson Knowledge Catalog"
  fi
  if [ "${CP4D_ENABLE_SERVICE_WKC}" == "true" ]; then
      if [ ${1} == "apply" ]; then
          echo "Enabling Service now"
          cp4dServiceWKCCaseSetup
          if [ "${CONTINUE_SERVICE_INSTALL}" == "true" ]; then
              #echo "Define new security context constraints"
              oc apply -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/scc/wkc-iis-scc.yaml

              #echo "Create new cluster role - wkc-iis-scc"
              oc delete clusterrole system:openshift:scc:wkc-iis-scc &> /dev/null
              oc create clusterrole system:openshift:scc:wkc-iis-scc --verb=use --resource=scc --resource-name=wkc-iis-scc

              #echo "Create new role binding -wkc-iis-scc-rb"
              oc delete rolebinding wkc-iis-scc-rb --namespace ${CP4D_INSTANCE_NAMESPACE}  &> /dev/null
              oc create rolebinding wkc-iis-scc-rb --namespace ${CP4D_INSTANCE_NAMESPACE} --clusterrole=system:openshift:scc:wkc-iis-scc --serviceaccount=ibm.common.services:wkc-iis-sa

              oc apply -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/subscriptions/ibm-cpd-wkc-operator-catalog-subscription/subscription.yaml
              echo ""
              echo ""
              let  LOOP_COUNT=1
              WKC_KIND_READY="NOT_READY"
              while [ "${WKC_KIND_READY}" != "1"  ]
              do
                    blinkWaitMessage "Waiting for WKC Operator to be installed before we create instance" 60
                    WKC_KIND_READY=`oc get crd | grep -c wkc.wkc.cpd.ibm.com`
                    if [ "${WKC_KIND_READY}" == "1" ]  ;then
                            echo "${BLUE_TEXT}COMPLETE ${RESET_TEXT} WKC Operator installed"
                            oc apply -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/customresource/wkc.yaml
                            echo ""
                            echo "Your request to install the service has been submitted.  It can take 3 hours or more."
                            echo "To check on the status of your service, you can run the following command:"
                            echo "            ${DATA_DIR}/${PROJECT_NAME}/${PRODUCT_SHORT_NAME}/service.sh ${ENV_FILE_NAME} --WKCStatus"
                            echo ""
                    fi
                    if [ $LOOP_COUNT -ge 60 ] ;then
                        echo "${RED_TEXT}FAILED:IBM Watson Knowledge Catalog instance could not be installed${RESET_TEXT}"
                        echo "After some time, you can run the following command to finsish the setup"
                        echo "            ${RED_TEXT}oc ${1} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/customresource/wkc.yaml${RESET_TEXT}"
                        echo ""
                        break
                    fi
                    let LOOP_COUNT=LOOP_COUNT+1
              done
          fi
      fi
      if [ ${1} == "delete" ]; then
        echo "This Feature Not Working 100% yet, beta version of command!!!!!!"
        echo "Removing Install Plan"
        local IIS_IP_NAME=`oc get ip -n ${CP4D_INSTANCE_NAMESPACE}  2> /dev/null | grep  ibm-cpd-iis|  awk '{print $1}'`
        oc delete ip ${IIS_IP_NAME} -n ${CP4D_INSTANCE_NAMESPACE}  2> /dev/null
        echo ""
        echo "Removing Custom Resource"
        oc patch wkc wkc-cr -n ${CP4D_INSTANCE_NAMESPACE} -p '{"metadata":{"finalizers":[]}}' --type=merge  2> /dev/null
        oc delete --grace-period=0 --force --ignore-not-found=true --include-uninitialized=true --timeout=30s -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/customresource/wkc.yaml  2> /dev/null
        echo ""
        echo "Removing Db2uCluster IIS and WKC"
        oc delete  Db2uCluster db2oltp-iis  -n ibm-common-services 2> /dev/null
        oc delete  Db2uCluster db2oltp-wkc -n ibm-common-services 2> /dev/null
        echo ""
        echo "Removing StatfulSets"
        oc delete statefulset -l 'icpdsupport/addOnId=wkc' 2> /dev/null | grep -v "No resources found"
        echo ""
        echo "Removing Operand Request"
        oc delete operandrequest wkc-requests-ccs  -n ${CP4D_INSTANCE_NAMESPACE} 2> /dev/null
        oc delete operandrequest wkc-requests-datarefinery -n ${CP4D_INSTANCE_NAMESPACE} 2> /dev/null
        oc delete operandrequest wkc-requests-db2uaas  -n ${CP4D_INSTANCE_NAMESPACE} 2> /dev/null
        oc delete operandrequest wkc-requests-iis -n ${CP4D_INSTANCE_NAMESPACE} 2> /dev/null
        echo ""
        echo "Removing Subscriptions"
        oc delete -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/subscriptions/ibm-cpd-wkc-operator-catalog-subscription/subscription.yaml
        echo ""
        echo "Removing Cluster Service Version"
        local WKC_VERSION_CSV=`oc get csv -n ${CP4D_INSTANCE_NAMESPACE}  2> /dev/null | grep ibm-cpd-wkc | awk '{print $4}'`
        oc delete csv ibm-cpd-wkc.v${WKC_VERSION_CSV} -n ${CP4D_INSTANCE_NAMESPACE}
      fi
      if [ ${1} == "operations" ]; then
            if [ ${2} == "clearIISStuckJob" ]; then
                echo "${RED_TEXT}Running clearIISStuckJob operations commands"
                oc delete job iis-db2u-backup-restore-job -n ${CP4D_INSTANCE_NAMESPACE}
                oc delete job iis-db2u-backup-pvc-job -n ${CP4D_INSTANCE_NAMESPACE}
                IIS_OPERATOR_PRESENT=`oc get po -n ${CP4D_OPERATORS_NAMESPACE} | grep -c ibm-cpd-iis-operator`
                if [ ${IIS_OPERATOR_PRESENT} -eq 1 ]; then
                    IIS_OPERATOR=`oc get po -n ${CP4D_OPERATORS_NAMESPACE} | grep ibm-cpd-iis-operator | awk '{print $1}'`
                    oc delete po ${IIS_OPERATOR} -n ${CP4D_OPERATORS_NAMESPACE}
                fi
                echo "${RESET_TEXT}"
            fi
      fi
  fi
  echo ""
}

cp4dServiceWKCCaseSetup()
{
  if [ ${CP4D_CLOUDCTL_CASE_BUILD_OUT} = "true" ]; then
    echo "Downloading Watson Knowledge Catalog Case version ${CP4D_VERSION}  (LOG ->  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ibm-wkc-save.log)"
    cloudctl case save \
    --repo ${CASE_REPO_PATH} \
    --case ibm-wkc \
    --version ${CP4D_VERSION} \
    --outputdir ${CASE_REPO_OFFLINE_DIR} &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ibm-wkc-save.log

    echo "Installing Watson Knowledge Catalog Case version ${CP4D_VERSION}   (LOG ->  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ibm-wkc-launch.log)"
    cloudctl case launch \
      --case ${CASE_REPO_OFFLINE_DIR}/ibm-wkc-${CP4D_VERSION}.tgz \
      --inventory wkcOperatorSetup \
      --namespace openshift-marketplace \
      --action install-catalog \
        --args "--inputDir ${CASE_REPO_OFFLINE_DIR} --recursive " &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ibm-wkc-launch.log
    echo "${BLUE_TEXT}COMPLETE ${RESET_TEXT}cloudclt Launch command finished"
    echo ""
    local WKC_CATALOG_READY=`oc get catalogsource -n openshift-marketplace ibm-cpd-wkc-operator-catalog -o jsonpath='{.status.connectionState.lastObservedState} {"\n"}' 2> /dev/null | sed 's/ *$//g'`
    let  LOOP_COUNT=1
    while [ "${WKC_CATALOG_READY}" != "READY"  ]
    do
        blinkWaitMessage "Waiting for Watson Knowledge Catalog to be ready.    " 60
        WKC_CATALOG_READY=`oc get catalogsource -n openshift-marketplace ibm-cpd-wkc-operator-catalog -o jsonpath='{.status.connectionState.lastObservedState} {"\n"}' 2> /dev/null | sed 's/ *$//g'`
        let LOOP_COUNT=LOOP_COUNT+1
        if [ $LOOP_COUNT -ge 10 ] ;then
            echo "${RED_TEXT}FAILED:Watson Knowledge Catalog could not be installed${RESET_TEXT}"
            echo ""
            CONTINUE_SERVICE_INSTALL=false
            break
        fi
    done
    echo "${BLUE_TEXT}COMPLETE ${RESET_TEXT} Successfully installed Watson Knowledge Catalog catalog."
  fi
}

cp4dServiceWKCStatus()
{
  printHeaderMessage "Cloud Pak for Data Service - Watson Knowledge Catalog Status"
  validateCP4DVersion &>/dev/null
  echo "Daffy Version                               :  ${DAFFY_VERSION}"
  echo "Bastion OS                                  :  ${OS_FLAVOR}"
  echo "Platform Install Type                       :  ${OCP_INSTALL_TYPE}"
  echo "OpenShift Version                           :  ${OCP_SERVER_VERSION}"
  echo "Zen Version                                 :  ${CP4D_ZEN_VERSION}"
  local WKC_STATUS=`oc get WKC wkc-cr -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.status.wkcStatus} {"\n"}' 2> /dev/null`
  local WKC_LOCAL_VERSION=`oc get WKC wkc-cr -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.spec.version} {"\n"}' 2> /dev/null`
  if [ -z ${WKC_STATUS} ]; then
    WKC_STATUS="Not Found"
  fi
  echo "Watson Knowledge Catalog                    :  ${WKC_STATUS} - ${WKC_LOCAL_VERSION}"
  local WKC_CCS_STATUS=`oc get CCS ccs-cr -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.status.ccsStatus} {"\n"}' 2> /dev/null`
  local WKC_CCS_VERSION=`oc get CCS ccs-cr -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.status.versions.reconciled} {"\n"}' 2> /dev/null`
  if [ -z ${WKC_CCS_STATUS} ]; then
    WKC_CCS_STATUS="Not Found"
  fi
  echo "      Common Core Services Module           :  ${WKC_CCS_STATUS} - ${WKC_CCS_VERSION}"
  local WKC_DR_STATUS=`oc get DataRefinery datarefinery-sample -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.status.datarefineryStatus} {"\n"}' 2> /dev/null`
  local WKC_DR_BUILD=`oc get DataRefinery datarefinery-sample -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.status.datarefineryBuildNumber} {"\n"}' 2> /dev/null`
  if [ -z ${WKC_DR_STATUS} ]; then
      WKC_DR_STATUS="Not Found"
  else
      WKC_DR_BUILD="Build ${WKC_DR_BUILD}"
  fi
  echo "      Data Refinery Module                  :  ${WKC_DR_STATUS} - ${WKC_DR_BUILD}"
  local WKC_DB2AAS_STATUS=`oc get Db2aaserviceService db2aaservice-cr -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.status.db2aaserviceStatus} {"\n"}' 2> /dev/null`
  local WKC_DB2AAS_VERSION=`oc get Db2aaserviceService db2aaservice-cr -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.status.versionBuild} {"\n"}' 2> /dev/null`
  if [ -z ${WKC_DB2AAS_STATUS} ]; then
      WKC_DB2AAS_STATUS="Not Found"
  fi
  echo "      Db2 as a Service Module               :  ${WKC_DB2AAS_STATUS} - ${WKC_DB2AAS_VERSION}"
  local WKC_IIS_STATUS=`oc get IIS iis-cr -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.status.iisStatus} {"\n"}' 2> /dev/null`
  local WKC_IIS_VERSION=`oc get IIS iis-cr -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.spec.version} {"\n"}' 2> /dev/null`
  if [ -z ${WKC_IIS_STATUS} ]; then
      WKC_IIS_STATUS="Not Found"
  fi
  echo "      InfoSphere Information Server Module  :  ${WKC_IIS_STATUS} - ${WKC_IIS_VERSION}"
  local WKC_UG_STATUS=`oc get UG ug-cr -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.status.ugStatus} {"\n"}' 2> /dev/null`
  local WKC_UG_VERSION=`oc get UG ug-cr -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.spec.version} {"\n"}' 2> /dev/null`
  if [ -z ${WKC_UG_STATUS} ]; then
      WKC_UG_STATUS="Not Found"
  fi
  echo "      Unified Governance                    :  ${WKC_UG_STATUS} - ${WKC_UG_VERSION}"
  echo "Pods:  "
  oc get pods -A -l 'app.kubernetes.io/managed-by=ibm-cpd-wkc-operator' 2> /dev/null
  echo ""
  oc get pods -A -l 'icpdsupport/addOnId=wkc' --sort-by=.status.startTime | awk 'NR == 1; NR > 1 {print $0 | "tac"}' 2> /dev/null
  echo ""
}
