############################################################
#Author           : Kyle Dawson
#Author email     : Kyle.Dawson@us.ibm.com
#Original Date    : 2022-01-25
#Initial Version  : v2022-02-15
############################################################
cp4baODMConsole()
{
  printHeaderMessage "Decision Console"
  #CP4BA_ODM_URL_DC=`oc get ICP4ACluster ${CP4BA_DEPLOYMENT_NAME} -o jsonpath='{.status.endpoints[?(@.name=="ODM Decision Center")]}'  | jq | grep uri | awk '{print $2}' | sed 's/\"//g'`
  #CP4BA_ODM_URL_RES=`oc get ICP4ACluster ${CP4BA_DEPLOYMENT_NAME} -o jsonpath='{.status.endpoints[?(@.name=="ODM Decision Server Console")]}'  | jq | grep uri | awk '{print $2}'| sed 's/\"//g'`
  #echo ${CP4BA_ODM_URL_DC}
  #echo ${CP4BA_ODM_URL_RES}
    oc get cm ${CP4BA_DEPLOYMENT_NAME}-cp4ba-access-info -n ${CP4BA_AUTO_NAMESPACE} -o=jsonpath='{.data.odm-access-info}' &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/odm-console.log
  ODM_USERNAME=`cat  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/odm-console.log | grep "username"  | awk '{print $4}'`
  echo "Username                                   : ${ODM_USERNAME}"
  ODM_PASSWORD=`cat  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/odm-console.log | grep "password"  | awk '{print $4}'`
  echo "Password                                   : ${ODM_PASSWORD}"
  ODM_DC_URL=`cat  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/odm-console.log | grep "ODM Decision Center"  | awk '{print $5}'`
  echo "Decision Center                            : ${BLUE_TEXT}${ODM_DC_URL}${RESET_TEXT}"
  ODM_DR_URL=`cat  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/odm-console.log | grep "ODM Decision Runner"  | awk '{print $5}'`
  echo "Decision Runner                            : ${BLUE_TEXT}${ODM_DR_URL}${RESET_TEXT}"
  ODM_RES_URL=`cat  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/odm-console.log | grep "ODM Decision Server Console"  | awk '{print $6}'`
  echo "Decision Server Console                    : ${BLUE_TEXT}${ODM_RES_URL}${RESET_TEXT}"
  ODM_RESRUN_URL=`cat  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/odm-console.log | grep "ODM Decision Server Runtime"  | awk '{print $6}'`
  echo "Decision Server Runtime                    : ${BLUE_TEXT}${ODM_RESRUN_URL}${RESET_TEXT}"


}
cp4baODMStatus()
{
    printHeaderMessage "CP4BA Service Status - Decisions"
    rm -fR ${LOG_DIR}/${PRODUCT_SHORT_NAME}/odm-status.log 2> /dev/null
    if [  -z "${STATUS_COMPONENTS}" ]; then
      oc get ICP4ACluster  ${CP4BA_DEPLOYMENT_NAME} -n ${CP4BA_AUTO_NAMESPACE} -o yaml 2> /dev/null   |  sed 's/\"//g' | sed 's/,//g'  | sed 's/://g' | sed 's/{//g' | sed 's/}//g'  &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/odm-status.log
    else
      oc get ICP4ACluster  ${CP4BA_DEPLOYMENT_NAME} -n ${CP4BA_AUTO_NAMESPACE} -o jsonpath='{.status.components.odm}' 2> /dev/null  | jq  . |  sed 's/\"//g' | sed 's/,//g'  | sed 's/://g' | sed 's/{//g' | sed 's/}//g'  &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/odm-status.log
    fi

    CP4BA_ODM_STATUS=`cat ${LOG_DIR}/${PRODUCT_SHORT_NAME}/odm-status.log | grep odmDecisionCenterDeployment | awk '{print $2}'`
    if [ -z ${CP4BA_ODM_STATUS}  ]; then
      CP4BA_ODM_STATUS="Not Found"
    fi
    echo "odmDecisionCenterDeployment              :  ${CP4BA_ODM_STATUS}"

    CP4BA_ODM_STATUS=`cat ${LOG_DIR}/${PRODUCT_SHORT_NAME}/odm-status.log | grep odmDecisionCenterService | awk '{print $2}'`
    if [ -z ${CP4BA_ODM_STATUS}  ]; then
      CP4BA_ODM_STATUS="Not Found"
    fi
    echo "odmDecisionCenterService                 :  ${CP4BA_ODM_STATUS}"

    CP4BA_ODM_STATUS=`cat ${LOG_DIR}/${PRODUCT_SHORT_NAME}/odm-status.log | grep odmDecisionCenterZenIntegration | awk '{print $2}'`
    if [ -z ${CP4BA_ODM_STATUS}  ]; then
      CP4BA_ODM_STATUS="Not Found"
    fi
    echo "odmDecisionCenterZenIntegration          :  ${CP4BA_ODM_STATUS}"

    CP4BA_ODM_STATUS=`cat ${LOG_DIR}/${PRODUCT_SHORT_NAME}/odm-status.log | grep odmDecisionRunnerDeployment | awk '{print $2}'`
    if [ -z ${CP4BA_ODM_STATUS}  ]; then
      CP4BA_ODM_STATUS="Not Found"
    fi
    echo "odmDecisionRunnerDeployment              :  ${CP4BA_ODM_STATUS}"

    CP4BA_ODM_STATUS=`cat ${LOG_DIR}/${PRODUCT_SHORT_NAME}/odm-status.log | grep odmDecisionRunnerService | awk '{print $2}'`
    if [ -z ${CP4BA_ODM_STATUS}  ]; then
      CP4BA_ODM_STATUS="Not Found"
    fi
    echo "odmDecisionRunnerService                 :  ${CP4BA_ODM_STATUS}"

    CP4BA_ODM_STATUS=`cat ${LOG_DIR}/${PRODUCT_SHORT_NAME}/odm-status.log | grep odmDecisionRunnerZenIntegration | awk '{print $2}'`
    if [ -z ${CP4BA_ODM_STATUS}  ]; then
      CP4BA_ODM_STATUS="Not Found"
    fi
    echo "odmDecisionRunnerZenIntegration          :  ${CP4BA_ODM_STATUS}"

    CP4BA_ODM_STATUS=`cat ${LOG_DIR}/${PRODUCT_SHORT_NAME}/odm-status.log | grep odmDecisionServerConsoleDeployment | awk '{print $2}'`
    if [ -z ${CP4BA_ODM_STATUS}  ]; then
      CP4BA_ODM_STATUS="Not Found"
    fi
    echo "odmDecisionServerConsoleDeployment       :  ${CP4BA_ODM_STATUS}"

    CP4BA_ODM_STATUS=`cat ${LOG_DIR}/${PRODUCT_SHORT_NAME}/odm-status.log | grep odmDecisionServerConsoleService | awk '{print $2}'`
    if [ -z ${CP4BA_ODM_STATUS}  ]; then
      CP4BA_ODM_STATUS="Not Found"
    fi
    echo "odmDecisionServerConsoleService          :  ${CP4BA_ODM_STATUS}"

    CP4BA_ODM_STATUS=`cat ${LOG_DIR}/${PRODUCT_SHORT_NAME}/odm-status.log | grep odmDecisionServerConsoleZenIntegration | awk '{print $2}'`
    if [ -z ${CP4BA_ODM_STATUS}  ]; then
      CP4BA_ODM_STATUS="Not Found"
    fi
    echo "odmDecisionServerConsoleZenIntegration   :  ${CP4BA_ODM_STATUS}"

    CP4BA_ODM_STATUS=`cat ${LOG_DIR}/${PRODUCT_SHORT_NAME}/odm-status.log | grep odmDecisionServerRuntimeDeployment | awk '{print $2}'`
    if [ -z ${CP4BA_ODM_STATUS}  ]; then
      CP4BA_ODM_STATUS="Not Found"
    fi
    echo "odmDecisionServerRuntimeDeployment       :  ${CP4BA_ODM_STATUS}"

    CP4BA_ODM_STATUS=`cat ${LOG_DIR}/${PRODUCT_SHORT_NAME}/odm-status.log | grep odmDecisionServerRuntimeService | awk '{print $2}'`
    if [ -z ${CP4BA_ODM_STATUS}  ]; then
      CP4BA_ODM_STATUS="Not Found"
    fi
    echo "odmDecisionServerRuntimeService          :  ${CP4BA_ODM_STATUS}"

    CP4BA_ODM_STATUS=`cat ${LOG_DIR}/${PRODUCT_SHORT_NAME}/odm-status.log | grep odmDecisionServerRuntimeZenIntegration | awk '{print $2}'`
    if [ -z ${CP4BA_ODM_STATUS}  ]; then
      CP4BA_ODM_STATUS="Not Found"
    fi
    echo "odmDecisionServerRuntimeZenIntegration   :  ${CP4BA_ODM_STATUS}"

    CP4BA_ODM_STATUS=`cat ${LOG_DIR}/${PRODUCT_SHORT_NAME}/odm-status.log | grep odmOIDCRegistrationJob | awk '{print $2}'`
    if [ -z ${CP4BA_ODM_STATUS}  ]; then
      CP4BA_ODM_STATUS="Not Found"
    fi
    echo "odmOIDCRegistrationJob                   :  ${CP4BA_ODM_STATUS}"

}
cp4baODMPrepareFiles()
{
  #decisionCenter
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DEPLOYMENT_STARTER_ODM_DC_REPLICA_COUNT@/$CP4BA_DEPLOYMENT_STARTER_ODM_DC_REPLICA_COUNT/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DEPLOYMENT_STARTER_ODM_DC_REQUEST_CPU@/$CP4BA_DEPLOYMENT_STARTER_ODM_DC_REQUEST_CPU/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DEPLOYMENT_STARTER_ODM_DC_REQUEST_MEMORY@/$CP4BA_DEPLOYMENT_STARTER_ODM_DC_REQUEST_MEMORY/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DEPLOYMENT_STARTER_ODM_DC_LIMITS_CPU@/$CP4BA_DEPLOYMENT_STARTER_ODM_DC_LIMITS_CPU/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DEPLOYMENT_STARTER_ODM_DC_LIMITS_MEMORY@/$CP4BA_DEPLOYMENT_STARTER_ODM_DC_LIMITS_MEMORY/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DEPLOYMENT_STARTER_ODM_DC_REQUEST_EPHEMERAL_STORAGE@/$CP4BA_DEPLOYMENT_STARTER_ODM_DC_REQUEST_EPHEMERAL_STORAGE/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DEPLOYMENT_STARTER_ODM_DC_LIMITS_EPHEMERAL_STORAGE@/$CP4BA_DEPLOYMENT_STARTER_ODM_DC_LIMITS_EPHEMERAL_STORAGE/g"
  #decisionServerRuntime
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DEPLOYMENT_STARTER_ODM_DSR_REPLICA_COUNT@/$CP4BA_DEPLOYMENT_STARTER_ODM_DSR_REPLICA_COUNT/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DEPLOYMENT_STARTER_ODM_DSR_REQUEST_CPU@/$CP4BA_DEPLOYMENT_STARTER_ODM_DSR_REQUEST_CPU/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DEPLOYMENT_STARTER_ODM_DSR_REQUEST_MEMORY@/$CP4BA_DEPLOYMENT_STARTER_ODM_DSR_REQUEST_MEMORY/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DEPLOYMENT_STARTER_ODM_DSR_LIMITS_CPU@/$CP4BA_DEPLOYMENT_STARTER_ODM_DSR_LIMITS_CPU/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DEPLOYMENT_STARTER_ODM_DSR_LIMITS_MEMORY@/$CP4BA_DEPLOYMENT_STARTER_ODM_DSR_LIMITS_MEMORY/g"
  #decisionServerConsole
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DEPLOYMENT_STARTER_ODM_DSC_REQUEST_CPU@/$CP4BA_DEPLOYMENT_STARTER_ODM_DSC_REQUEST_CPU/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DEPLOYMENT_STARTER_ODM_DSC_REQUEST_MEMORY@/$CP4BA_DEPLOYMENT_STARTER_ODM_DSC_REQUEST_MEMORY/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DEPLOYMENT_STARTER_ODM_DSC_LIMITS_CPU@/$CP4BA_DEPLOYMENT_STARTER_ODM_DSC_LIMITS_CPU/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DEPLOYMENT_STARTER_ODM_DSC_LIMITS_MEMORY@/$CP4BA_DEPLOYMENT_STARTER_ODM_DSC_LIMITS_MEMORY/g"
  #decisionRunner
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DEPLOYMENT_STARTER_ODM_DR_REPLICA_COUNT@/$CP4BA_DEPLOYMENT_STARTER_ODM_DR_REPLICA_COUNT/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DEPLOYMENT_STARTER_ODM_DR_REQUEST_CPU@/$CP4BA_DEPLOYMENT_STARTER_ODM_DR_REQUEST_CPU/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DEPLOYMENT_STARTER_ODM_DR_REQUEST_MEMORY@/$CP4BA_DEPLOYMENT_STARTER_ODM_DR_REQUEST_MEMORY/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DEPLOYMENT_STARTER_ODM_DR_LIMITS_CPU@/$CP4BA_DEPLOYMENT_STARTER_ODM_DR_LIMITS_CPU/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DEPLOYMENT_STARTER_ODM_DR_LIMITS_MEMORY@/$CP4BA_DEPLOYMENT_STARTER_ODM_DR_LIMITS_MEMORY/g"

}
