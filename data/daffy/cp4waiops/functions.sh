#!/bin/bash
############################################################
#Author           : Dave Krier
#Author email     : dakrier@us.ibm.com
#Original Date    : v2022-01-05
#Initial Version  : v2022-01-05
############################################################
# Documentation links
#https://www.ibm.com/docs/en/cloud-paks/cloud-pak-watson-aiops/3.2.0?topic=installation-installing-online-offline#install-op-cli
validateCP4WAIOPSVersion()
{
  case ${CP4WAIOPS_VERSION} in
    3.2.0)
        CP4WAIOPS_SUBSCRIPTION_CHANNEL='v3.2'
        echo "${BLUE_TEXT}PASSED ${RESET_TEXT} Version: ${CP4WAIOPS_VERSION} is valid!"
        ;;
    3.3.1)
        CP4WAIOPS_SUBSCRIPTION_CHANNEL='v3.3'
        echo "${BLUE_TEXT}PASSED ${RESET_TEXT} Version: ${CP4WAIOPS_VERSION} is valid!"
        ;;
     *)
        echo "${RED_TEXT}FAILED: Invalid version CP4WAIOPS_VERSION=${CP4WAIOPS_VERSION}${RESET_TEXT}"
        echo "${RED_TEXT}Current Supported Versions: 3.2.0, 3.3.1${RESET_TEXT}"
        SHOULD_EXIT=1
        ;;
  esac
}

## Main Functions ##########################################
precheckCP4WAIOPS()
{
  printHeaderMessage "Performing precheck steps!"

  printHeaderMessage "Validate the necessary variables are set"
  variablePresent ${CP4WAIOPS_VERSION} CP4WAIOPS_VERSION
  variablePresent ${CP_REGISTRY} CP_REGISTRY

  if [ ${CP4WAIOPS_DEPLOY_EMGR} == "true" ]  && [ ${CP4WAIOPS_VERSION} != "3.3.1" ]; then
    echo "${RED_TEXT} Daffy Automation of Watson AIOps Event Manager is not supported with CP4WAIOPS Version ${CP4WAIOPS_VERSION} ! ${RESET_TEXT}"
    echo "${RED_TEXT} Please update your env file and select CP4WAIOPS Version 3.3.1!   ${RESET_TEXT}"
    SHOULD_EXIT=1
  fi

  case ${OCP_INSTALL_TYPE} in
    roks-msp)
        testIBMCloudLogin
        waitForROKSClusterReady
        ;;
  esac

  printHeaderMessage "Validate CP4WAIOPS Version"
  validateCP4WAIOPSVersion

  prepareCP4WAIOPSInputFiles
  prepareHost
  getOpenShiftTools
  baseValidation

  validateStorage ${CP4WAIOPS_STORAGE_CLASS}
  validateStorage ${CP4WAIOPS_BLOCK_STORAGE_CLASS}

  printHeaderMessage "Validate IBM Entitlement Key"
  getIBMEntitlementKey
  variablePresent ${IBM_ENTITLEMENT_KEY} IBM_ENTITLEMENT_KEY
  getOpenShiftTools
  validateOCPAccess
  printHeaderMessage "Validate OCP Version for CP4WAIOPS"
  validOCPVersionCP4WAIOPS

  shouldExit
  echo ""
  echo "Pre-install steps are complete, lets get to work."
  echo ""

}

