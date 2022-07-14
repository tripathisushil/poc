############################################################
#Author           : Jeff Imholz
#Author email     : jimholz@us.ibm.com
#Original Date    : 2022-03-04
#Initial Version  : v2022-03-04
############################################################
#Setup Variables
############################################################
#https://www.ibm.com/docs/en/cloud-paks/cp-integration/2021.4?topic=capabilities-application-integration-dashboard-deployment
cp4iServiceAceDash()
{
  if [ "${1}" = "delete" ]; then
     printHeaderMessage "Cloud Pak for Integration Service - Ace Dashboard" ${RED_TEXT}
  else
      printHeaderMessage "Cloud Pak for Integration Service - Ace Dashboard"
  fi
  if [ "${CP4I_ENABLE_SERVICE_ACEDASH}" == "true" ]; then
      if [ ${1} == "apply" ]; then
            echo "Enabling Service now"
               blinkWaitMessage "Waiting for Ace Operator to be installed before we create instance" 10
               ACE_OPERATOR_SUBSCRIPTION_READY=`oc get csv -n ${CP4I_NAMESPACE} | grep  ibm-appconnect 2> /dev/null | grep -c Succeeded`
                  if [ "${ACE_OPERATOR_SUBSCRIPTION_READY}" == "1" ]  ;then
                     echo "${BLUE_TEXT}COMPLETE ${RESET_TEXT}ACE Operator installed"
                     oc apply -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/customresource/ace-dashboard.yaml
                     echo ""
                     echo "Your request to install the service has been submitted.  It can take up to 30 minutes."
                     echo "To check on the status of your service, you can run the following command:"
                     echo "            ${DATA_DIR}/${PROJECT_NAME}/${PRODUCT_SHORT_NAME}/service.sh ${ENV_FILE_NAME} --AceDashStatus"
                     echo ""
                  fi

      fi
  else
      if [ ${1} == "delete" ]; then
         echo "Removing Operand Request"
         oc delete operandrequest ace-dashboard-dash -n ${CP4I_NAMESPACE} 2> /dev/null
         echo ""
         echo "Removing Custom Resource"
         oc delete --grace-period=0 --force --ignore-not-found=true --include-uninitialized=true --timeout=30s -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/customresource/ace-dashboard.yaml 2> /dev/null
         oc delete crd dashboards.appconnect.ibm.com 2> /dev/null
         echo ""
         echo "Removing Service"
         oc delete Dashboard ace-dashboard -n ${CP4I_NAMESPACE} 2> /dev/null
         echo ""
      fi
  fi
  echo ""
}

cp4iServiceAceDashStatus()
{
  printHeaderMessage "Cloud Pak for Integration Service - ACE Dashboard"
  validateCP4IVersion &>/dev/null
  echo "Daffy Version                            :  ${DAFFY_VERSION}"
  echo "OpenShift Version                        :  ${OCP_SERVER_VERSION}"
  echo "Bastion OS                               :  ${OS_FLAVOR}"
  echo "Platform Install Type                    :  ${OCP_INSTALL_TYPE}"
  echo "Zen Version                              :  ${CP4I_ZEN_VERSION}"
  local AceDesign_VERSION=`oc get Dashboard ace-dashboard --namespace=${CP4I_NAMESPACE} -o jsonpath='{.spec.version}' 2> /dev/null`
  if [ -z ${AceDash_VERSION} ]; then
    AceDash_VERSION=""
  fi
  #Status good locic, need to test -o jsonpath='{.status.message}'
  local AceDash_STATUS=`oc get Dashboard ace-dashboard -n ${CP4I_NAMESPACE} -o jsonpath='{.status.reconcileStatus}' 2> /dev/null`
  if [ -z ${AceDash_STATUS} ]; then
    AceDash_STATUS="Not Found"
  fi
  echo "Ace Dashboard                      :  ${AceDash_STATUS} - ${AceDash_VERSION}"
  echo "Pods:  "
  oc get pods -A -l 'app.kubernetes.io/instance=ace-dashboard'
  echo ""
  oc get pods -A -l 'release in (ace-dashboard)'
  echo ""
}
