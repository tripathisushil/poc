############################################################
#Author           : Kyle Dawson
#Author email     : Kyle.Dawson@us.ibm.com
#Original Date    : 2022-01-25
#Initial Version  : v2022-0D-Beta
############################################################
#Setup Variables
############################################################
precheckCP4BAService()
{
    printHeaderMessage "Precheck CP4BA Services"
    validateCP4BAVersion
    getOpenShiftTools
    validateOCPAccess
    validateCloudPakSize
    cp4baValidateService
    if [ ! -z "${CP4BA_DEPLOYMENT_STARTER_SERVICE}"  ]; then
      if [ ${CP4BA_DEPLOYMENT_STARTER_SERVICE} == "samples" ] ; then
          if [ ! -z "${CP4BA_DEPLOYMENT_STARTER_SERVICE_SAMPLE}" ] ; then
              if [ -f  ${DIR}/templates/services/samples/${CP4BA_DEPLOYMENT_STARTER_SERVICE_SAMPLE}.yaml ]; then
                echo "${BLUE_TEXT}PASSED ${RESET_TEXT} Valid Sample CP4BA Service given - ${CP4BA_DEPLOYMENT_STARTER_SERVICE_SAMPLE}"
              else
                echo "${RED_TEXT}WARN ${RESET_TEXT} Samples service set but sample giving does not exit. (${CP4BA_DEPLOYMENT_STARTER_SERVICE_SAMPLE})"
                echo "Possible options: ${DIR}/templates/services/samples"
                ls  ${DIR}/templates/services/samples/*.yaml | sed 's/\.yaml//g' | sed 's/.*\///g'
                SHOULD_EXIT=1
              fi
          else
              echo "${RED_TEXT}WARN ${RESET_TEXT} Samples service set but no sample giving.  Missing CP4BA_DEPLOYMENT_STARTER_SERVICE_SAMPLE="
              echo "Possible options: ${DIR}/templates/services/samples"
              ls  ${DIR}/templates/services/samples/*.yaml | sed 's/\.yaml//g' | sed 's/.*\///g'
              SHOULD_EXIT=1
          fi
      else
         resourcePresent ${DIR}/templates/services/${CP4BA_DEPLOYMENT_STARTER_SERVICE}-starter.yaml
      fi
    fi
    case ${OCP_INSTALL_TYPE} in
      roks-msp)
          validateStorage ${CP4BA_AUTO_STORAGE_CLASS_FAST_ROKS}
          ;;
      *)
          validateStorage ${CP4BA_AUTO_STORAGE_CLASS_OCP}
          ;;
    esac
    if [ "${CP4BA_ENABLE_SERVICE_OPS}" == "true" ] ;then
       cp4baOPSPreCheck
    fi
    shouldExit
    echo ""
    echo "All prechecks passed, lets get to work."
    echo ""
}
prepareCP4BAServiceInputFiles()
{
    printHeaderMessage "Prepare CP4BA Service Files"
    mkdir -p ${TEMP_DIR}/${PRODUCT_SHORT_NAME}
    cd ${TEMP_DIR}/${PRODUCT_SHORT_NAME}
    cp -fR ${DIR}/templates/* ${TEMP_DIR}/${PRODUCT_SHORT_NAME}
    DAFFY_UNIQUE_ID_TEMP=`echo ${DAFFY_UNIQUE_ID} | sed "s/@/__at__/g"`
    find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@PROJECT_NAME@/$PROJECT_NAME/g"
    find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@CURRENT_DATE_TIME@/$CURRENT_DATE_TIME/g"
    find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@DAFFY_UNIQUE_ID_TEMP@/$DAFFY_UNIQUE_ID_TEMP/g"
    find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@DAFFY_VERSION@/$DAFFY_VERSION/g"

    find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@CP_REGISTRY@/$CP_REGISTRY/g"
    find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@CP_DEPLOYMENT_PLATFORM@/$CP_DEPLOYMENT_PLATFORM/g"
    find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@CP4BA_DEPLOYMENT_NAME@/$CP4BA_DEPLOYMENT_NAME/g"
    find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@CP4BA_DEPLOYMENT_PROFILE_SIZE@/$CP4BA_DEPLOYMENT_PROFILE_SIZE/g"
    find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@CP4BA_DEPLOYMENT_LICENSE@/$CP4BA_DEPLOYMENT_LICENSE/g"
    find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@CP4BA_VERSION@/$CP4BA_VERSION/g"
    find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@CP4BA_ROOT_CA_SECRET@/$CP4BA_ROOT_CA_SECRET/g"
    find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@CP4BA_IFIX@/$CP4BA_IFIX/g"
    find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@CRD_DEBUG@/$CRD_DEBUG/g"
    find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@CRD_NO_LOG@/$CRD_NO_LOG/g"

    #Storage Class
    find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@CP4BA_AUTO_STORAGE_CLASS_OCP@/$CP4BA_AUTO_STORAGE_CLASS_OCP/g"
    find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@CP4BA_AUTO_STORAGE_CLASS_OCP_BLOCK@/$CP4BA_AUTO_STORAGE_CLASS_OCP_BLOCK/g"
    find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@CP4BA_AUTO_STORAGE_CLASS_OCP_SLOW@/$CP4BA_AUTO_STORAGE_CLASS_OCP_SLOW/g"
    find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@CP4BA_AUTO_STORAGE_CLASS_OCP_MEDIUM@/$CP4BA_AUTO_STORAGE_CLASS_OCP_MEDIUM/g"
    find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@CP4BA_AUTO_STORAGE_CLASS_OCP_FAST@/$CP4BA_AUTO_STORAGE_CLASS_OCP_FAST/g"

    #Version tags
    find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@CP4BA_OPENLDAP_VERSION@/$CP4BA_OPENLDAP_VERSION/g"
    find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@CP4BA_BUSYBOX_VERSION@/$CP4BA_BUSYBOX_VERSION/g"
    find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@CP4BA_PHP_LDAP_ADMIN_VERSION@/$CP4BA_PHP_LDAP_ADMIN_VERSION/g"
    find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@CP4BA_BAN_NAVIGATOR_VERSION@/$CP4BA_BAN_NAVIGATOR_VERSION/g"
    find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@CP4BA_ECM_CPE_VERSION@/$CP4BA_ECM_CPE_VERSION/g"
    find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@CP4BA_ECM_GRAPHQL_VERSION@/$CP4BA_ECM_GRAPHQL_VERSION/g"
    find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@CP4BA_ECM_ICCSAP_VERSION@/$CP4BA_ECM_ICCSAP_VERSION/g"
    find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@CP4BA_ECM_IER_VERSION@/$CP4BA_ECM_IER_VERSION/g"
    find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@CP4BA_ECM_TM_VERSION@/$CP4BA_ECM_TM_VERSION/g"
    find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@CP4BA_ECM_CSS_VERSION@/$CP4BA_ECM_CSS_VERSION/g"
    find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@CP4BA_ECM_CMIS_VERSION@/$CP4BA_ECM_CMIS_VERSION/g"
    find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@CP4BA_KEYTOOL_JOB_CONTAINER_VERSION@/$CP4BA_KEYTOOL_JOB_CONTAINER_VERSION/g"
    find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@CP4BA_DBCOMPATIBILITY_INIT_CONTAINER_VERSION@/$CP4BA_DBCOMPATIBILITY_INIT_CONTAINER_VERSION/g"
    find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@CP4BA_KEYTOOL_INIT_CONTAINER_VERSION@/$CP4BA_KEYTOOL_INIT_CONTAINER_VERSION/g"
    find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@CP4BA_UMSREGISTRATION_INITJOB_VERSION@/$CP4BA_UMSREGISTRATION_INITJOB_VERSION/g"
    find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@CP4BA_RESOURCE_REGISTRY_CONFIGURATION_VERSION@/$CP4BA_RESOURCE_REGISTRY_CONFIGURATION_VERSION/g"

    #OPS
    find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@CP4BA_OPS_ML_NAMESPACE@/$CP4BA_OPS_ML_NAMESPACE/g"


    case ${CP4BA_IFIX} in
        IF005|IF007|IF008)
          find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/.*busybox.*//g"
          find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/.*phpldapadmin.*//g"
          find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/.*tag: $//g"
          sed -i '/^$/d' ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services/*.yaml
    esac

    cp4baODMPrepareFiles
    cp4baFilenetPrepareFiles
    cp4baBAWPrepareFiles
    echo "${BLUE_TEXT}COMPLETE ${RESET_TEXT}All install files moved to ${TEMP_DIR}/${PRODUCT_SHORT_NAME} and updated based on your environment."
    echo ""
}
cp4baServiceEstimateTimes()
{
  case ${CP4BA_DEPLOYMENT_SERVICE} in
    decisions)
          printHeaderMessage "CP4BA Service Estimates - ${CP4BA_DEPLOYMENT_SERVICE}"
          echo "Your request to install the service has been submitted.  It can take 2 hours or more more to complete"
          echo ""
          ;;
    content)
          printHeaderMessage "CP4BA Service Estimates - ${CP4BA_DEPLOYMENT_SERVICE}"
          echo "Your request to install the service has been submitted.  It can take 2 hours or more more to complete"
          echo ""
          ;;
    content-decisions)
          printHeaderMessage "CP4BA Service Estimates - ${CP4BA_DEPLOYMENT_SERVICE}"
          echo "Your request to install the service has been submitted.  It can take 3 hourss or more to complete"
          echo ""
          ;;
  esac
}
cp4baServiceStatus()
{
  case ${CP4BA_DEPLOYMENT_SERVICE} in
    samples)
        cp4baHighLevelStatus
        cp4baStatusDump
        cp4baFilenetStatus
        cp4baBAWStatus
        cp4baBAIStatus
        cp4baODMStatus
        ;;
    content-decisions)
        cp4baHighLevelStatus
        cp4baStatusDump
        cp4baFilenetStatus
        cp4baBAIStatus
        cp4baODMStatus
        ;;
    content)
        cp4baHighLevelStatus
        cp4baStatusDump
        cp4baFilenetStatus
        cp4baBAIStatus
        ;;
    decisions)
        cp4baHighLevelStatus
        cp4baStatusDump
        cp4baBAIStatus
        cp4baODMStatus
        ;;
    workflow)
        cp4baHighLevelStatus
        cp4baStatusDump
        cp4baBAWStatus
        cp4baBAIStatus
        ;;
  esac
}

cp4baServiceConsole()
{

  case ${CP4BA_DEPLOYMENT_SERVICE} in
    samples)
        cp4baConfigMapDump
        cp4baODMConsole
        cp4baFilenetConsole
        cp4baBAIConsole
        cp4baBAWConsole
        cp4baLDAPConsole
        ;;
    content-decisions)
        cp4baConfigMapDump
        cp4baODMConsole
        cp4baFilenetConsole
        cp4baBAIConsole
        cp4baLDAPConsole
        ;;
    content)
        cp4baConfigMapDump
        cp4baFilenetConsole
        cp4baBAIConsole
        cp4baLDAPConsole
        ;;
    decisions)
        cp4baConfigMapDump
        cp4baODMConsole
        cp4baBAIConsole
        cp4baLDAPConsole
        ;;
    workflow)
        cp4baConfigMapDump
        cp4baBAWConsole
        cp4baBAIConsole
        ;;
  esac
  if [ "${CP4BA_ENABLE_SERVICE_OPS}" == "true" ]; then
    cp4baOPSDisplaySwaggerURL
  fi
}
cp4baDeployService()
{

  printHeaderMessage "Deploy Cloud Pak for Business Automation - ${CP4BA_DEPLOYMENT_SERVICE} ${DEPLOYMENT_TYPE} service"
  echo ""
  if [[  "${DEPLOYMENT_TYPE}" ==  "starter"  ]]; then
    local STARTER_PREFIX="Starter"
  fi
  let LOOP_COUNT=1
  local ICP4BA_OPERATOR_READY="NOT_READY"
  while [ "${ICP4BA_OPERATOR_READY}" != "1"  ]
  do
        blinkWaitMessage "Waiting for ibm-cp4a-operator to be installed before we create instance." 10
        ICP4BA_OPERATOR_READY=`oc get csv -n ${CP4BA_AUTO_NAMESPACE} 2> /dev/null | grep ibm-cp4a-operator 2> /dev/null | grep -c Succeeded`
        if [ "${ICP4BA_OPERATOR_READY}" == "1" ]  ;then
          echo "${BLUE_TEXT}COMPLETE ${RESET_TEXT}ibm-cp4a-operator is ready."
          if [ ! -z  "${CP4BA_DEPLOYMENT_STARTER_SERVICE_SAMPLE}"  ]; then
              local DEPLOYMENT_RESULT=`oc apply -n ${CP4BA_AUTO_NAMESPACE} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services/samples/${CP4BA_DEPLOYMENT_STARTER_SERVICE_SAMPLE}.yaml  2>&1  | tee  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/cp4a-service-deployment-${CP4BA_DEPLOYMENT_STARTER_SERVICE_SAMPLE}.log  | grep -c "created\|unchanged\|configured"`
          else
              local DEPLOYMENT_RESULT=`oc apply -n ${CP4BA_AUTO_NAMESPACE} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services/${CP4BA_DEPLOYMENT_SERVICE}-${DEPLOYMENT_TYPE}.yaml  2>&1  | tee  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/cp4a-service-deployment-${CP4BA_DEPLOYMENT_SERVICE}-${DEPLOYMENT_TYPE}.log  | grep -c "created\|unchanged\|configured"`
          fi
          if [  ${DEPLOYMENT_RESULT} -eq 1  ]; then
            if [ ! -z  "${CP4BA_DEPLOYMENT_STARTER_SERVICE_SAMPLE}"  ]; then
                cat ${LOG_DIR}/${PRODUCT_SHORT_NAME}/cp4a-service-deployment-${CP4BA_DEPLOYMENT_STARTER_SERVICE_SAMPLE}.log
                echo "${BLUE_TEXT}SUCCESS ${RESET_TEXT} Deployed the following YAML - ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services/samples/${CP4BA_DEPLOYMENT_STARTER_SERVICE_SAMPLE}.yaml"
            else
                cat ${LOG_DIR}/${PRODUCT_SHORT_NAME}/cp4a-service-deployment-${CP4BA_DEPLOYMENT_SERVICE}-${DEPLOYMENT_TYPE}.log
                echo "${BLUE_TEXT}SUCCESS ${RESET_TEXT} Deployed the following YAML - ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services/${CP4BA_DEPLOYMENT_SERVICE}-${DEPLOYMENT_TYPE}.yaml"
            fi
            cp4baServiceEstimateTimes
            echo "To watch the operator logs, you can run the following command:"
            echo "                         ${BLUE_TEXT}oc logs -n ${CP4BA_AUTO_NAMESPACE} --tail=100 -f deployment/ibm-cp4a-operator | grep -v proxy${RESET_TEXT}"
            echo ""
            echo "Or you can get status of all components via this command:"
            echo "                         ${BLUE_TEXT}${DATA_DIR}/${PROJECT_NAME}/${PRODUCT_SHORT_NAME}/service.sh ${ENV_FILE_NAME} --${STARTER_PREFIX}Status${RESET_TEXT}"
            echo ""
            echo "Or you can get console connection info with the following command:"
            echo "                        ${BLUE_TEXT}${DATA_DIR}/${PROJECT_NAME}/${PRODUCT_SHORT_NAME}/service.sh ${ENV_FILE_NAME} --${STARTER_PREFIX}Console${RESET_TEXT}"
            echo ""
          else
                echo "${RED_TEXT}FAILED ${RESET_TEXT} Failed to deploy Service Yaml${RESET_TEXT}"
                echo "YAML - ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services/${CP4BA_DEPLOYMENT_SERVICE}-${DEPLOYMENT_TYPE}.yaml"
                echo "Result from deployment:"
                cat ${LOG_DIR}/${PRODUCT_SHORT_NAME}/cp4a-service-deployment-${CP4BA_DEPLOYMENT_SERVICE}-${DEPLOYMENT_TYPE}.log
          fi
        fi
        let LOOP_COUNT=LOOP_COUNT+1
        if [ $LOOP_COUNT -ge 61 ] ;then
            echo "${RED_TEXT}FAILED ${RESET_TEXT} ibm-cp4a-operator operator could not be installed. Timeout waiting.${RESET_TEXT}"
            echo "ibm-cp4a-operator instance could not be found."
            echo ""
            break
        fi
  done
  echo ""
}
cp4baHighLevelStatus()
{
  validateCP4BAVersion
  local MESSAGE1=`oc get ICP4ACluster icp4adeploy -n ${CP4BA_AUTO_NAMESPACE} -o jsonpath='{.status.conditions[0].message}' 2> /dev/null | head -n 1`
  if [ -z  "${MESSAGE1}"  ]; then
    MESSAGE1=`oc get ICP4ACluster icp4adeploy -n ${CP4BA_AUTO_NAMESPACE} -o jsonpath='{.status.conditions[0].reason}' 2> /dev/null | head -n 1`
  fi
  if [ "${MESSAGE1}"  == "---" ]; then
      MESSAGE1=`oc get ICP4ACluster icp4adeploy -n ${CP4BA_AUTO_NAMESPACE} -o jsonpath='{.status.conditions[0].message}' 2> /dev/null | head -n 2| tail -1 `
  fi
  local MESSAGE2=`oc get ICP4ACluster icp4adeploy -n ${CP4BA_AUTO_NAMESPACE} -o jsonpath='{.status.conditions[1].message}' 2> /dev/null | head -n 1`
  printHeaderMessage "CP4BA Service Status"
  echo "Daffy Version                            :  ${DAFFY_VERSION}"
  echo "Bastion OS                               :  ${OS_FLAVOR}"
  echo "Platform Install Type                    :  ${OCP_INSTALL_TYPE}"
  echo "OpenShift Version                        :  ${OCP_SERVER_VERSION}"
  echo "CP4BA Version                            :  ${CP4BA_VERSION} ${CP4BA_IFIX}"
  echo "Project/Namespace                        :  ${CP4BA_AUTO_NAMESPACE}"
  echo "Zen Version                              :  ${CP4BA_ZEN_VERSION}"
  echo "Message 1                                :  ${MESSAGE1}"
  echo "Message 2                                :  ${MESSAGE2}"
}

cp4baLDAPConsole()
{
  #printHeaderMessage "LDAP Console "
  oc get cm ${CP4BA_DEPLOYMENT_NAME}-cp4ba-access-info -n ${CP4BA_AUTO_NAMESPACE} -o=jsonpath='{.data.openldap-access-info}' &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ldap-console.log
  #local USERNAME=`cat  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ldap-console.log | grep "username"  | awk '{print $2}'| head -n 1`
  #echo "Username                                   : ${USERNAME}"
  #local PASSWORD=`cat  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ldap-console.log | grep "password"  | awk '{print $2}'| head -n 1`
  #echo "Password                                   : ${PASSWORD}"
  ##################################################
  #local LDAP_URL=`cat  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ldap-console.log | grep "ldapwebconsole\|phpldapadmin"  | awk '{print $1}'| head -n 1`
  #echo "LDAP URL                                   : ${BLUE_TEXT}${LDAP_URL}${RESET_TEXT}"

}
cp4baConfigMapDump()
{
  oc get cm ${CP4BA_DEPLOYMENT_NAME}-cp4ba-access-info -n ${CP4BA_AUTO_NAMESPACE} -o yaml  &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/${CP4BA_DEPLOYMENT_NAME}-cp4ba-access-info.yaml
  echo "Config Map Dump - ${LOG_DIR}/${PRODUCT_SHORT_NAME}/${CP4BA_DEPLOYMENT_NAME}-cp4ba-access-info.yaml"
  echo ""
}
cp4baStatusDump()
{
  oc get ICP4ACluster ${CP4BA_DEPLOYMENT_NAME} -n ${CP4BA_AUTO_NAMESPACE} -o jsonpath='{.status.components}' 2> /dev/null 1> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/${CP4BA_DEPLOYMENT_NAME}-cp4ba-status-info.yaml
  if [ -s ${LOG_DIR}/${PRODUCT_SHORT_NAME}/${CP4BA_DEPLOYMENT_NAME}-cp4ba-status-info.yaml ]; then
    cat  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/${CP4BA_DEPLOYMENT_NAME}-cp4ba-status-info.yaml | jq . >  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/${CP4BA_DEPLOYMENT_NAME}-cp4ba-status-info.yaml.tmp
    mv ${LOG_DIR}/${PRODUCT_SHORT_NAME}/${CP4BA_DEPLOYMENT_NAME}-cp4ba-status-info.yaml.tmp ${LOG_DIR}/${PRODUCT_SHORT_NAME}/${CP4BA_DEPLOYMENT_NAME}-cp4ba-status-info.yaml
    echo "Status Dump                              :  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/${CP4BA_DEPLOYMENT_NAME}-cp4ba-status-info.yaml"
  else
    echo "Status Dump                              :  Not Found"
  fi
}