installCP4WAIOPS() {
   printHeaderMessage "Deploying the CP4WAIOPS CloudPak! - AI Manager"

   printHeaderMessage "Creating new CP4WAIOPS project"
   #oc apply -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/namespace/cp4waiops.yaml
   oc create namespace ${CP4WAIOPS_NAMESPACE} 2>/dev/null
   sleep 5

   applyNameSpaceLabels ${CP4WAIOPS_NAMESPACE} 'IBM CP4WAIOPS Services'

   printHeaderMessage "Configuring Network Ingress Operator Policies for CP4WAIOPS"
   if [ $(oc get ingresscontroller default -n openshift-ingress-operator -o jsonpath='{.status.endpointPublishingStrategy.type}') = "HostNetwork" ]; then
       oc patch namespace default --type=json -p '[{"op":"add","path":"/metadata/labels","value":{"network.openshift.io/policy-group":"ingress"}}]'
   fi

   printHeaderMessage "Creating catalog source for CP4WAIOPS"
   oc apply -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/catalogsource/ibm-operator-catalog.yaml

   printHeaderMessage "Creating the operator group"
   oc apply -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/operatorgroup/cp4waiops.yaml

   printHeaderMessage "Creating the subscription witin the IBM Operator Catalog"
   oc apply -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/subscription/ibm-aiops-orchestrator.yaml

   echo ""
   let LOOP_COUNT=1
   local CP4WAIOPS_SUBSCRIPTION_READY="NOT_READY"
   while [ "${CP4WAIOPS_SUBSCRIPTION_READY}" != "1"  ]
   do
         blinkWaitMessage "Waiting for subscription and operator(ibm-aiops-orchestrator) to be installed before we proceed" 60
         CP4WAIOPS_SUBSCRIPTION_READY=`oc get csv -A 2> /dev/null | grep ibm-aiops-orchestrator 2> /dev/null | grep -c Succeeded`
         if [ "${CP4WAIOPS_SUBSCRIPTION_READY}" == "1" ]  ;then
              printHeaderMessage "Deploying CP4WAIOPS Installation"
              oc apply -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/installation/ibm-cp-watson-aiops.yaml
         fi
         if [ $LOOP_COUNT -ge 20 ] ;then
             echo "${RED_TEXT}FAILED: ibm-aiops-orchestrator operator could not be installed. Timeout waiting.${RESET_TEXT}"
             echo ""
             echo "${RED_TEXT}Exiting Script!!!!!!!${RESET_TEXT}"
             exit 9
         fi
         let LOOP_COUNT=LOOP_COUNT+1
  done

# Validate install is complte
let VALIDATE_LOOP_COUNT=1
local CP_READY="Not ready"
while [ "${CP_READY}" != "Ready"  ]
do
  blinkWaitMessage "Waiting - Checking every 5 min to validate deployment is successful! " 300
  CP_READY=`oc get BaseUI -A -o custom-columns="STATUS:status.conditions[?(@.type==\"Ready\")].reason"  2> /dev/null| grep -v STATUS`
  if [ "${CP_READY}" == "Ready" ] ;then
     applyNameSpaceLabels ibm-common-services 'IBM Common Services'
     echo "CP4WAIOPS is successfuly deployed!!"
     echo ""
     echo ""
  fi
  if [ ${VALIDATE_LOOP_COUNT} -ge 12 ] ;then
      echo "${RED_TEXT}FAILED: Unable to validate CP4WAIOPS instance is ready. Timeout waiting.${RESET_TEXT}"
      echo "${RED_TEXT}Status = ${CP_READY}${RESET_TEXT}"
      exit 9
  fi
  let VALIDATE_LOOP_COUNT=VALIDATE_LOOP_COUNT+1

done
}

