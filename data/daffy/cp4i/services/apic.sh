############################################################
#Author           : Jeff Imholz
#Author email     : jimholz@us.ibm.com
#Original Date    : 2022-03-04
#Initial Version  : v2022-03-04
############################################################
#Setup Variables
############################################################
#https://www.ibm.com/docs/en/cloud-paks/cp-integration/2021.4?topic=capabilities-api-management-deployment
cp4iServiceAPIC()
{
  if [ "${1}" = "delete" ]; then
     printHeaderMessage "Cloud Pak for Integration Service - API Connect Instance" ${RED_TEXT}
  else
     printHeaderMessage "Cloud Pak for Integration Service - API Connect Instance"
  fi
  if [ "${CP4I_ENABLE_SERVICE_APIC}" == "true" ]; then
      if [ ${1} == "apply" ]; then
            echo "Enabling Service now"
               blinkWaitMessage "Waiting for APIC Operator to be installed before we create instance" 10
               APIC_OPERATOR_SUBSCRIPTION_READY=`oc get csv -n ${CP4I_NAMESPACE} | grep  ibm-apic 2> /dev/null | grep -c Succeeded`
                  if [ ${APIC_OPERATOR_SUBSCRIPTION_READY} == "1" ]  ;then
                     echo "${BLUE_TEXT}COMPLETE ${RESET_TEXT}APIC Operator installed"
                     if [ ${CP4I_ENABLE_SERVICE_TRACING} == "true" ]; then
                        echo ""
                        echo "Updating Service for Tracing"
                        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@TRACING_ENABLED@/true/g"
                     else
                        echo "Continuing deployment of MQ Single Instance without Tracing"
                        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@TRACING_ENABLED@/false/g"
                     fi
                        oc apply -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/customresource/apic.yaml
                        echo ""
                        echo "Your request to install the service has been submitted.  It can take up to 45 minutes."
                        echo "To check on the status of your service, you can run the following command:"
                        echo "            ${DATA_DIR}/${PROJECT_NAME}/${PRODUCT_SHORT_NAME}/service.sh ${ENV_FILE_NAME} --APICStatus"
                        echo ""
                  fi
                  # Check to see if odservicebinding exists first
                  ODSERVICE_BINDING=`oc get OperationsDashboardServiceBinding -n ${CP4I_NAMESPACE} | grep -c od-service-binding 2> /dev/null`
                  if [ ${ODSERVICE_BINDING} == "1" ] ;then
                     echo "ODService Binding exists, continuing on"
                  else
                    echo "Applying ODService binding"
                    oc apply -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/customresource/apicodtracing.yaml -n ${CP4I_NAMESPACE}
                  fi
      fi
  else
      if [ ${1} == "delete" ]; then
         echo "Removing Operand Request"
         oc delete operandrequest apic-min -n ${CP4I_NAMESPACE} 2> /dev/null
         echo ""
         echo "Removing Custom Resource"
         oc delete --grace-period=0 --force --ignore-not-found=true --include-uninitialized=true --timeout=30s -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/customresource/apic.yaml 2> /dev/null
         oc delete apiconnectclusters.apiconnect.ibm.com 2> /dev/null
         echo ""
         echo "Removing Service"
         oc delete APIConnectCluster apic-min -n ${CP4I_NAMESPACE} 2> /dev/null
         echo ""
      fi
  fi
  echo ""
}

cp4iServiceAPICStatus()
{
  printHeaderMessage "Cloud Pak for Integration Service - API Connect Instance"
  validateCP4IVersion &>/dev/null
  echo "Daffy Version                            :  ${DAFFY_VERSION}"
  echo "OpenShift Version                        :  ${OCP_SERVER_VERSION}"
  echo "Bastion OS                               :  ${OS_FLAVOR}"
  echo "Platform Install Type                    :  ${OCP_INSTALL_TYPE}"
  echo "Cloud Pak for Integration Version        :  ${CP4I_VERSION}"
  echo "Zen Version                              :  ${CP4I_ZEN_VERSION}"
  local APIC_VERSION=`oc get APIConnectCluster apic-min --namespace=${CP4I_NAMESPACE} -o jsonpath='{.spec.version}' 2> /dev/null`
  if [ -z ${APIC_VERSION} ]; then
    APIC_VERSION=""
  fi
  #Status good locic, need to test -o jsonpath='{.status.message}'
  local APIC_STATUS=`oc get APIConnectCluster apic-min -n ${CP4I_NAMESPACE} -o jsonpath='{.status.phase}' 2> /dev/null`
  if [ -z ${APIC_STATUS} ]; then
    APIC_STATUS="Not Found"
  fi
  echo "API Connect Instance                     :  ${APIC_STATUS} - ${APIC_VERSION}"
  echo "Pods:  "
  oc get pods -A -l 'app.kubernetes.io/part-of=apic-min'
  oc get pods -A -l 'app.kubernetes.io/part-of=ibm-datapower-apic-min-gw'
  echo ""
  #oc get pods -A -l 'release in (mq0-ibm-mq-0)'
  #echo ""
}
