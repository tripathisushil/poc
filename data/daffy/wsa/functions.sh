#!/bin/bash
############################################################
#Author           : Kyle Dawson
#Author email     : Kyle.Dawson@us.ibm.com
#Original Date    : 2022-01-21
#Initial Version  : v2022-02-15
############################################################
#https://www.ibm.com/docs/en/ws-automation?topic=installing-openshift-cli
precheckWSA()
{
  printHeaderMessage "Precheck WebSphere Automation"
  baseValidation
  printHeaderMessage "Validate WebSphere Automation Version"
  validateWSAVersion
  prepareHost
  getIBMEntitlementKey
  variablePresent ${IBM_ENTITLEMENT_KEY} IBM_ENTITLEMENT_KEY
  resourcePresent ${DIR}/templates/customresource/webspherehealth.yaml
  resourcePresent ${DIR}/templates/customresource/webspheresecure.yaml
  resourcePresent ${DIR}/templates/customresource/wsa-small-profile.yaml
  resourcePresent ${DIR}/templates/customresource/wsa-automationui.yaml
  resourcePresent ${DIR}/templates/namespaces/openshift-operators.yaml
  resourcePresent ${DIR}/templates/namespaces/websphere-automation.yaml
  resourcePresent ${DIR}/templates/catalogsource/ibm-operator-catalog/catalogsource.yaml
  resourcePresent ${DIR}/templates/operatorgroup/ibm-websphere-automation.yaml
  resourcePresent ${DIR}/templates/subscriptions/ibm-websphere-automation/subscription.yaml

  validateOCPAccess
  shouldExit
  echo ""
  echo "All prechecks passed, lets get to work."
  echo ""
}

precheckWSAService()
{
  printHeaderMessage "Precheck WebSphere Automation Service"
  baseValidation
  prepareHost
  resourcePresent ${DIR}/templates/catalogsource/ibm-operator-catalog/catalogsource.yaml
  resourcePresent ${DIR}/templates/operatorgroup/ibm-websphere-automation.yaml
  resourcePresent ${DIR}/templates/subscriptions/ibm-websphere-automation/subscription.yaml

  validateOCPAccess
  if [ ${SHOULD_EXIT} == 1 ] ;then
    echo ""
    echo ""
    echo "${RED_TEXT}Missing above required resources/permissions. Exiting Script!!!!!!!${RESET_TEXT}"
    echo ""
    echo ""
    exit 1
  fi
  echo ""
  echo "All prechecks passed, lets get to work."
  echo ""
}

validateWSAVersion()
{
  case ${CPWSA_VERSION} in
    1.3)
        CP4WSA_SUBSCRIPTION_CHANNEL="v1.3"
        AUTOBASE_VERSION="2.0.3"
        AUTOMATIONUI_VERSION="1.3.0"
        echo "${BLUE_TEXT}PASSED ${RESET_TEXT} Version: ${CPWSA_VERSION} is valid!"
        ;;
    1.2)
        CP4WSA_SUBSCRIPTION_CHANNEL="v1.2"
        AUTOBASE_VERSION="1.2.1"
        AUTOMATIONUI_VERSION="1.2.0"
        echo "${BLUE_TEXT}PASSED ${RESET_TEXT} Version: ${CPWSA_VERSION} is valid!"
        ;;
     *)
       echo "${RED_TEXT}FAILED: Invalid version CPWSA_VERSION=${CPWSA_VERSION}${RESET_TEXT}"
       echo "${RED_TEXT}Current Supported Versions: 1.3 or 1.2${RESET_TEXT}"
       SHOULD_EXIT=1
       ;;
  esac
}

