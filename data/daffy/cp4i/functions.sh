#!/bin/bash
############################################################
#Author           : Dave Krier
#Author email     : dakrier@us.ibm.com
#Original Date    : 2021-10-25
#Initial Version  : v2021-12-01
############################################################
#Setup Variables
############################################################
validateCP4IVersion()
{
  case ${CP4I_VERSION} in
    2021.4.1)
        echo "${BLUE_TEXT}PASSED ${RESET_TEXT} Valid version CP4I_VERSION=${CP4I_VERSION}"
        ;;
    2021.3.1)
        echo "${BLUE_TEXT}PASSED ${RESET_TEXT} Valid version CP4I_VERSION=${CP4I_VERSION}"
        ;;
    2021.2.1)
        echo "${BLUE_TEXT}PASSED ${RESET_TEXT} Valid version CP4I_VERSION=${CP4I_VERSION}"
        ;;
     *)
       echo "${RED_TEXT}FAILED: Invalid version CP4I_VERSION=${CP4I_VERSION}${RESET_TEXT}"
       echo "${RED_TEXT}Current Supported Versions: 2021.4.1, 2021.3.1, 2021.2.1${RESET_TEXT}"
       SHOULD_EXIT=1
       ;;
  esac
  CP4I_ZEN_VERSION=`oc get ZenService iaf-zen-cpdservice -n ${CP4I_NAMESPACE} -o jsonpath='{.status.currentVersion} {"\n"}' 2> /dev/null`
  if [ -z ${CP4I_ZEN_VERSION} ]; then
    CP4I_ZEN_VERSION="Not Found"
  fi
  OCP_SERVER_VERSION=`oc version | grep Server | awk '{print $3}'`
  #if [ -z ${OCP_SERVER_VERSION} ]; then
  #  OCP_SERVER_VERSION="Not Found"
  #fi
}

precheckCP4I()
{
  printHeaderMessage "Prechecks"
  prepareHost
  baseValidation
  getOpenShiftTools
  getIBMEntitlementKey
  variablePresent ${CP4I_VERSION} CP4I_VERSION
  variablePresent ${IBM_ENTITLEMENT_KEY} IBM_ENTITLEMENT_KEY
  variablePresent ${CP_REGISTRY} CP_REGISTRY
  variablePresent ${CP_REGISTRY_EMAIL} CP_REGISTRY_EMAIL
  validateCP4IVersion
  case ${OCP_INSTALL_TYPE} in
    roks-msp)
        testIBMCloudLogin
        waitForROKSClusterReady
        ;;
    rosa-msp)
        ROSALoginCluster
        ;;
  esac
  validateStorage ${CP4I_STORAGE_CLASS}
  validateStorage ${CP4I_BLOCK_CLASS}
  validateOCPAccess
  validateCloudPakSize
  validOCPVersion
  #Make sure storage classes that we use exist
  shouldExit
  echo ""
  echo "All prechecks passed, lets get to work."
  echo ""

}

