############################################################
#Author           : Kyle Dawson
#Author email     : Kyle.Dawson@us.ibm.com
#Original Date    : 2022-01-25
#Initial Version  : v2022-02-15
############################################################
cp4baBAIStatus()
{
    printHeaderMessage "CP4BA Service Status - Insights"
    rm -fR ${LOG_DIR}/${PRODUCT_SHORT_NAME}/bai-status.log 2> /dev/null
    oc get ICP4ACluster ${CP4BA_DEPLOYMENT_NAME} -n ${CP4BA_AUTO_NAMESPACE} -o jsonpath='{.status.components}' 2> /dev/null  | jq  . |  sed 's/\"//g' | sed 's/,//g'  | sed 's/://g' | sed 's/{//g' | sed 's/}//g'  &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/bai-status.log
    #################################################
    #BAI
    #################################################
    CP4BA_BAI_DEPLOYMENT_STATUS=`cat ${LOG_DIR}/${PRODUCT_SHORT_NAME}/bai-status.log | grep bai_deploy_status | awk '{print $2}'`
    if [ -z ${CP4BA_BAI_DEPLOYMENT_STATUS}  ]; then
      CP4BA_BAI_DEPLOYMENT_STATUS="Not Found"
    fi
    echo "bai_deploy_status:                       :  ${CP4BA_BAI_DEPLOYMENT_STATUS}"
    CP4BA_BAI_INSIGHT_ENGINE_STATUS=`cat ${LOG_DIR}/${PRODUCT_SHORT_NAME}/bai-status.log | grep insightsEngine | awk '{print $2}'`
    if [ -z ${CP4BA_BAI_INSIGHT_ENGINE_STATUS}  ]; then
      CP4BA_BAI_INSIGHT_ENGINE_STATUS="Not Found"
    fi
    echo "insightsEngine:                          :  ${CP4BA_BAI_INSIGHT_ENGINE_STATUS}"

}
cp4baBAIConsole()
{
  printHeaderMessage "Insights Console"
  oc get cm ${CP4BA_DEPLOYMENT_NAME}-cp4ba-access-info -n ${CP4BA_AUTO_NAMESPACE} -o yaml &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/bai-console.yaml
  NAV_USERNAME=`cat  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/bai-console.yaml | grep "Business Performance Center Username"  | awk '{print $5}'| head -n 1`
  echo "Business Performance Center Username       : ${NAV_USERNAME}"
  NAV_PASSWORD=`cat  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/bai-console.yaml | grep "Business Performance Center Password"  | awk '{print $5}'| head -n 1`
  echo "Business Performance Center Password       : ${NAV_PASSWORD}"
  #################################################
  #BAI Desktop
  #################################################
  NAV_CP4BA_URL=`cat  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/bai-console.yaml | grep "Business Performance Center URL"  | awk '{print $5}'| head -n 1`
  echo "Business Performance Center URL            : ${BLUE_TEXT}${NAV_CP4BA_URL}${RESET_TEXT}"
  #################################################
  #Elastic Search
  #################################################
  ELS_USERNAME=`cat  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/bai-console.yaml | grep "Elasticsearch Username"  | awk '{print $3}'| head -n 1`
  echo "Elasticsearch Username                     : ${ELS_USERNAME}"
  ELS_PASSWORD=`cat  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/bai-console.yaml | grep "Elasticsearch Password"  | awk '{print $3}'| head -n 1`
  echo "Elasticsearch Password                     : ${ELS_PASSWORD}"
  ELS_CP4BA_URL=`cat  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/bai-console.yaml | grep "Elasticsearch URL"  | awk '{print $3}'| head -n 1`
  echo "Elasticsearch URL                          : ${BLUE_TEXT}${ELS_CP4BA_URL}${RESET_TEXT}"

}
