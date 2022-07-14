############################################################
#Author           : Jeff Imholz
#Author email     : jimholz@us.ibm.com
#Original Date    : 2022-05-01
#Initial Version  : v2022-05-01
############################################################
#Setup Variables
############################################################
validateCP4SECVersion()
{
  case ${CP4SEC_VERSION} in
    1.9)
        echo "${BLUE_TEXT}PASSED ${RESET_TEXT} Valid version CP4SEC_VERSION=${CP4SEC_VERSION}"
        ;;
     *)
       echo "${RED_TEXT}FAILED: Invalid version CP4SEC_VERSION=${CP4SEC_VERSION}${RESET_TEXT}"
       echo "${RED_TEXT}Current Supported Versions: 1.9${RESET_TEXT}"
       SHOULD_EXIT=1
       ;;
  esac
  OCP_SERVER_VERSION=`oc version | grep Server | awk '{print $3}'`
}

precheckCP4SEC()
{
  printHeaderMessage "Prechecks"
  prepareHost
  baseValidation
  getOpenShiftTools
  getIBMEntitlementKey
  variablePresent ${CP4SEC_VERSION} CP4SEC_VERSION
  variablePresent ${IBM_ENTITLEMENT_KEY} IBM_ENTITLEMENT_KEY
  variablePresent ${CP_REGISTRY} CP_REGISTRY
  variablePresent ${CP_REGISTRY_EMAIL} CP_REGISTRY_EMAIL
  validateCP4SECVersion
  case ${OCP_INSTALL_TYPE} in
    roks-msp)
        testIBMCloudLogin
        waitForROKSClusterReady
        ;;
    rosa-msp)
        ROSALoginCluster
        ;;
  esac
  validateStorage ${CP4SEC_STORAGE_CLASS}
  validateStorage ${CP4SEC_BLOCK_CLASS}
  validateOCPAccess
  validateCloudPakSize
  validOCPVersion
  #Make sure storage classes that we use exist
  shouldExit
  echo ""
  echo "All prechecks passed, lets get to work."
  echo ""

}