installCP4WAIOPS_EventMgr() {

  printHeaderMessage "Deploying the CP4WAIOPS CloudPak! - Event Manager"

  printHeaderMessage "Creating new cp4waiops-emgr Name Space"
  oc create namespace ${CP4WAIOPS_EMGR_NAMESPACE} 2>/dev/null
  sleep 3

  applyNameSpaceLabels ${CP4WAIOPS_EMGR_NAMESPACE} 'IBM CP4WAIOPS-EMGR Services'

  printHeaderMessage "Creating the operator group"
  oc apply -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/operatorgroup/cp4waiops-emgr.yaml

  printHeaderMessage "Creating the Watson AIOps EventMGR subscription witin the IBM Operator Catalog"
  oc apply -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/subscription/ibm-aiops-orchestrator-emgr.yaml

  echo ""
  let LOOP_COUNT=1
  local CP4WAIOPS_EMGR_SUBSCRIPTION_READY="NOT_READY"
  while [ "${CP4WAIOPS_EMGR_SUBSCRIPTION_READY}" != "1"  ]
  do
        blinkWaitMessage "Waiting for subscription and operator(noi) Watson AIOps Event Manager to be installed before we proceed" 60
        CP4WAIOPS_EMGR_SUBSCRIPTION_READY=`oc get csv -A 2> /dev/null | grep noi 2> /dev/null | grep -c Succeeded`
        if [ "${CP4WAIOPS_EMGR_SUBSCRIPTION_READY}" == "1" ]  ;then
             printHeaderMessage "Watson AIOps Event Manager Subscription has been installed! "
             echo " "
             echo "   1.)   From the Red Hat OpenShift OLM UI, go to Operators > Installed Operators, and select IBM Cloud Pak for Watson AIOps Event Manager."
             echo "         Under Provided APIs > NOI select Create Instance."
             echo " "
             echo "   2.)   Use the Form view to configure the properties for the deployment, and select the Create button. For more information,"
             echo "         see Cloud operator properties Opens in a new tab in the IBM® Netcool® Operations Insight® documentation."
             econ " "
             echo "         Under the All Instances tab, an Event Manager instance appears."
             echo " "
             echo "         >>>> Please See Documentation Here: >>>>>:  https://www.ibm.com/docs/en/cloud-paks/cloud-pak-watson-aiops/${CP4WAIOPS_VERSION}?topic=manager-starter-installation"
             echo " "
             echo "         NOTE:  When creating the Event Manager instance use: default-dockercfg-xxxx as the Entitlement Secret"

        fi
        if [ $LOOP_COUNT -ge 20 ] ;then
            echo "${RED_TEXT}FAILED: Watson AIOPS Event Manager (noi) operator could not be installed. Timeout waiting.${RESET_TEXT}"
            echo ""
            echo "${RED_TEXT}Exiting Script!!!!!!!${RESET_TEXT}"
            exit 9
        fi
        let LOOP_COUNT=LOOP_COUNT+1
 done

}

##### sub functions ############
validOCPVersionCP4WAIOPS()
{
 if [[ "${CURRENT_SCRIPT_NAME}" == *build.sh ]];then
       if [ -n "${OCP_RELEASE}" ];then
              printHeaderMessage "Validate Version of OpenShift"
              validateOpenShiftVersion
              if [[ -n "${OCP_RELEASE}" ]]; then
                if [[ -z "${OCP_BASE_VERSION}" ]]; then
                  OCP_BASE_VERSION=`echo ${OCP_RELEASE} | sed "s/\.[0-9][0-9]//g"`
                  OCP_BASE_VERSION_LENGTH=`echo $OCP_BASE_VERSION | wc -c`
                  if [[ ${OCP_BASE_VERSION_LENGTH} -gt 4 ]]; then
                    OCP_BASE_VERSION=`echo ${OCP_BASE_VERSION} | sed "s/\.[0-9]$//g"`
                  fi
                fi
              fi
              case ${OCP_BASE_VERSION} in
                4.6|4.8)
                    echo "${BLUE_TEXT}PASSED ${RESET_TEXT} Supported version of OpenShift(${OCP_BASE_VERSION})"
                    ;;
                4.7|4.9)
                    SHOULD_EXIT=1
                    echo "${RED_TEXT}FAILED: Unsupported version of OpenShift(${OCP_BASE_VERSION}). Currently only supports - 4.6, 4.8 ${RESET_TEXT}"
                    ;;
                *)
                    SHOULD_EXIT=1
                    echo "${RED_TEXT}FAILED: Unsupported version number(${OCP_BASE_VERSION}). Currently only supports - 4.6, 4.8 ${RESET_TEXT}"
              esac
        else
            echo "${RED_TEXT}FAILED: Missing OCP_RELEASE variable or is blank. ${RESET_TEXT}"
        fi
        echo ""
        CP4WAIOPS_ZEN_VERSION=`oc get ZenService iaf-zen-cpdservice -n ${CP4WAIOPS_NAMESPACE} -o jsonpath='{.status.currentVersion} {"\n"}' 2> /dev/null`
        OCP_SERVER_VERSION=`oc version 2> /dev/null| grep Server | awk '{print $3}'`
 fi
}