wsaValidateBaseVersion()
{

  WSA_ZEN_VERSION=`oc get ZenService iaf-zen-cpdservice -n ${WSA_INSTANCE_NAMESPACE} -o jsonpath='{.status.currentVersion} {"\n"}' 2> /dev/null`
  if [ -z ${WSA_ZEN_VERSION} ]; then
    WSA_ZEN_VERSION="Not Found"
  fi
  OCP_SERVER_VERSION=`oc version 2> /dev/null| grep Server | awk '{print $3}'`
  if [ -z ${OCP_SERVER_VERSION} ]; then
    OCP_SERVER_VERSION="Not Found"
  fi

}
prepareWSAInputFiles()
{
  printHeaderMessage "Prepare WebSphere Automation Input Files"
  mkdir -p ${TEMP_DIR}/${PRODUCT_SHORT_NAME}
  cd ${TEMP_DIR}/${PRODUCT_SHORT_NAME}
  cp -fR ${DIR}/templates/* ${TEMP_DIR}/${PRODUCT_SHORT_NAME}
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@WSA_OPERATOR_NAMESPACE@/$WSA_OPERATOR_NAMESPACE/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@WSA_INSTANCE_NAMESPACE@/$WSA_INSTANCE_NAMESPACE/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@WSA_STORAGE_CLASS@/$WSA_STORAGE_CLASS/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@WSA_BLOCK_CLASS@/$WSA_BLOCK_CLASS/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@WSA_STORAGE_SIZE@/$WSA_STORAGE_SIZE/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@CP4WSA_SUBSCRIPTION_CHANNEL@/$CP4WSA_SUBSCRIPTION_CHANNEL/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@AUTOBASE_VERSION@/$AUTOBASE_VERSION/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@AUTOMATIONUI_VERSION@/$AUTOMATIONUI_VERSION/g"
}
processWSANameSpaces()
{
  if [ "${1}" == "apply" ];then
    printHeaderMessage "Creating WebSphere Automation Namespaces"
  else
    printHeaderMessage "Deleting WebSphere Automation Namespaces"  ${RED_TEXT}
    echo "This has not been implemented yet!!!!!!!!"
    return
  fi
  oc ${1} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/namespaces/websphere-automation.yaml
  applyNameSpaceLabels ${WSA_INSTANCE_NAMESPACE} 'IBM Websphere Automation'
  oc ${1} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/operatorgroup/ibm-websphere-automation.yaml
  #if [ ${WSA_OPERATOR_NAMESPACE} == "openshift-operators" ] ; then
  #  oc ${1} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/namespaces/openshift-operators.yaml
  #  applyNameSpaceLabels ${WSA_OPERATOR_NAMESPACE} 'OpenShift Operators'
  #  oc ${1} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/operatorgroup/ibm-websphere-automation.yaml
  #elif [ ${WSA_OPERATOR_NAMESPACE} == ${WSA_INSTANCE_NAMESPACE} ]; then
  #  oc ${1} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/operatorgroup/ibm-websphere-automation.yaml
  #fi
}
processWSACatalogSource()
{
  if [ "${1}" == "apply" ];then
    printHeaderMessage "Creating WebSphere Automation Catalogs"
  else
    printHeaderMessage "Deleting  WebSphere Automation Catalogs"  ${RED_TEXT}
    echo "This has not been implemented yet!!!!!!!!"
    return
  fi
  oc ${1} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/catalogsource/ibm-operator-catalog/catalogsource.yaml
}
processWSAOperators()
{
  if [ "${1}" == "apply" ];then
    printHeaderMessage "Creating WebSphere Automation Operators"
  else
    printHeaderMessage "Deleting WSA Operators"  ${RED_TEXT}
    echo "This has not been implemented yet!!!!!!!!"
    return
  fi
  local WSA_OPERATOR_GROUP=`oc -n ${WSA_OPERATOR_NAMESPACE} get operatorgroup | grep -c operatorgroup`
  while [ ${WSA_OPERATOR_GROUP} == 0 ]
  do
    blinkWaitMessage "waiting for wsa operator group to be there" 20
    WSA_OPERATOR_GROUP=`oc -n ${WSA_OPERATOR_NAMESPACE} get operatorgroup | grep -c operatorgroup`
  done
  echo "Applying WSA Subscription"
  oc ${1} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/subscriptions/ibm-websphere-automation/subscription.yaml

}

displayWSAAdminConsoleInfo()
{
  printHeaderMessage "Display WebSphere Automation Console Info"
  WSA_URL=`oc get websphereautomation wsa -n ${WSA_INSTANCE_NAMESPACE} -o jsonpath='{.status.endpoints.automationUI}'`
  WSA_PASSWORD=`oc -n ${IBM_COMMON_SERVICES_NAMESPACE} get secret platform-auth-idp-credentials -o jsonpath={.data.admin_password} | base64 --decode`
  echo "${BLUE_TEXT}Here is the login info for the WebSphere Automation console:"
  echo "##########################################################################################################${RESET_TEXT}"
  echo "Super User            :      admin"
  echo "Password              :      ${WSA_PASSWORD}"
  echo "WSA Web Console       :      ${BLUE_TEXT}${WSA_URL}${RESET_TEXT}"
  echo ""
  echo ""
}

displayWSAStatus()
{
  WSA_ZEN_VERSION=`oc get ZenService iaf-zen-cpdservice -n ${WSA_INSTANCE_NAMESPACE} -o jsonpath='{.status.currentVersion} {"\n"}' 2> /dev/null`
  if [ -z ${WSA_ZEN_VERSION} ]; then
    WSA_ZEN_VERSION="Not Found"
  fi
  printHeaderMessage "Display WebSphere Automation Status"
  wsaValidateBaseVersion
  echo "Daffy Version                            :  ${DAFFY_VERSION}"
  echo "Bastion OS                               :  ${OS_FLAVOR}"
  echo "Platform Install Type                    :  ${OCP_INSTALL_TYPE}"
  echo "OpenShift Version                        :  ${OCP_SERVER_VERSION}"
  echo "Zen Version                              :  ${WSA_ZEN_VERSION}"

  #Status good locic, need to test -o jsonpath='{.status.message}'
  local WSA_VERSION=`oc get WebSphereAutomation wsa -n ${WSA_INSTANCE_NAMESPACE} -o jsonpath='{.status.versions.reconciled}' 2> /dev/null`
  local WSA_STATUS=`oc get WebSphereAutomation wsa -n ${WSA_INSTANCE_NAMESPACE} -o jsonpath='{.status.conditions[0].status}' 2> /dev/null`
  if [ ${WSA_STATUS} == "False" ]; then
      WSA_STATUS="Not Ready"
  else
      WSA_STATUS="Ready"
  fi
  echo "WebSphere Automation Instance            :  ${WSA_STATUS} - ${WSA_VERSION}"
  local WSA_HEALTH_VERSION=`oc get WebSphereHealth wsa-health -n ${WSA_INSTANCE_NAMESPACE} -o jsonpath='{.status.versions.reconciled}' 2> /dev/null`
  local WSA_HEALTH_STATUS=`oc get WebSphereHealth wsa-health -n ${WSA_INSTANCE_NAMESPACE} -o jsonpath='{.status.conditions[0].status}' 2> /dev/null`
  if [ ${WSA_HEALTH_STATUS} == "False" ]; then
      WSA_HEALTH_STATUS="Not Ready"
  else
      WSA_HEALTH_STATUS="Ready"
  fi
  echo "WebSphere Automation Health Instance     :  ${WSA_HEALTH_STATUS} - ${WSA_HEALTH_VERSION}"
  local WSA_SECURE_VERSION=`oc get WebSphereSecure wsa-secure -n ${WSA_INSTANCE_NAMESPACE} -o jsonpath='{.status.versions.reconciled}' 2> /dev/null`
  local WSA_SECURE_STATUS=`oc get WebSphereSecure wsa-secure -n ${WSA_INSTANCE_NAMESPACE} -o jsonpath='{.status.conditions[0].status}' 2> /dev/null`
  if [ ${WSA_SECURE_STATUS} == "False" ]; then
      WSA_SECURE_STATUS="Not Ready"
  else
      WSA_SECURE_STATUS="Ready"
  fi
  echo "WebSphere Automation Secure Instance     :  ${WSA_SECURE_STATUS} - ${WSA_SECURE_VERSION}"
  echo ""
  echo "WebSphere Automation Pods:  "
  oc get pods -A -l 'app.kubernetes.io/part-of=wsa'
  echo ""
  echo "WebSphere Health Pods:  "
  oc get pods -A -l 'app.kubernetes.io/part-of=wsa-health'
  echo ""
  echo "WebSphere Secure Pods:  "
  oc get pods -A -l 'app.kubernetes.io/part-of=wsa-secure'
  echo ""
}

processWSAInstance()
{
  printHeaderMessage "Processing WebSphere Automation Instance"
  echo "Verifying WebSphere Automation operators are installed"
  WSA_OPERATOR="ibm-websphere-automation"
  local WEBSPHERE_SUBSCRIPTION_READY=`oc get csv -n ${WSA_OPERATOR_NAMESPACE} 2> /dev/null | grep ${WSA_OPERATOR} 2> /dev/null | grep -c Succeeded`
  while [ "${WEBSPHERE_SUBSCRIPTION_READY}" == "0" ]
  do
      blinkWaitMessage "Waiting for WebSphere Automation Operator to be installed before we continue(Wait upto 10 min), checking every 10 sec" 10
      WEBSPHERE_SUBSCRIPTION_READY=`oc get csv -n ${WSA_OPERATOR_NAMESPACE} 2> /dev/null | grep ${WSA_OPERATOR} 2> /dev/null | grep -c Succeeded`
  done
  WSA_AUTO_CORE_OPERATOR="ibm-automation-core"
  local WSA_AUTO_CORE_READY=`oc get csv -n ${WSA_OPERATOR_NAMESPACE} 2> /dev/null | grep ${WSA_AUTO_CORE_OPERATOR} 2> /dev/null | grep -c Succeeded`
  while [ "${WSA_AUTO_CORE_READY}" == "0" ]
  do
      blinkWaitMessage "Waiting for WebSphere Automation Foundation Core Operator to be installed before we create instance(Wait upto 10 min), checking every 10 sec" 10
      WSA_AUTO_CORE_READY=`oc get csv -n ${WSA_OPERATOR_NAMESPACE} 2> /dev/null | grep ${WSA_AUTO_CORE_OPERATOR} 2> /dev/null | grep -c Succeeded`
  done
  echo "WebSphere Automation Operator & WebSphere Automation Foundation Core Operator are installed"
  echo "Applying WebSphere Automation UI"
  oc apply -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/customresource/wsa-automationui.yaml
  local WSA_AUTOUI_READY=`oc get AutomationUIConfig wsa-automationui -n ${WSA_INSTANCE_NAMESPACE} | grep -c True 2> /dev/null`
  while [ "${WSA_AUTOUI_READY}" == "0" ]
  do
      blinkWaitMessage "Waiting for WSA Automation UI Config to be Ready" 30
      WSA_AUTOUI_READY=`oc get AutomationUIConfig wsa-automationui -n ${WSA_INSTANCE_NAMESPACE} | grep -c True 2> /dev/null`
  done
  echo "${BLUE_TEXT}COMPLETE ${RESET_TEXT}Successfully installed Websphere Automation UI CustomResource"
  applyNameSpaceLabels ibm-common-services 'IBM Common Services'
  echo "Applying WebSphere Automation Small Profile"
  oc apply -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/customresource/wsa-small-profile.yaml
          #    echo "${BLUE_TEXT}COMPLETE ${RESET_TEXT}Successfully installed Websphere Automation Small Profile"
          #if [ ${WSA_SECURE} == "true" ]; then
          #    oc ${1} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/customresource/webspheresecure.yaml
          #    echo "${BLUE_TEXT}COMPLETE ${RESET_TEXT}Successfully installed Websphere Secure CustomResource"
          #    applyNameSpaceLabels ibm-common-services 'IBM Common Services'
          #    break
          #  else
          #    oc ${1} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/customresource/wsa-small-profile.yaml
          #    echo "${BLUE_TEXT}COMPLETE ${RESET_TEXT}Successfully installed Websphere Automation Small Profile"
              #oc ${1} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/customresource/webspherehealth.yaml
              #echo "${BLUE_TEXT}COMPLETE ${RESET_TEXT}Successfully installed Websphere Health CustomResource"
              #applyNameSpaceLabels ibm-common-services 'IBM Common Services'
          #    break
          #fi
        #fi
        #let LOOP_COUNT=LOOP_COUNT+1
        #if [ $LOOP_COUNT -ge 60 ] ;then
        #    echo "${RED_TEXT}FAILED:  ${WSA_OPERATOR} subscription could not be installed. Timeout waiting.${RESET_TEXT}"
        #    echo "IBM WebSphere Automation Operator instance could not be found."
        #    echo "After some time, you can run the following command to finsish the setup"
        #    if [ ${WSA_SECURE} == "true" ]; then
        #        echo "            oc apply -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/customresource/webspheresecure.yaml"
        #    else
        #        echo "            oc apply -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/customresource/webspherehealth.yaml"
        #    fi
        #    echo ""
        #    exit 99
        #fi
  #done
  echo "Your request to install the service has been submitted.  It can take an hour or more more to complete"
}
