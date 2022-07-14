############################################################
#Author           : Jeff Imholz
#Author email     : jimholz@us.ibm.com
#Original Date    : 2022-03-04
#Initial Version  : v2022-03-04
############################################################
#Setup Variables
############################################################
#https://www.ibm.com/docs/en/cloud-paks/cp-integration/2021.4?topic=capabilities-event-streams-deployment
cp4iServiceEventStreams()
{
  if [ "${1}" = "delete" ]; then
     printHeaderMessage "Cloud Pak for Integration Service - Event Streams Instance" ${RED_TEXT}
  else
     printHeaderMessage "Cloud Pak for Integration Service - Event Streams Instance"
  fi
  if [ "${CP4I_ENABLE_SERVICE_EVENTSTREAMS}" == "true" ]; then
      if [ ${1} == "apply" ]; then
            echo "Enabling Service now"
               blinkWaitMessage "Waiting for Event Streams Operator to be installed before we create instance" 10
               ES_OPERATOR_SUBSCRIPTION_READY=`oc get csv -n ${CP4I_NAMESPACE} | grep  ibm-eventstreams 2> /dev/null | grep -c Succeeded`
                  if [ ${ES_OPERATOR_SUBSCRIPTION_READY} == "1" ]  ;then
                     echo "${BLUE_TEXT}COMPLETE ${RESET_TEXT}Event Streams Operator installed"
                     oc apply -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/customresource/eventstreams.yaml
                     echo ""
                     echo "Your request to install the service has been submitted.  It can take up to 30 minutes."
                     echo "To check on the status of your service, you can run the following command:"
                     echo "            ${DATA_DIR}/${PROJECT_NAME}/${PRODUCT_SHORT_NAME}/service.sh ${ENV_FILE_NAME} --EventStreamsStatus"
                     echo ""
                  fi
      fi
  else
      if [ ${1} == "delete" ]; then
         echo "Removing Operand Request"
         oc delete operandrequest eventstreams-ibm-es-eventstreams -n ${CP4I_NAMESPACE} 2> /dev/null
         echo ""
         echo "Removing Custom Resource"
         oc delete --grace-period=0 --force --ignore-not-found=true --include-uninitialized=true --timeout=30s -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/customresource/eventstreams.yaml 2> /dev/null
         oc delete crd eventstreams.eventstreams.ibm.com 2> /dev/null
         oc delete crd eventstreamsgeoreplicators.eventstreams.ibm.com 2> /dev/null
         oc delete crd kafkaconnectors.eventstreams.ibm.com 2> /dev/null
         oc delete crd kafkaconnects.eventstreams.ibm.com 2> /dev/null
         oc delete crd kafkaconnects2is.eventstreams.ibm.com 2> /dev/null
         oc delete crd kafkamirrormaker2s.eventstreams.ibm.com 2> /dev/null
         oc delete crd kafkarebalances.eventstreams.ibm.com 2> /dev/null
         oc delete crd kafkas.eventstreams.ibm.com 2> /dev/null
         oc delete crd kafkatopics.eventstreams.ibm.com 2> /dev/null
         oc delete crd kafkausers.eventstreams.ibm.com 2> /dev/null
         echo ""
         echo "Removing Service"
         oc delete EventStreams eventstreams -n ${CP4I_NAMESPACE} 2> /dev/null
         echo ""
      fi
  fi
  echo ""
}

cp4iServiceEventStreamsStatus()
{
  printHeaderMessage "Cloud Pak for Integration Service - Event Streams Instance"
  validateCP4IVersion &>/dev/null
  echo "Daffy Version                            :  ${DAFFY_VERSION}"
  echo "OpenShift Version                        :  ${OCP_SERVER_VERSION}"
  echo "Bastion OS                               :  ${OS_FLAVOR}"
  echo "Platform Install Type                    :  ${OCP_INSTALL_TYPE}"
  echo "Zen Version                              :  ${CP4I_ZEN_VERSION}"
  local ES_VERSION=`oc get EventStreams eventstreams --namespace=${CP4I_NAMESPACE} -o jsonpath='{.spec.version}' 2> /dev/null`
  if [ -z ${ES_VERSION} ]; then
    ES_VERSION=""
  fi
  #Status good locic, need to test -o jsonpath='{.status.message}'
  local ES_STATUS=`oc get EventStreams eventstreams -n ${CP4I_NAMESPACE} -o jsonpath='{.status.phase}' 2> /dev/null`
  if [ -z ${ES_STATUS} ]; then
    ES_STATUS="Not Found"
  fi
  echo "Event Streams Instance                   :  ${ES_STATUS} - ${ES_VERSION}"
  echo "Pods:  "
  oc get pods -A -l 'app.kubernetes.io/instance=eventstreams'
  echo ""
  #oc get pods -A -l 'release in (mq0-ibm-mq-0)'
  #echo ""
}
