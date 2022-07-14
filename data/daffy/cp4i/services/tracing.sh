############################################################
#Author           : Jeff Imholz
#Author email     : jimholz@us.ibm.com
#Original Date    : 2022-03-04
#Initial Version  : v2022-03-04
############################################################
#Setup Variables
############################################################
#https://www.ibm.com/docs/en/cloud-paks/cp-integration/2021.4?topic=capabilities-transaction-tracing-deployment
cp4iServiceTracing()
{
  if [ "${1}" = "delete" ]; then
     printHeaderMessage "Cloud Pak for Integration Service - Operations Dashboard Tracing" ${RED_TEXT}
  else
      printHeaderMessage "Cloud Pak for Integration Service - Operations Dashboard Tracing"
  fi
  if [ "${CP4I_ENABLE_SERVICE_TRACING}" == "true" ]; then
      if [ ${1} == "apply" ]; then
            echo "Enabling Service now"
               blinkWaitMessage "Waiting for Operations Dashboard to be installed before we create instance" 10
               TRACING_OPERATOR_SUBSCRIPTION_READY=`oc get csv -n ${CP4I_NAMESPACE} | grep  ibm-integration-operations-dashboard 2> /dev/null | grep -c Succeeded`
                  if [ "${TRACING_OPERATOR_SUBSCRIPTION_READY}" == "1" ]  ;then
                     echo "${BLUE_TEXT}COMPLETE ${RESET_TEXT}Operations Dashboard Operator installed"
                     oc apply -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/customresource/tracing.yaml
                     echo ""
                     echo "Your request to install the service has been submitted.  Before continuing on, we will wait for this service to finish"
                     #echo "To check on the status of your service, you can run the following command:"
                     #echo "            ${DATA_DIR}/${PROJECT_NAME}/${PRODUCT_SHORT_NAME}/service.sh ${ENV_FILE_NAME} --TracingStatus"
                     echo ""
                  fi
      fi
  else
      if [ ${1} == "delete" ]; then
         echo "Removing Operand Request"
         oc delete operandrequest tracing-ibm-integration-operations-dashboard -n ${CP4I_NAMESPACE} 2> /dev/null
         echo ""
         echo "Removing Custom Resource"
         oc delete --grace-period=0 --force --ignore-not-found=true --include-uninitialized=true --timeout=30s -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/customresource/tracing.yaml 2> /dev/null
         oc delete crd operationsdashboards.integration.ibm.com 2> /dev/null
         oc delete crd operationsdashboardservicebindings.integration.ibm.com 2> /dev/null
         echo ""
         echo "Removing Service"
         oc delete OperationsDashboard tracing -n ${CP4I_NAMESPACE} 2> /dev/null
         echo ""
      fi
  fi
  echo ""
}

cp4iServiceTracingStatus()
{
  printHeaderMessage "Cloud Pak for Integration Service - Operations Dashboard Tracing"
  validateCP4IVersion &>/dev/null
  echo "Daffy Version                            :  ${DAFFY_VERSION}"
  echo "OpenShift Version                        :  ${OCP_SERVER_VERSION}"
  echo "Bastion OS                               :  ${OS_FLAVOR}"
  echo "Platform Install Type                    :  ${OCP_INSTALL_TYPE}"
  echo "Zen Version                              :  ${CP4I_ZEN_VERSION}"
  local AceDesign_VERSION=`oc get OperationsDashboard tracing --namespace=${CP4I_NAMESPACE} -o jsonpath='{.spec.version}' 2> /dev/null`
  if [ -z ${Tracing_VERSION} ]; then
    Tracing_VERSION=""
  fi
  #Status good locic, need to test -o jsonpath='{.status.message}'
  local Tracing_STATUS=`oc get OperationsDashboard tracing -n ${CP4I_NAMESPACE} -o jsonpath='{.status.phase}' 2> /dev/null`
  if [ -z ${Tracing_STATUS} ]; then
    Tracing_STATUS="Not Found"
  fi
  echo "Operations Dashboard                     :  ${Tracing_STATUS} - ${Tracing_VERSION}"
  echo "Pods:  "
  oc get pods -A -l 'app.kubernetes.io/instance=tracing'
  echo ""
  oc get pods -A -l 'release in (tracing)'
  echo ""
}
