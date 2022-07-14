############################################################
#Author           : Jeff Imholz
#Author email     : jimholz@us.ibm.com
#Original Date    : 2022-03-04
#Initial Version  : v2022-03-04
############################################################
#Setup Variables
############################################################
#https://www.ibm.com/docs/en/cloud-paks/cp-integration/2021.4?topic=capabilities-messaging-capability-deployment
cp4iServiceMQHA()
{
  if [ "${1}" = "delete" ]; then
     printHeaderMessage "Cloud Pak for Integration Service - MQ Prod HA Instance" ${RED_TEXT}
  else
     printHeaderMessage "Cloud Pak for Integration Service - MQ Prod HA Instance"
  fi
  if [ "${CP4I_ENABLE_SERVICE_MQHA}" == "true" ]; then
      if [ ${1} == "apply" ]; then
            echo "Enabling Service now"
               blinkWaitMessage "Waiting for MQ Operator to be installed before we create instance" 10
               MQ_OPERATOR_SUBSCRIPTION_READY=`oc get csv -n ${CP4I_NAMESPACE} | grep  ibm-mq 2> /dev/null | grep -c Succeeded`
                  if [ ${MQ_OPERATOR_SUBSCRIPTION_READY} == "1" ]  ;then
                     echo "${BLUE_TEXT}COMPLETE ${RESET_TEXT}MQ Operator installed"
                     if [ ${CP4I_ENABLE_SERVICE_TRACING} == "true" ]; then
                        echo ""
                        echo "Updating Service for Tracing"
                        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@TRACING_ENABLED@/true/g"
                     else
                        echo "Continuing deployment of MQ HA Instance without Tracing"
                        find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@TRACING_ENABLED@/false/g"
                     fi
                        oc apply -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/customresource/mq-ha.yaml
                        echo ""
                        echo "Your request to install the service has been submitted.  It can take up to 30 minutes."
                        echo "To check on the status of your service, you can run the following command:"
                        echo "            ${DATA_DIR}/${PROJECT_NAME}/${PRODUCT_SHORT_NAME}/service.sh ${ENV_FILE_NAME} --MQHAStatus"
                        echo ""
                  fi
                  #check to see if OD Service binding exists
                  ODSERVICE_BINDING=`oc get OperationsDashboardServiceBinding -n ${CP4I_NAMESPACE} | grep -c od-service-binding 2> /dev/null`
                  if [ ${ODSERVICE_BINDING} == "1" ] ;then
                     echo "ODService Binding exists, continuing on"
                  else
                     echo "Applying ODService binding"
                     oc apply -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/customresource/mqhaodtracing.yaml -n ${CP4I_NAMESPACE}
                  fi
      fi
  else
      if [ ${1} == "delete" ]; then
         echo "Removing Operand Request"
         oc delete operandrequest mq-ha-ibm-mq -n ${CP4I_NAMESPACE} 2> /dev/null
         echo ""
         echo "Removing Custom Resource"
         oc delete --grace-period=0 --force --ignore-not-found=true --include-uninitialized=true --timeout=30s -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/customresource/mq-ha.yaml 2> /dev/null
         oc delete crd queuemanagers.mq.ibm.com 2> /dev/null
         echo ""
         echo "Removing Service"
         oc delete QueueManager mq-ha -n ${CP4I_NAMESPACE} 2> /dev/null
         echo ""
      fi
  fi
  echo ""
}

cp4iServiceMQHAStatus()
{
  printHeaderMessage "Cloud Pak for Integration Service - MQ Prod HA Instance"
  validateCP4IVersion &>/dev/null
  echo "Daffy Version                            :  ${DAFFY_VERSION}"
  echo "OpenShift Version                        :  ${OCP_SERVER_VERSION}"
  echo "Bastion OS                               :  ${OS_FLAVOR}"
  echo "Platform Install Type                    :  ${OCP_INSTALL_TYPE}"
  echo "Zen Version                              :  ${CP4I_ZEN_VERSION}"
  local MQ_VERSION=`oc get QueueManager mq-ha --namespace=${CP4I_NAMESPACE} -o jsonpath='{.spec.version}' 2> /dev/null`
  if [ -z ${MQ_VERSION} ]; then
    MQ_VERSION=""
  fi
  #Status good locic, need to test -o jsonpath='{.status.message}'
  local MQ_STATUS=`oc get QueueManager mq-ha -n ${CP4I_NAMESPACE} -o jsonpath='{.status.phase}' 2> /dev/null`
  if [ -z ${MQ_STATUS} ]; then
    MQ_STATUS="Not Found"
  fi
  echo "MQ Prod HA Instance                      :  ${MQ_STATUS} - ${MQ_VERSION}"
  echo "Pods:  "
  oc get pods -A -l 'app.kubernetes.io/instance=mq-ha'
  echo ""
  #oc get pods -A -l 'release in (mq0-ibm-mq-0)'
  #echo ""
}
