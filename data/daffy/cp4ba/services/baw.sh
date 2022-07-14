############################################################
#Author           : Kyle Dawson
#Author email     : Kyle.Dawson@us.ibm.com
#Original Date    : 2022-01-25
#Initial Version  : v2022-02-15
############################################################
cp4baBAWStatus()
{
    printHeaderMessage "CP4BA Service Status - Workflow"
    rm -fR ${LOG_DIR}/${PRODUCT_SHORT_NAME}/workflow-status.log 2> /dev/null
    oc get ICP4ACluster ${CP4BA_DEPLOYMENT_NAME} -n ${CP4BA_AUTO_NAMESPACE} -o jsonpath='{.status.components}' 2> /dev/null  | jq  . |  sed 's/\"//g' | sed 's/,//g'  | sed 's/://g' | sed 's/{//g' | sed 's/}//g'  &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/workflow-status.log
    CP4BA_PFS_DEPLOYMENT_STATUS=`cat ${LOG_DIR}/${PRODUCT_SHORT_NAME}/workflow-status.log | grep pfsDeployment | awk '{print $2}'`
    if [ -z ${CP4BA_PFS_DEPLOYMENT_STATUS}  ]; then
      CP4BA_PFS_DEPLOYMENT_STATUS="Not Found"
    fi
    echo "pfsDeployment                            :  ${CP4BA_PFS_DEPLOYMENT_STATUS}"
    CP4BA_PFS_SERVICE_STATUS=`cat ${LOG_DIR}/${PRODUCT_SHORT_NAME}/workflow-status.log| grep pfsService | awk '{print $2}'`
    if [ -z ${CP4BA_PFS_SERVICE_STATUS}  ]; then
      CP4BA_PFS_SERVICE_STATUS="Not Found"
    fi
    echo "pfsService                               :  ${CP4BA_PFS_SERVICE_STATUS}"
    CP4BA_PFS_ZEN_INTEGRATION_STATUS=`cat ${LOG_DIR}/${PRODUCT_SHORT_NAME}/workflow-status.log| grep pfsZenIntegration | awk '{print $2}'`
    if [ -z ${CP4BA_PFS_ZEN_INTEGRATION_STATUS}  ]; then
      CP4BA_PFS_ZEN_INTEGRATION_STATUS="Not Found"
    fi
    echo "pfsZenIntegration                        :  ${CP4BA_PFS_ZEN_INTEGRATION_STATUS}"
    CP4BA_BAML_DEPLOYMENT_STATUS=`cat ${LOG_DIR}/${PRODUCT_SHORT_NAME}/workflow-status.log| grep bamlDeployStatus | awk '{print $2}'`
    if [ -z ${CP4BA_BAML_DEPLOYMENT_STATUS}  ]; then
      CP4BA_BAML_DEPLOYMENT_STATUS="Not Found"
    fi
    echo "bamlDeployStatus                         :  ${CP4BA_BAML_DEPLOYMENT_STATUS}"
    CP4BA_BAML_DEPLOYMENT=`cat ${LOG_DIR}/${PRODUCT_SHORT_NAME}/workflow-status.log| grep bamlDeployment | awk '{print $2}'`
    if [ -z ${CP4BA_BAML_DEPLOYMENT}  ]; then
      CP4BA_BAML_DEPLOYMENT="Not Found"
    fi
    echo "bamlDeployment                           :  ${CP4BA_BAML_DEPLOYMENT}"
    CP4BA_BAML_SERVICE_STATUS=`cat ${LOG_DIR}/${PRODUCT_SHORT_NAME}/workflow-status.log| grep bamlService | awk '{print $2}'`
    if [ -z ${CP4BA_BAML_SERVICE_STATUS}  ]; then
      CP4BA_BAML_SERVICE_STATUS="Not Found"
    fi
    echo "bamlServiceStatus                        :  ${CP4BA_BAML_SERVICE_STATUS}"
    CP4BA_BAW_DEPLOYMENT_STATUS=`cat ${LOG_DIR}/${PRODUCT_SHORT_NAME}/workflow-status.log| grep bawDeployment | awk '{print $2}'`
    if [ -z ${CP4BA_BAW_DEPLOYMENT_STATUS}  ]; then
      CP4BA_BAW_DEPLOYMENT_STATUS="Not Found"
    fi
    echo "bawDeployment                            :  ${CP4BA_BAW_DEPLOYMENT_STATUS}"
    CP4BA_BAW_SERVICE_STATUS=`cat ${LOG_DIR}/${PRODUCT_SHORT_NAME}/workflow-status.log| grep bawService | awk '{print $2}'`
    if [ -z ${CP4BA_BAW_SERVICE_STATUS}  ]; then
      CP4BA_BAW_SERVICE_STATUS="Not Found"
    fi
    echo "bawService                               :  ${CP4BA_BAW_SERVICE_STATUS}"
    CP4BA_BAW_ZEN_INTEGRATION_STATUS=`cat ${LOG_DIR}/${PRODUCT_SHORT_NAME}/workflow-status.log| grep bawZenIntegration | awk '{print $2}'`
    if [ -z ${CP4BA_BAW_ZEN_INTEGRATION_STATUS}  ]; then
      CP4BA_BAW_ZEN_INTEGRATION_STATUS="Not Found"
    fi
    echo "bawZenIntegration                        :  ${CP4BA_BAW_ZEN_INTEGRATION_STATUS}"
}
cp4baBAWConsole()
{
  printHeaderMessage "Workflow Console"
  oc get cm ${CP4BA_DEPLOYMENT_NAME}-cp4ba-access-info -n ${CP4BA_AUTO_NAMESPACE} -o jsonpath='{.data.bastudio-access-info}' &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/bastudio-access-info.log
  BAW_USERNAME=`cat  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/bastudio-access-info.log | grep "username:"  | awk '{print $2}'| head -n 1`
  echo "User Name                                  : ${BAW_USERNAME}"
  BAW_PASSWORD=`cat  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/bastudio-access-info.log | grep "password"  | awk '{print $2}'| head -n 1`
  echo "Password                                   : ${BAW_PASSWORD}"
  CP_DASHBOARD_URL=`cat  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/bastudio-access-info.log | grep "Cloudpak Dashboard"  | awk '{print $3}'`
  echo "Cloudpak Dashboard                         : ${BLUE_TEXT}${CP_DASHBOARD_URL}${RESET_TEXT}"
  BA_WORKPLACE_URL=`cat  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/bastudio-access-info.log | grep "Business Automation Workplace"  | awk '{print $4}'`
  echo "Business Automation Workplace              : ${BLUE_TEXT}${BA_WORKPLACE_URL}${RESET_TEXT}"
  BA_WORKFLOW_EXTERNAL_URL=`cat  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/bastudio-access-info.log | grep "Business Automation Workflow External base URL"  | awk '{print $7}'`
  echo "Business Automation Workflow External URL  : ${BLUE_TEXT}${BA_WORKFLOW_EXTERNAL_URL}${RESET_TEXT}"
  BA_WORKFLOW_PORTAL_URL=`cat  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/bastudio-access-info.log | grep "Business Automation Process Portal"  | awk '{print $5}'`
  echo "Business Automation Process Portal         : ${BLUE_TEXT}${BA_WORKFLOW_PORTAL_URL}${RESET_TEXT}"
  BA_CASE_CLIENT_URL=`cat  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/bastudio-access-info.log | grep "Business Automation Case Client"  | awk '{print $5}'`
  echo "Business Automation Case Client            : ${BLUE_TEXT}${BA_CASE_CLIENT_URL}${RESET_TEXT}"

}
cp4baBAWPrepareFiles()
{
    find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_BASTUDIO_VERSION@/$CP4BA_BASTUDIO_VERSION/g"
    find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_BASTUDIO_SOLUTION_SERVER_HELMJOB_DB_VERSION@/$CP4BA_BASTUDIO_SOLUTION_SERVER_HELMJOB_DB_VERSION/g"
    find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_BASTUDIO_SOLUTION_SERVER_VERSION@/$CP4BA_BASTUDIO_SOLUTION_SERVER_VERSION/g"
    find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_BASTUDIO_JMS_SERVER_VERSION@/$CP4BA_BASTUDIO_JMS_SERVER_VERSION/g"
    find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_WORKFLOW_AUTHORING_VERSION@/$CP4BA_WORKFLOW_AUTHORING_VERSION/g"
    find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_WORKFLOW_PFS_BPD_DATABASE_INIT_PROD_VERSION@/$CP4BA_WORKFLOW_PFS_BPD_DATABASE_INIT_PROD_VERSION/g"
    find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_WORKFLOW_SERVER_DBHANDLING@/$CP4BA_WORKFLOW_SERVER_DBHANDLING/g"
    find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_WORKFLOW_IAWS_IBM_WORKPLACE_VERSION@/$CP4BA_WORKFLOW_IAWS_IBM_WORKPLACE_VERSION/g"
    find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_WORKFLOW_TOOLKIT_INSTALLER_VERSION@/$CP4BA_WORKFLOW_TOOLKIT_INSTALLER_VERSION/g"
    find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_WORKFLOW_IAWS_PS_CONTENT_INTEGRATION@/$CP4BA_WORKFLOW_IAWS_PS_CONTENT_INTEGRATION/g"
    find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_WORKFLOW_SERVER_CASE_INITIALIZTION_VERSION@/$CP4BA_WORKFLOW_SERVER_CASE_INITIALIZTION_VERSION/g"
    find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_WORKFLOW_JMS_VERSION@/$CP4BA_WORKFLOW_JMS_VERSION/g"
    find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_BAML_BUI_TASK_PRIORITIZATION_VERSION@/$CP4BA_BAML_BUI_TASK_PRIORITIZATION_VERSION/g"
    find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_BAML_WORKFORCE_INSIGHTS_VERSION@/$CP4BA_BAML_WORKFORCE_INSIGHTS_VERSION/g"
    find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_PFS_PROD_VERSION@/$CP4BA_PFS_PROD_VERSION/g"

}
