############################################################
#Author           : Jeff Imholz
#Author email     : jimholz@us.ibm.com
#Original Date    : 2022-03-04
#Initial Version  : v2022-03-04
############################################################
#Setup Variables
############################################################
#https://www.ibm.com/docs/en/cloud-paks/cp-integration/2021.4?topic=capabilities-application-integration-designer-deployment
cp4iServiceAceDesign()
{
  if [ "${1}" = "delete" ]; then
     printHeaderMessage "Cloud Pak for Integration Service - Ace Designer" ${RED_TEXT}
  else
      printHeaderMessage "Cloud Pak for Integration Service - Ace Designer"
  fi
  if [ "${CP4I_ENABLE_SERVICE_ACEDESIGN}" == "true" ]; then
      if [ ${1} == "apply" ]; then
            echo "Enabling Service now"
               blinkWaitMessage "Waiting for ACE Operator to be installed before we create instance" 10
               ACE_OPERATOR_SUBSCRIPTION_READY=`oc get csv -n ${CP4I_NAMESPACE} | grep  ibm-appconnect 2> /dev/null | grep -c Succeeded`
                  if [ "${ACE_OPERATOR_SUBSCRIPTION_READY}" == "1" ]  ;then
                     echo "${BLUE_TEXT}COMPLETE ${RESET_TEXT}ACE Operator installed"
                     oc apply -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/customresource/ace-designer.yaml
                     echo ""
                     echo "Your requset to install the service has been submitted.  It can take up to 30 minutes."
                     echo "To check on the status of your service, you can run the following command:"
                     echo "            ${DATA_DIR}/${PROJECT_NAME}/${PRODUCT_SHORT_NAME}/service.sh ${ENV_FILE_NAME} --AceDesignStatus"
                     echo ""
                  fi

      fi
  else
      if [ ${1} == "delete" ]; then
         echo "Removing Operand Request"
         oc delete operandrequest ace-design-designer -n ${CP4I_NAMESPACE} 2> /dev/null
         echo ""
         echo "Removing Custom Resource"
         oc delete --grace-period=0 --force --ignore-not-found=true --include-uninitialized=true --timeout=30s -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/customresource/ace-designer.yaml 2> /dev/null
         oc delete crd designerauthorings.appconnect.ibm.com 2> /dev/null
         echo ""
         echo "Removing Service"
         oc delete DesignerAuthoring ace-design -n ${CP4I_NAMESPACE} 2> /dev/null
         echo ""
      fi
  fi
  echo ""
}

cp4iServiceAceDesignStatus()
{
  printHeaderMessage "Cloud Pak for Integration Service - ACE Designer"
  validateCP4IVersion &>/dev/null
  echo "Daffy Version                            :  ${DAFFY_VERSION}"
  echo "OpenShift Version                        :  ${OCP_SERVER_VERSION}"
  echo "Bastion OS                               :  ${OS_FLAVOR}"
  echo "Platform Install Type                    :  ${OCP_INSTALL_TYPE}"
  echo "Zen Version                              :  ${CP4I_ZEN_VERSION}"
  local AceDesign_VERSION=`oc get DesignerAuthoring ace-design --namespace=${CP4I_NAMESPACE} -o jsonpath='{.spec.version}' 2> /dev/null`
  if [ -z ${AceDesign_VERSION} ]; then
    AceDesign_VERSION=""
  fi
  #Status good locic, need to test -o jsonpath='{.status.message}'
  local AceDesign_STATUS=`oc get DesignerAuthoring ace-design -n ${CP4I_NAMESPACE} -o jsonpath='{.status.reconcileStatus}' 2> /dev/null`
  if [ -z ${AceDesign_STATUS} ]; then
    AceDesign_STATUS="Not Found"
  fi
  echo "Ace Designer                      :  ${AceDesign_STATUS} - ${AceDesign_VERSION}"
  echo "Pods:  "
  oc get pods -A -l 'app.kubernetes.io/instance=ace-design'
  echo ""
}