prepareCP4SECInputFiles()
{
  mkdir -p ${TEMP_DIR}/${PRODUCT_SHORT_NAME}
  cd ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/
  cp -fR ${DIR}/templates/* ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@PROJECT_NAME@/$PROJECT_NAME/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@CP4SEC_VERSION@/$CP4SEC_VERSION/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@CP4SEC_NAMESPACE@/$CP4SEC_NAMESPACE/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@CP4SEC_SUBSCRIPTION_CHANNEL@/$CP4SEC_SUBSCRIPTION_CHANNEL/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@CP4SEC_STORAGE_CLASS@/$CP4SEC_STORAGE_CLASS/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@CP4SEC_BLOCK_CLASS@/$CP4SEC_BLOCK_CLASS/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@IBM_CLOUD_CATALOG_SOURCE@/$IBM_CLOUD_CATALOG_SOURCE/g"
}

processCP4SECYaml()
{
  if [ "${1}" == "apply" ];then
    printHeaderMessage "Creating ${CP4SEC_NAMESPACE} Namespace"
    oc ${1} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/namespaces/namespace_cp4sec.yaml
    applyNameSpaceLabels ${CP4SEC_NAMESPACE} 'IBM CP4 Security Services'
    printHeaderMessage "Creating CP4Security CatalogSource"
    oc ${1} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/catalogsource/ibm-operator-catalog/catalogsource.yaml
    printHeaderMessage "Creating CP4Security OperatorGroup"
    oc ${1} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/operatorgroup/operatorgroup.yaml
    printHeaderMessage "Creating CP4Security Subscription"
    oc ${1} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/subscriptions/ibm-cp-security/cp4sec_subscription.yaml
    printHeaderMessage "Creating IBM Entitlement secret in CP4Security namespace"
    oc create secret docker-registry ibm-entitlement-key --docker-server=$CP_REGISTRY --docker-username=cp --docker-password=$IBM_ENTITLEMENT_KEY -n ${CP4SEC_NAMESPACE}
  else
    printHeaderMessage "Nothing to deploy"  ${RED_TEXT}
    SHOULD_EXIT=1
  fi
  echo ""

}

deployOCPServerless()
{
  printHeaderMessage "Deploying Openshift Knative Serverless"
  oc apply -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/subscriptions/individual-subscriptions/serverless_subscription.yaml
  # add wait for operator to be installed
  local OPERATOR_STATUS=`oc get csv 2> /dev/null | grep "serverless-operator" | awk '{print $(NF)}'`
  while [ "${OPERATOR_STATUS}" != "Succeeded" ]
  do
    blinkWaitMessage "Still waiting  - almost there, will keep checking every 10 seconds" 10
    OPERATOR_STATUS=`oc get csv 2> /dev/null | grep "serverless-operator" | awk '{print $(NF)}'`
  done
  echo "OpenShift Serverless Operator applied"
  echo "Applying knative serving custom resource"
  oc apply -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/customresource/serving.yaml
  printf "\n"
}

displayCP4SecurityStatus()
{
  printHeaderMessage "Display Cloud Pak for Security Status"
  validateCP4IVersion
  echo "Daffy Version                :   ${DAFFY_VERSION}"
  echo "OpenShift Versions           :   ${OCP_SERVER_VERSION}"
  echo ""
  printHeaderMessage "Here is the status of the ${CP4SEC_NAMESPACE} Operators:  "
  oc get csv -n openshift-operators -n ${CP4SEC_NAMESPACE}
  printf "\n\n\n${RESET_TEXT}"
}

waitForOCPServerlessToComplete()
{
  startWaitForServing=$SECONDS
  printHeaderMessage "Wait for Knative Serverless to complete"
  echo ""
  blinkWaitMessage "Waiting 1 minute before we start to check!" 60
  local OPERATOR_STATUS=`oc get knativeserving.operator.knative.dev/knative-serving -n knative-serving --template='{{range .status.conditions}}{{printf "%s=%s\n" .type .status}}{{end}}' | grep -c "Ready=True"`
  while [ "${OPERATOR_STATUS}" != "1" ]
  do
    blinkWaitMessage "Still waiting  - almost there, will keep checking every 10 seconds" 10
    OPERATOR_STATUS=`oc get knativeserving.operator.knative.dev/knative-serving -n knative-serving --template='{{range .status.conditions}}{{printf "%s=%s\n" .type .status}}{{end}}' | grep -c "Ready=True"`
  done
  echo "Knative Serverless is ready"
  now=$SECONDS
  let "diff=now-startWaitForServing"
  startWaitForServing=${diff}
  if (( $startWaitForServing > 60 )) ; then
      let "minutes=(startWaitForServing%3600)/60"
      let "seconds=(startWaitForServing%3600)%60"
      echo "Operator was created in $minutes minute(s) and $seconds second(s)"
  else
      echo "Operator was created in $startWaitForServing seconds (WOW insane speed, you have a great system)"
  fi
}

cp4SecurityCMDLine()
{
  printHeaderMessage "Downloading Cloud Pak for Security command line utility"
  POD=`$(oc get pod -n ${CP4SEC_NAMESPACE} --no-headers -lrun=cp-serviceability | cut -d' ' -f1)`
  oc -n ${CP4SEC_NAMESPACE} cp ${POD}:/opt/bin/linux/cpctl ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/cpctl && chmod +x ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/cpctl
  install -vm 0755 -o root ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/cpctl /usr/local/bin/cpctl &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/openldap.log
  cpctl load
  CPCTL_READY=`cpctl -v | grep -c version`
  if [ $CPCTL_READY == 1 ]; then
    echo "${BLUE_TEXT}Cloud Pak for Security Command Line installed"
  else
    cp4SecurityCMDLine
  fi
}

cp4SecurityLDAP()
{
  printHeaderMessage "Deploying OpenLDAP for Cloud Pak for Security"
  cpctl tools deploy_openldap --token $(oc whoami -t) --ldap_usernames 'secadmin,analyst1,analyst2,analyst3,analyst4,analyst5' --ldap_password ${CP4SEC_ADMIN_PWD} >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/openldap.log
}

cp4SecurityStatus()
{
  OCP_SERVER_VERSION=`oc version | grep Server | awk '{print $3}'`
  validateCP4SECVersion &>/dev/null
  printHeaderMessage "Cloud Pak for Security - All Status"
  echo "Daffy Version                               :  ${DAFFY_VERSION}"
  echo "OpenShift Version                           :  ${OCP_SERVER_VERSION}"
  echo "Bastion OS                                  :  ${OS_FLAVOR}"
  echo "Platform Install Type                       :  ${OCP_INSTALL_TYPE}"
  echo "Cloud Pak Versions                          :  ${CP4SEC_VERSION}"
  local CP4SEC_STATUS=`oc get CP4SThreatManagement threatmgmt -n ${CP4SEC_NAMESPACE} -o jsonpath='{.status.conditions[].type} {"\n"}' 2> /dev/null`
  if [ -z ${CP4SEC_STATUS} ]; then
    CP4SEC_STATUS="Not Found"
  fi
  echo "Cloud Pak for Security                      :  ${CP4SEC_STATUS} - ${CP4SEC_VERSION}"
  echo ""
}

deployThreatMgmt()
{
      printHeaderMessage "Deploy Threat Management"
      echo "Checking to make sure Cloud Pak for Security Operator is Installed"
      OPERATOR_STATUS=`oc get csv -n ${CP4SEC_NAMESPACE} 2> /dev/null | grep "ibm-cp-security" | awk '{print $(NF)}'`
      while [ "${OPERATOR_STATUS}" != "Succeeded" ]
      do
        blinkWaitMessage "Still waiting  - almost there, will keep checking every 10 seconds" 10
        OPERATOR_STATUS=`oc get csv -n ${CP4SEC_NAMESPACE} 2> /dev/null | grep "ibm-cp-security" | awk '{print $(NF)}'`
      done
      echo "Cloud Pak for Security Operator is installed"
      echo ""
      echo "Installing Threat Management for Cloud Pak for Security"
      oc apply -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/customresource/threatmgmt.yaml
      printf "\n"
      startWaitForThreatMgmt=$SECONDS
      OPERATOR_STATUS=`oc get CP4SThreatManagement threatmgmt -n ${CP4SEC_NAMESPACE} -o jsonpath='{.status.conditions} {"\n"}' | grep -c Success 2> /dev/null`
      if [ ${OPERATOR_STATUS} != "1" ]; then
          printHeaderMessage "Wait for Cloud Pak for Security Threat Management to complete - could take up to an hour or more"
          echo ""
          blinkWaitMessage "Waiting 30 minutes before we start to check!" 1800
          OPERATOR_STATUS=`oc get CP4SThreatManagement threatmgmt -n ${CP4SEC_NAMESPACE} -o jsonpath='{.status.conditions} {"\n"}' | grep -c Success 2> /dev/null`
            while [ ${OPERATOR_STATUS} != "1" ]
            do
               blinkWaitMessage "Still waiting  - almost there, will keep checking every 2 min" 120
               OPERATOR_STATUS=`oc get CP4SThreatManagement threatmgmt -n ${CP4SEC_NAMESPACE} -o jsonpath='{.status.conditions} {"\n"}' | grep -c Success 2> /dev/null`
            done
      fi
      echo "Cloud Pak for Security Threat Management is Successful"
      now=$SECONDS
      let "diff=now-startWaitForThreatMgmt"
      startWaitForThreatMgmt=${diff}
        if (( $startWaitForThreatMgmt > 60 )) ; then
           let "minutes=(startWaitForThreatMgmt%3600)/60"
           let "seconds=(startWaitForThreatMgmt%3600)%60"
           echo "Instance was created in $minutes minute(s) and $seconds second(s)"
        else
           echo "Instance was created in $startWaitForThreatMgmt seconds (WOW insane speed, you have a great system)"
        fi
}

displayCP4SecurityInfo()
{
  CP4SEC_PASSWORD=${CP4SEC_ADMIN_PWD}
  CP4SEC_URL=`oc get routes -n ${CP4SEC_NAMESPACE} isc-route-default -o jsonpath='{.status.ingress[].host} {"\n"}'`
  CP4SEC_USER=${CP4SEC_ADMIN}

  printHeaderMessage "Here is the login info for the CP4I Navigator console:"
  echo "Super User                   :      ${CP4SEC_USER}"
  echo "Password                     :      ${CP4SEC_PASSWORD}"
  echo "CP4Security Web Console      :      ${BLUE_TEXT}${CP4SEC_URL}${RESET_TEXT}"
  printf "\n\n\n${RESET_TEXT}"
}