prepareCP4WAIOPSInputFiles()
{
  mkdir -p ${TEMP_DIR}/${PRODUCT_SHORT_NAME}
  cd ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/
  cp -fR ${DIR}/templates/* ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/

  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@CP4WAIOPS_EMGR_NAMESPACE@/$CP4WAIOPS_EMGR_NAMESPACE/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@CP4WAIOPS_EMGR_SUBSCRIPTION_CHANNEL@/$CP4WAIOPS_EMGR_SUBSCRIPTION_CHANNEL/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@CP4WAIOPS_NAMESPACE@/$CP4WAIOPS_NAMESPACE/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@CP4WAIOPS_VERSION@/$CP4WAIOPS_VERSION/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@CP4WAIOPS_SUBSCRIPTION_CHANNEL@/$CP4WAIOPS_SUBSCRIPTION_CHANNEL/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@CP4WAIOPS_STORAGE_CLASS@/$CP4WAIOPS_STORAGE_CLASS/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@CP4WAIOPS_BLOCK_STORAGE_CLASS@/$CP4WAIOPS_BLOCK_STORAGE_CLASS/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@IBM_CLOUD_CATALOG_SOURCE@/$IBM_CLOUD_CATALOG_SOURCE/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@CP4WAIOPS_IMAGE_PULL_SECRET@/$CP4WAIOPS_IMAGE_PULL_SECRET/g"

}

displayCP4WAIOPSAdminConsoleInfo()
{
  CP4WAIOPS_URL=`oc get route -n ${CP4WAIOPS_NAMESPACE} cpd -o jsonpath="{.spec.host}{'\n'}"`
  if [ -n ${CP4WAIOPS_URL}  ]; then
      CP4WAIOPS_USER=`oc -n ibm-common-services get secret platform-auth-idp-credentials -o jsonpath='{.data.admin_username}' | base64 -d && echo`
      CP4WAIOPS_PASSWORD=`oc -n ibm-common-services get secret platform-auth-idp-credentials -o jsonpath="{.data.admin_password}" | base64 -d && echo`

      echo "${BLUE_TEXT}Here is the login info for the CP4WAIOPS Navigator console:"
      echo "##########################################################################################################${RESET_TEXT}"
      echo "AI Manager User             :      ${CP4WAIOPS_USER}"
      echo "AI Manager Password         :      ${CP4WAIOPS_PASSWORD}"
      echo "AI Manager Web Console      :      ${BLUE_TEXT}https://${CP4WAIOPS_URL}${RESET_TEXT}"
      printf "\n\n\n${RESET_TEXT}"
  else
    echo "${RED_TEXT}CP4WAIOPS URL is not available.${RESET_TEXT}"
    printf "\n\n\n"
  fi

}

displayCP4WAIOPSStatus()
{
  printHeaderMessage "Display Cloud Pak for Watson AI Ops"
  validOCPVersionCP4WAIOPS
  echo "Daffy Version                 :  ${DAFFY_VERSION}"
  echo "OpenShift Version             :  ${OCP_SERVER_VERSION}"
  local INSTALLATION_STATUS=`oc get Installation ibm-cp-watson-aiops -n ${CP4WAIOPS_NAMESPACE} -o jsonpath="{.status.phase}{'\n'}" 2> /dev/null`

  if [ -z ${INSTALLATION_STATUS} ]; then
        INSTALLATION_STATUS="Not Found"
  else
    if [ ${INSTALLATION_STATUS} != "InProgress" ]  && [ ${INSTALLATION_STATUS} != "Running" ]; then
        INSTALLATION_STATUS="Not Found"
    fi
  fi
  echo "Installation Status           :  ${INSTALLATION_STATUS} "

  local ZEN_STATUS=`oc get ZenService iaf-zen-cpdservice -n ${CP4WAIOPS_NAMESPACE} -o jsonpath="{.status.zenStatus}{'\n'}" 2> /dev/null`
  if [ -z ${ZEN_STATUS} ]; then
      ZEN_STATUS="Not Found"
  else
      if [ ${ZEN_STATUS} != "InProgress" ]  && [ ${ZEN_STATUS} != "Completed" ]; then
          ZEN_STATUS="Not Found"
      fi
  fi
  echo "Zen Status                    :  ${ZEN_STATUS} - ${CP4WAIOPS_ZEN_VERSION}"
  echo ""
}