prepareCP4IInputFiles()
{
  mkdir -p ${TEMP_DIR}/${PRODUCT_SHORT_NAME}
  cd ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/
  cp -fR ${DIR}/templates/* ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@PROJECT_NAME@/$PROJECT_NAME/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@CP4I_VERSION@/$CP4I_VERSION/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@CP4I_LICENSE@/$CP4I_LICENSE/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@CP4I_NAMESPACE@/$CP4I_NAMESPACE/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@CP4I_SUBSCRIPTION_CHANNEL@/$CP4I_SUBSCRIPTION_CHANNEL/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@CP4I_STORAGE_CLASS@/$CP4I_STORAGE_CLASS/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@CP4I_BLOCK_CLASS@/$CP4I_BLOCK_CLASS/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@IBM_CLOUD_CATALOG_SOURCE@/$IBM_CLOUD_CATALOG_SOURCE/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@CP4I_LICENSE_USE@/$CP4I_LICENSE_USE/g"

  #Service updates
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@ACE_LICENSE@/$ACE_LICENSE/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@ACE_VERSION@/$ACE_VERSION/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@APIC_LICENSE@/$APIC_LICENSE/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@APIC_VERSION@/$APIC_VERSION/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@ASSET_REPO_LICENSE@/$ASSET_REPO_LICENSE/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@ES_VERSION@/$ES_VERSION/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@MQ_LICENSE@/$MQ_LICENSE/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@MQ_VERSION@/$MQ_VERSION/g"
}

processCP4IYaml()
{
  if [ "${1}" == "apply" ];then
    printHeaderMessage "Creating ${CP4I_NAMESPACE} Namespace"
    oc ${1} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/namespaces/namespace_cp4i.yaml
    applyNameSpaceLabels ${CP4I_NAMESPACE} 'IBM CP4I Services'
    printHeaderMessage "Creating CP4I CatalogSource"
    oc ${1} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/catalogsource/ibm-operator-catalog/catalogsource.yaml
    printHeaderMessage "Creating CP4I OperatorGroup"
    oc ${1} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/operatorgroup/operatorgroup.yaml
    printHeaderMessage "Creating CP4I Subscription"
    oc ${1} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/subscriptions/ibm-cp-integration/cp4i_all_subscription.yaml
  else
    printHeaderMessage "Nothing to deploy"  ${RED_TEXT}
    SHOULD_EXIT=1
  fi
  echo ""

}


deployPlatformNavInstance()
{
  printHeaderMessage "Deploying Platform Navigator Instance"
  oc ${1} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/customresource/platformnavigator.yaml
  applyNameSpaceLabels ibm-common-services 'IBM Common Services'
  printf "\n"
}

displayPlatformNavigatorInfo()
{
  CP4I_PASSWORD=`oc get secrets -n ibm-common-services platform-auth-idp-credentials -ojsonpath='{.data.admin_password}' | base64 -d && echo ""`
  CP4I_URL=`oc describe PlatformNavigator integration-${PROJECT_NAME}  --namespace=${CP4I_NAMESPACE} | grep "UI Endpoint" | awk '{print $3}' `
  CP4I_USER=`oc get secrets -n ibm-common-services platform-auth-idp-credentials -ojsonpath='{.data.admin_username}' | base64 -d && echo ""`

  printHeaderMessage "Here is the login info for the CP4I Navigator console:"
  echo "Super User            :      ${CP4I_USER}"
  echo "Password              :      ${CP4I_PASSWORD}"
  echo "CP4I Web Console      :      ${BLUE_TEXT}${CP4I_URL}${RESET_TEXT}"
  printf "\n\n\n${RESET_TEXT}"

}

displayCP4IStatus()
{
  printHeaderMessage "Display Cloud Pak for Integration Status"
  validateCP4IVersion
  echo "Daffy Version                :   ${DAFFY_VERSION}"
  echo "OpenShift Versions           :   ${OCP_SERVER_VERSION}"
  echo ""
  printHeaderMessage "Here is the status of the ${CP4I_NAMESPACE} Operators:  "
  oc get csv -n openshift-operators -n ${CP4I_NAMESPACE}
  printf "\n\n\n${RESET_TEXT}"
}

waitForPlatformNavigatorOperatorToComplete()
{
  startWaitForPFN=$SECONDS
  printHeaderMessage "Wait for platform Navigator Operator to complete"
  echo ""
  blinkWaitMessage "Waiting 3 minutes before we start to check!" 180
  OPERATOR_STATUS=`oc get csv -n ${CP4I_NAMESPACE} 2> /dev/null | grep "ibm-integration-platform-navigator" | awk '{print $(NF)}'`
  while [ "${OPERATOR_STATUS}" != "Succeeded" ]
  do
    blinkWaitMessage "Still waiting  - almost there, will keep checking every 10 seconds" 10
    OPERATOR_STATUS=`oc get csv -n ${CP4I_NAMESPACE} 2> /dev/null | grep "ibm-integration-platform-navigator" | awk '{print $(NF)}'`
  done
  echo "Platform Navigator Operator is Ready"
  now=$SECONDS
  let "diff=now-startWaitForPFN"
  startWaitForPFN=${diff}
  if (( $startWaitForPFN > 60 )) ; then
      let "minutes=(startWaitForPFN%3600)/60"
      let "seconds=(startWaitForPFN%3600)%60"
      echo "Operator was created in $minutes minute(s) and $seconds second(s)"
  else
      echo "Operator was created in $startWaitForPFN seconds (WOW insane speed, you have a great system)"
  fi
}

waitForPFNInstanceToComplete()
{

    startWaitForPFNI=$SECONDS
    printHeaderMessage "Wait for platform Navigator Instance to complete"
    echo ""
    blinkWaitMessage "Waiting 20 minutes before we start to check!" 1200
    OPERATOR_STATUS=`oc get PlatformNavigator integration-${PROJECT_NAME} --namespace=${CP4I_NAMESPACE} -o json 2> /dev/null | jq .status.conditions[0].type 2> /dev/null`
    while [ ${OPERATOR_STATUS} != '"Ready"' ]
    do
      blinkWaitMessage "Still waiting  - almost there, will keep checking every 2 min" 120
      OPERATOR_STATUS=`oc get PlatformNavigator integration-${PROJECT_NAME}  --namespace=${CP4I_NAMESPACE} -o json  2> /dev/null | jq .status.conditions[0].type 2> /dev/null`
    done
    echo "Platform Navigator Instance is Ready"
    now=$SECONDS
    let "diff=now-startWaitForPFNI"
    startWaitForPFNI=${diff}
    if (( $startWaitForPFNI > 60 )) ; then
        let "minutes=(startWaitForPFNI%3600)/60"
        let "seconds=(startWaitForPFNI%3600)%60"
        echo "Instance was created in $minutes minute(s) and $seconds second(s)"
    else
        echo "Instance was created in $startWaitForPFNI seconds (WOW insane speed, you have a great system)"
    fi
}

cp4iServiceAllStatus()
{
  OCP_SERVER_VERSION=`oc version | grep Server | awk '{print $3}'`
  validateCP4IVersion &>/dev/null
  printHeaderMessage "Cloud Pak for Integration Service - All Status"
  echo "Daffy Version                               :  ${DAFFY_VERSION}"
  echo "OpenShift Version                           :  ${OCP_SERVER_VERSION}"
  echo "Bastion OS                                  :  ${OS_FLAVOR}"
  echo "Platform Install Type                       :  ${OCP_INSTALL_TYPE}"
  echo "Cloud Pak Versions                          :  ${CP4I_VERSION}"
  echo "Zen Version                                 :  ${CP4I_ZEN_VERSION}"
  local AceDesign_VERSION=`oc get DesignerAuthoring ace-design --namespace=${CP4I_NAMESPACE} -o jsonpath='{.spec.version}' 2> /dev/null`
  local AceDesign_STATUS=`oc get DesignerAuthoring ace-design -n ${CP4I_NAMESPACE} -o jsonpath='{.status.phase}' 2> /dev/null`
  if [ -z ${AceDesign_STATUS} ]; then
    AceDesign_STATUS="Not Found"
  fi
  echo "AppConnect Designer                         :  ${AceDesign_STATUS} - ${AceDesign_VERSION}"
  local AceDash_VERSION=`oc get Dashboard ace-dashboard --namespace=${CP4I_NAMESPACE} -o jsonpath='{.spec.version}' 2> /dev/null`
  local AceDash_STATUS=`oc get Dashboard ace-dashboard --namespace=${CP4I_NAMESPACE} -o jsonpath='{.status.phase} {"\n"}' 2> /dev/null | sed 's/ *$//g'`
  if [ -z ${AceDash_STATUS} ]; then
    AceDash_STATUS="Not Found"
  fi
  echo "AppConnect Dashboard                        :  ${AceDash_STATUS} - ${AceDash_VERSION}"
  local Repo_STATUS=`oc get AssetRepository assetrepo -n ${CP4I_NAMESPACE} -o jsonpath='{.status.phase} {"\n"}' 2> /dev/null | sed 's/ *$//g'`
  local Repo_VERSION=`oc get AssetRepository assetrepo --namespace=${CP4I_NAMESPACE} -o jsonpath='{.spec.version} {"\n"}' 2> /dev/null`
  if [ -z ${Repo_STATUS} ]; then
    Repo_STATUS="Not Found"
  fi
  echo "Asset Repository                            :  ${Repo_STATUS} - ${Repo_VERSION}"
  Tracing_VERSION=`oc get OperationsDashboard tracing --namespace=${CP4I_NAMESPACE} -o jsonpath='{.spec.version} {"\n"}' 2> /dev/null`
  Tracing_STATUS=`oc get OperationsDashboard tracing --namespace=${CP4I_NAMESPACE} -o jsonpath='{.status.phase} {"\n"}' 2> /dev/null | sed 's/ *$//g'`
  if [ -z ${Tracing_STATUS} ]; then
      Tracing_STATUS="Not Found"
  fi
  echo "Operations Dashboard Tracing                :  ${Tracing_STATUS} - ${Tracing_VERSION}"
  MQ_VERSION=`oc get QueueManager mq0 --namespace=${CP4I_NAMESPACE} -o jsonpath='{.spec.version} {"\n"}' 2> /dev/null`
  MQ_STATUS=`oc get QueueManager mq0 --namespace=${CP4I_NAMESPACE} -o jsonpath='{.status.phase} {"\n"}' 2> /dev/null | sed 's/ *$//g'`
  if [ -z ${MQ_STATUS} ]; then
      MQ_STATUS="Not Found"
  fi
  echo "MQ Single Instance                          :  ${MQ_STATUS} - ${MQ_VERSION}"
  APIC_VERSION=`oc get APIConnectCluster apic-min --namespace=${CP4I_NAMESPACE} -o jsonpath='{.spec.version} {"\n"}' 2> /dev/null`
  APIC_STATUS=`oc get APIConnectCluster apic-min --namespace=${CP4I_NAMESPACE} -o jsonpath='{.status.phase} {"\n"}' 2> /dev/null | sed 's/ *$//g'`
  if [ -z ${APIC_STATUS} ]; then
      APIC_STATUS="Not Found"
  fi
  echo "API Connect Instance                        :  ${APIC_STATUS} - ${APIC_VERSION}"
  MQ_VERSION=`oc get QueueManager mq-ha --namespace=${CP4I_NAMESPACE} -o jsonpath='{.spec.version} {"\n"}' 2> /dev/null`
  MQ_STATUS=`oc get QueueManager mq-ha --namespace=${CP4I_NAMESPACE} -o jsonpath='{.status.phase} {"\n"}' 2> /dev/null | sed 's/ *$//g'`
  if [ -z ${MQ_STATUS} ]; then
      MQ_STATUS="Not Found"
  fi
  echo "MQ HA Instance                              :  ${MQ_STATUS} - ${MQ_VERSION}"
  ES_VERSION=`oc get EventStreams eventstreams --namespace=${CP4I_NAMESPACE} -o jsonpath='{.spec.version} {"\n"}' 2> /dev/null`
  ES_STATUS=`oc get EventStreams eventstreams --namespace=${CP4I_NAMESPACE} -o jsonpath='{.status.phase} {"\n"}' 2> /dev/null | sed 's/ *$//g'`
  if [ -z ${ES_STATUS} ]; then
      ES_STATUS="Not Found"
  fi
  echo "Event Streams Instance                      :  ${ES_STATUS} - ${ES_VERSION}"
  echo ""
}

validateCP4IServiceVersion()
{
    case ${CP4I_VERSION} in
      2021.4.1)
        echo "Valid version CP4I Version found=${CP4I_VERSION}${RESET_TEXT}"
        echo ""
        ;;
      *)
        echo "${RED_TEXT}FAILED: Invalid version CP4I_VERSION=${CP4I_VERSION}${RESET_TEXT}"
        echo "${RED_TEXT}Current Supported Service Versions: 2021.4.1${RESET_TEXT}"
        SHOULD_EXIT=1
        ;;
   esac
}

deployTracingService()
{
   #if [ "${CP4I_ENABLE_SERVICE_TRACING}" == "true" ]; then
      printHeaderMessage "Deploy Tracing Service"
      echo "Installing Operations Dashboard Tracing Service first before continuing onto other Services"
      oc apply -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/customresource/tracing.yaml
      printf "\n"
      startWaitForTraceI=$SECONDS
      OPERATOR_STATUS=`oc get OperationsDashboard tracing  --namespace=${CP4I_NAMESPACE} -o jsonpath='{.status.phase} {"\n"}' 2> /dev/null`
      if [ ${OPERATOR_STATUS} != "Ready" ]; then
          printHeaderMessage "Wait for Integration Operations Dashboard Tracing Instance to complete"
          echo ""
          blinkWaitMessage "Waiting 10 minutes before we start to check!" 600
          OPERATOR_STATUS=`oc get OperationsDashboard tracing --namespace=${CP4I_NAMESPACE} -o jsonpath='{.status.phase} {"\n"}' 2> /dev/null`
            while [ ${OPERATOR_STATUS} != "Ready" ]
            do
               blinkWaitMessage "Still waiting  - almost there, will keep checking every 2 min" 120
               OPERATOR_STATUS=`oc get OperationsDashboard tracing  --namespace=${CP4I_NAMESPACE} -o jsonpath='{.status.phase} {"\n"}' 2> /dev/null`
            done
      fi
      echo "Integration Operations Dashboard Tracing Instance is Ready"
      now=$SECONDS
      let "diff=now-startWaitForTraceI"
      startWaitForTraceI=${diff}
        if (( $startWaitForTraceI > 60 )) ; then
           let "minutes=(startWaitForTraceI%3600)/60"
           let "seconds=(startWaitForTraceI%3600)%60"
           echo "Instance was created in $minutes minute(s) and $seconds second(s)"
        else
           echo "Instance was created in $startWaitForTraceI seconds (WOW insane speed, you have a great system)"
        fi
      echo "Applying Operations Dashboard tracing secret"
      oc create secret generic icp4i-od-store-cred -n ${CP4I_NAMESPACE} --from-literal=icp4i-od-cacert.pem="empty" --from-literal=username="empty" --from-literal=password="empty" --from-literal=tracingUrl="empty"
}

validateTracingService()
{
   printHeaderMessage "Validate Tracing Service"
   OPERATOR_STATUS=`oc get OperationsDashboard tracing --namespace=${CP4I_NAMESPACE} -o jsonpath='{.status.phase} {"\n"}' 2> /dev/null`
   if [ ${CP4I_ENABLE_SERVICE_TRACING} == "true" ] ;then
        echo "Checking for existing tracing service"
        if [ "${OPERATOR_STATUS}" == "Ready" ] ;then
           echo "Operations Dashoard tracing service is already installed, continuing on"
        else
           echo "Operations Dashboard tracing not ready, installing now"
           deployTracingService
        fi
   else
       echo "Operations Dashboard tracing not selected, continuing on to other services."
   fi
}
