############################################################
#Author           : Kyle Dawson
#Author email     : Kyle.Dawson@us.ibm.com
#Original Date    : 2022-01-25
#Initial Version  : v2022-0D-Beta
############################################################
cp4baFilenetConsole()
{
  printHeaderMessage "Content Console"
  oc get cm ${CP4BA_DEPLOYMENT_NAME}-cp4ba-access-info -n ${CP4BA_AUTO_NAMESPACE} -o jsonpath='{.data.cpe-access-info}' &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/filenet-console.log
  NAV_USERNAME=`cat  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/filenet-console.log | grep "username"  | awk '{print $2}'| head -n 1`
  echo "Username                                   : ${NAV_USERNAME}"
  NAV_PASSWORD=`cat  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/filenet-console.log | grep "password"  | awk '{print $2}'| head -n 1`
  echo "Password                                   : ${NAV_PASSWORD}"
  #################################################
  #CPE
  #################################################
  CPE_ADMIN_URL=`cat  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/filenet-console.log | grep "Content Platform Engine administration"  | awk '{print $5}' | head -n 1`
  echo "Content Platform Engine administration     : ${BLUE_TEXT}${CPE_ADMIN_URL}${RESET_TEXT}"
  CPE_HC_URL=`cat  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/filenet-console.log | grep "Content Platform Engine health check"  | awk '{print $6}' | head -n 1`
  echo "Content Platform Engine health check       : ${BLUE_TEXT}${CPE_HC_URL}${RESET_TEXT}"
  CPE_PING_URL=`cat  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/filenet-console.log | grep "Content Platform Engine ping page"  | awk '{print $6}' | head -n 1`
  echo "Content Platform Engine ping page          : ${BLUE_TEXT}${CPE_PING_URL}${RESET_TEXT}"
  FILENET_PING_URL=`cat  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/filenet-console.log | grep "FileNet Process Services ping page"  | awk '{print $6}' | head -n 1`
  #################################################
  #Filenet
  #################################################
  echo "FileNet Process Services ping page         : ${BLUE_TEXT}${FILENET_PING_URL}${RESET_TEXT}"
  FILENET_PROCESS_SERVICES_URL=`cat  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/filenet-console.log | grep "FileNet Process Services details page"  | awk '{print $6}' | head -n 1`
  echo "FileNet Process Services details page      : ${BLUE_TEXT}${FILENET_PROCESS_SERVICES_URL}${RESET_TEXT}"
  #################################################
  #navigator
  #################################################
  oc get cm ${CP4BA_DEPLOYMENT_NAME}-cp4ba-access-info -n ${CP4BA_AUTO_NAMESPACE} -o jsonpath='{.data.navigator-access-info}' &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/navigator-console.log
  NAV_CP4BA_URL=`cat  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/navigator-console.log | grep "Business Automation Navigator for CP4BA"  | awk '{print $6}'| head -n 1`
  echo "Business Automation Navigator for CP4BA    : ${BLUE_TEXT}${NAV_CP4BA_URL}${RESET_TEXT}"
  NAV_FNCM_URL=`cat  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/navigator-console.log | grep "Business Automation Navigator for FNCM"  | awk '{print $6}'| head -n 1`
  echo "Business Automation Navigator for FNCM     : ${BLUE_TEXT}${NAV_FNCM_URL}${RESET_TEXT}"
  #################################################
  #GraphQL
  #################################################
  oc get cm ${CP4BA_DEPLOYMENT_NAME}-cp4ba-access-info -n ${CP4BA_AUTO_NAMESPACE} -o jsonpath='{.data.graphql-access-info}' &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/graphql-console.log
  CONTENT_SERVICES_GRAPHQL_URL=`cat  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/graphql-console.log | grep "Content Services GraphQL"  | awk '{print $4}'| head -n 1`
  echo "Content Services GraphQL                   : ${BLUE_TEXT}${CONTENT_SERVICES_GRAPHQL_URL}${RESET_TEXT}"


}
cp4baFilenetStatus()
{
    printHeaderMessage "CP4BA Service Status - Content"
    rm -fR ${LOG_DIR}/${PRODUCT_SHORT_NAME}/filenet-status.log 2> /dev/null
    oc get ICP4ACluster ${CP4BA_DEPLOYMENT_NAME} -n ${CP4BA_AUTO_NAMESPACE} -o jsonpath='{.status.components}' 2> /dev/null  | jq  . |  sed 's/\"//g' | sed 's/,//g'  | sed 's/://g' | sed 's/{//g' | sed 's/}//g'  &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/filenet-status.log
    #################################################
    #CPE
    #################################################
    CP4BA_CPE_DEPLOYMENT_STATUS=`cat ${LOG_DIR}/${PRODUCT_SHORT_NAME}/filenet-status.log | grep cpeDeployment | awk '{print $2}'`
    if [ -z ${CP4BA_CPE_DEPLOYMENT_STATUS}  ]; then
      CP4BA_CPE_DEPLOYMENT_STATUS="Not Found"
    fi
    echo "cpeDeployment                            :  ${CP4BA_CPE_DEPLOYMENT_STATUS}"
    CP4BA_CPE_JDBC_DRIVER_STATUS=`cat ${LOG_DIR}/${PRODUCT_SHORT_NAME}/filenet-status.log | grep cpeJDBCDriver | awk '{print $2}'`
    if [ -z ${CP4BA_CPE_JDBC_DRIVER_STATUS}  ]; then
      CP4BA_CPE_JDBC_DRIVER_STATUS="Not Found"
    fi
    echo "cpeJDBCDriver                            :  ${CP4BA_CPE_JDBC_DRIVER_STATUS}"
    CP4BA_CPE_ROUTE_STATUS=`cat ${LOG_DIR}/${PRODUCT_SHORT_NAME}/filenet-status.log | grep cpeRoute | awk '{print $2}'`
    if [ -z ${CP4BA_CPE_ROUTE_STATUS}  ]; then
      CP4BA_CPE_ROUTE_STATUS="Not Found"
    fi
    echo "cpeRoute                                 :  ${CP4BA_CPE_ROUTE_STATUS}"
    CP4BA_CPE_SERVICE_STATUS=`cat ${LOG_DIR}/${PRODUCT_SHORT_NAME}/filenet-status.log | grep cpeService | awk '{print $2}'`
    if [ -z ${CP4BA_CPE_SERVICE_STATUS}  ]; then
      CP4BA_CPE_SERVICE_STATUS="Not Found"
    fi
    echo "cpeService                               :  ${CP4BA_CPE_SERVICE_STATUS}"
    CP4BA_CPE_STORAGE_STATUS=`cat ${LOG_DIR}/${PRODUCT_SHORT_NAME}/filenet-status.log | grep cpeStorage | awk '{print $2}'`
    if [ -z ${CP4BA_CPE_STORAGE_STATUS}  ]; then
      CP4BA_CPE_STORAGE_STATUS="Not Found"
    fi
    echo "cpeStorage                               :  ${CP4BA_CPE_STORAGE_STATUS}"
    CP4BA_CPE_ZEN_INEGRATION_STATUS=`cat ${LOG_DIR}/${PRODUCT_SHORT_NAME}/filenet-status.log | grep cpeZenInegration | awk '{print $2}'`
    if [ -z ${CP4BA_CPE_ZEN_INEGRATION_STATUS}  ]; then
      CP4BA_CPE_ZEN_INEGRATION_STATUS="Not Found"
    fi
    echo "cpeZenInegration                         :  ${CP4BA_CPE_ZEN_INEGRATION_STATUS}"
    CP4BA_GRAPHQL_ROUTE_STATUS=`cat ${LOG_DIR}/${PRODUCT_SHORT_NAME}/filenet-status.log | grep graphqlDeployment | awk '{print $2}'`
    if [ -z ${CP4BA_GRAPHQL_ROUTE_STATUS}  ]; then
      CP4BA_GRAPHQL_ROUTE_STATUS="Not Found"
    fi
    #################################################
    #GraphQL
    #################################################
    echo "graphqlDeployment                        :  ${CP4BA_GRAPHQL_ROUTE_STATUS}"
    CP4BA_GRAPHQL_SERVICE_STATUS=`cat ${LOG_DIR}/${PRODUCT_SHORT_NAME}/filenet-status.log | grep graphqlRoute | awk '{print $2}'`
    if [ -z ${CP4BA_GRAPHQL_SERVICE_STATUS}  ]; then
      CP4BA_GRAPHQL_SERVICE_STATUS="Not Found"
    fi
    echo "graphqlRoute                             :  ${CP4BA_GRAPHQL_SERVICE_STATUS}"
    CP4BA_GRAPHQL_SERVICE_STATUS=`cat ${LOG_DIR}/${PRODUCT_SHORT_NAME}/filenet-status.log | grep graphqlService | awk '{print $2}'`
    if [ -z ${CP4BA_GRAPHQL_SERVICE_STATUS}  ]; then
      CP4BA_GRAPHQL_SERVICE_STATUS="Not Found"
    fi
    echo "graphqlService                           :  ${CP4BA_GRAPHQL_SERVICE_STATUS}"
    CP4BA_GRAPHQL_STORAGE_STATUS=`cat ${LOG_DIR}/${PRODUCT_SHORT_NAME}/filenet-status.log | grep graphqlStorage | awk '{print $2}'`
    if [ -z ${CP4BA_GRAPHQL_STORAGE_STATUS}  ]; then
      CP4BA_GRAPHQL_STORAGE_STATUS="Not Found"
    fi
    echo "graphqlStorage                           :  ${CP4BA_GRAPHQL_STORAGE_STATUS}"
    #################################################
    #Navigator
    #################################################
    CP4BA_NAVIGATOR_DEPLOYMENT_STATUS=`cat ${LOG_DIR}/${PRODUCT_SHORT_NAME}/filenet-status.log | grep navigatorDeployment | awk '{print $2}'`
    if [ -z ${CP4BA_NAVIGATOR_DEPLOYMENT_STATUS}  ]; then
      CP4BA_NAVIGATOR_DEPLOYMENT_STATUS="Not Found"
    fi
    echo "navigatorDeployment                      :  ${CP4BA_NAVIGATOR_DEPLOYMENT_STATUS}"
    CP4BA_NAVIGATOR_SERVICE_STATUS=`cat ${LOG_DIR}/${PRODUCT_SHORT_NAME}/filenet-status.log | grep navigatorService | awk '{print $2}'`
    if [ -z ${CP4BA_NAVIGATOR_SERVICE_STATUS}  ]; then
      CP4BA_NAVIGATOR_SERVICE_STATUS="Not Found"
    fi
    echo "navigatorService                         :  ${CP4BA_NAVIGATOR_SERVICE_STATUS}"
    CP4BA_NAVIGATOR_SETORAGE_STATUS=`cat ${LOG_DIR}/${PRODUCT_SHORT_NAME}/filenet-status.log | grep navigatorStorage | awk '{print $2}'`
    if [ -z ${CP4BA_NAVIGATOR_SETORAGE_STATUS}  ]; then
      CP4BA_NAVIGATOR_SETORAGE_STATUS="Not Found"
    fi
    echo "navigatorStorage                         :  ${CP4BA_NAVIGATOR_SETORAGE_STATUS}"
    CP4BA_NAVIGATOR_ZEN_INEGRATION_STATUS=`cat ${LOG_DIR}/${PRODUCT_SHORT_NAME}/filenet-status.log | grep navigatorZenInegration | awk '{print $2}'`
    if [ -z ${CP4BA_NAVIGATOR_ZEN_INEGRATION_STATUS}  ]; then
      CP4BA_NAVIGATOR_ZEN_INEGRATION_STATUS="Not Found"
    fi
    echo "navigatorZenInegration                   :  ${CP4BA_NAVIGATOR_ZEN_INEGRATION_STATUS}"

    #     extshare:
    #       extshareDeployment: NotInstalled
    #       extshareRoute: NotInstalled
    #       extshareService: NotInstalled
    #       extshareStorage: NotInstalled
    #     gitgatewayService:
    #       gitsvcDeployment: NotInstalled
    #       gitsvcPersistentVolume: NotInstalled
    #       gitsvcService: NotInstalled
    #     iccsap:
    #       iccsapDeployment: NotInstalled
    #       iccsapRoute: NotInstalled
    #       iccsapService: NotInstalled
    #       iccsapStorageCheck: NotInstalled
    #     ier:
    #       ierDeployment: NotInstalled
    #       ierRoute: NotInstalled
    #       ierService: NotInstalled
    #       ierStorageCheck: NotInstalled

}
cp4baFilenetPrepareFiles()
{
  #cpe
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DEPLOYMENT_STARTER_CPE_REPLICA_COUNT@/$CP4BA_DEPLOYMENT_STARTER_CPE_REPLICA_COUNT/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DEPLOYMENT_STARTER_CPE_REQUEST_CPU@/$CP4BA_DEPLOYMENT_STARTER_CPE_REQUEST_CPU/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DEPLOYMENT_STARTER_CPE_REQUEST_MEMORY@/$CP4BA_DEPLOYMENT_STARTER_CPE_REQUEST_MEMORY/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DEPLOYMENT_STARTER_CPE_LIMITS_CPU@/$CP4BA_DEPLOYMENT_STARTER_CPE_LIMITS_CPU/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DEPLOYMENT_STARTER_CPE_LIMITS_MEMORY@/$CP4BA_DEPLOYMENT_STARTER_CPE_LIMITS_MEMORY/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DEPLOYMENT_STARTER_CPE_AUTO_SCALING_ENABLED@/$CP4BA_DEPLOYMENT_STARTER_CPE_AUTO_SCALING_ENABLED/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DEPLOYMENT_STARTER_CPE_AUTO_SCALING_MAX_REPLICAS@/$CP4BA_DEPLOYMENT_STARTER_CPE_AUTO_SCALING_MAX_REPLICAS/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DEPLOYMENT_STARTER_CPE_AUTO_SCALING_MIN_REPLICAS@/$CP4BA_DEPLOYMENT_STARTER_CPE_AUTO_SCALING_MIN_REPLICAS/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DEPLOYMENT_STARTER_CPE_AUTO_SCALING_TARGET_CPU_UTIL_PERCENT@/$CP4BA_DEPLOYMENT_STARTER_CPE_AUTO_SCALING_TARGET_CPU_UTIL_PERCENT/g"
  #graphql
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DEPLOYMENT_STARTER_GRAPHQL_REPLICA_COUNT@/$CP4BA_DEPLOYMENT_STARTER_GRAPHQL_REPLICA_COUNT/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DEPLOYMENT_STARTER_GRAPHQL_REQUEST_CPU@/$CP4BA_DEPLOYMENT_STARTER_GRAPHQL_REQUEST_CPU/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DEPLOYMENT_STARTER_GRAPHQL_REQUEST_MEMORY@/$CP4BA_DEPLOYMENT_STARTER_GRAPHQL_REQUEST_MEMORY/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DEPLOYMENT_STARTER_GRAPHQL_LIMITS_CPU@/$CP4BA_DEPLOYMENT_STARTER_GRAPHQL_LIMITS_CPU/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DEPLOYMENT_STARTER_GRAPHQL_LIMITS_MEMORY@/$CP4BA_DEPLOYMENT_STARTER_GRAPHQL_LIMITS_MEMORY/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DEPLOYMENT_STARTER_GRAPHQL_AUTO_SCALING_ENABLED@/$CP4BA_DEPLOYMENT_STARTER_GRAPHQL_AUTO_SCALING_ENABLED/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DEPLOYMENT_STARTER_GRAPHQL_AUTO_SCALING_MAX_REPLICAS@/$CP4BA_DEPLOYMENT_STARTER_GRAPHQL_AUTO_SCALING_MAX_REPLICAS/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DEPLOYMENT_STARTER_GRAPHQL_AUTO_SCALING_MIN_REPLICAS@/$CP4BA_DEPLOYMENT_STARTER_GRAPHQL_AUTO_SCALING_MIN_REPLICAS/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DEPLOYMENT_STARTER_GRAPHQL_AUTO_SCALING_TARGET_CPU_UTIL_PERCENT@/$CP4BA_DEPLOYMENT_STARTER_GRAPHQL_AUTO_SCALING_TARGET_CPU_UTIL_PERCENT/g"
  #css
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DEPLOYMENT_STARTER_CSS_REPLICA_COUNT@/$CP4BA_DEPLOYMENT_STARTER_CSS_REPLICA_COUNT/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DEPLOYMENT_STARTER_CSS_REQUEST_CPU@/$CP4BA_DEPLOYMENT_STARTER_CSS_REQUEST_CPU/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DEPLOYMENT_STARTER_CSS_REQUEST_MEMORY@/$CP4BA_DEPLOYMENT_STARTER_CSS_REQUEST_MEMORY/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DEPLOYMENT_STARTER_CSS_LIMITS_CPU@/$CP4BA_DEPLOYMENT_STARTER_CSS_LIMITS_CPU/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DEPLOYMENT_STARTER_CSS_LIMITS_MEMORY@/$CP4BA_DEPLOYMENT_STARTER_CSS_LIMITS_MEMORY/g"
  #graphql
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DEPLOYMENT_STARTER_CMIS_REPLICA_COUNT@/$CP4BA_DEPLOYMENT_STARTER_CMIS_REPLICA_COUNT/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DEPLOYMENT_STARTER_CMIS_REQUEST_CPU@/$CP4BA_DEPLOYMENT_STARTER_CMIS_REQUEST_CPU/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DEPLOYMENT_STARTER_CMIS_REQUEST_MEMORY@/$CP4BA_DEPLOYMENT_STARTER_CMIS_REQUEST_MEMORY/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DEPLOYMENT_STARTER_CMIS_LIMITS_CPU@/$CP4BA_DEPLOYMENT_STARTER_CMIS_LIMITS_CPU/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DEPLOYMENT_STARTER_CMIS_LIMITS_MEMORY@/$CP4BA_DEPLOYMENT_STARTER_CMIS_LIMITS_MEMORY/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DEPLOYMENT_STARTER_CMIS_AUTO_SCALING_ENABLED@/$CP4BA_DEPLOYMENT_STARTER_CMIS_AUTO_SCALING_ENABLED/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DEPLOYMENT_STARTER_CMIS_AUTO_SCALING_MAX_REPLICAS@/$CP4BA_DEPLOYMENT_STARTER_CMIS_AUTO_SCALING_MAX_REPLICAS/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DEPLOYMENT_STARTER_CMIS_AUTO_SCALING_MIN_REPLICAS@/$CP4BA_DEPLOYMENT_STARTER_CMIS_AUTO_SCALING_MIN_REPLICAS/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DEPLOYMENT_STARTER_CMIS_AUTO_SCALING_TARGET_CPU_UTIL_PERCENT@/$CP4BA_DEPLOYMENT_STARTER_CMIS_AUTO_SCALING_TARGET_CPU_UTIL_PERCENT/g"
  #graphql
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DEPLOYMENT_STARTER_TM_REPLICA_COUNT@/$CP4BA_DEPLOYMENT_STARTER_TM_REPLICA_COUNT/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DEPLOYMENT_STARTER_TM_REQUEST_CPU@/$CP4BA_DEPLOYMENT_STARTER_TM_REQUEST_CPU/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DEPLOYMENT_STARTER_TM_REQUEST_MEMORY@/$CP4BA_DEPLOYMENT_STARTER_TM_REQUEST_MEMORY/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DEPLOYMENT_STARTER_TM_LIMITS_CPU@/$CP4BA_DEPLOYMENT_STARTER_TM_LIMITS_CPU/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DEPLOYMENT_STARTER_TM_LIMITS_MEMORY@/$CP4BA_DEPLOYMENT_STARTER_TM_LIMITS_MEMORY/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DEPLOYMENT_STARTER_TM_AUTO_SCALING_ENABLED@/$CP4BA_DEPLOYMENT_STARTER_TM_AUTO_SCALING_ENABLED/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DEPLOYMENT_STARTER_TM_AUTO_SCALING_MAX_REPLICAS@/$CP4BA_DEPLOYMENT_STARTER_TM_AUTO_SCALING_MAX_REPLICAS/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DEPLOYMENT_STARTER_TM_AUTO_SCALING_MIN_REPLICAS@/$CP4BA_DEPLOYMENT_STARTER_TM_AUTO_SCALING_MIN_REPLICAS/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DEPLOYMENT_STARTER_TM_AUTO_SCALING_TARGET_CPU_UTIL_PERCENT@/$CP4BA_DEPLOYMENT_STARTER_TM_AUTO_SCALING_TARGET_CPU_UTIL_PERCENT/g"

  #Production Settings
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_LDAP_SERVER@/$CP4BA_LDAP_SERVER/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_LDAP_PORT@/$CP4BA_LDAP_PORT/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_LDAP_BASE_DN@/$CP4BA_LDAP_BASE_DN/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_LDAP_SERVER_BIND_SECRET@/$CP4BA_LDAP_SERVER_BIND_SECRET/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_LDAP_SERVER_SSL_ENABLED@/$CP4BA_LDAP_SERVER_SSL_ENABLED/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_LDAP_SERVER_SSL_SECRET_NAME@/$CP4BA_LDAP_SERVER_SSL_SECRET_NAME/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_LDAP_USER_NAME_ATTRIBUTE@/$CP4BA_LDAP_USER_NAME_ATTRIBUTE/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_LDAP_USER_DISPLAY_NAME_ATTRIBUTE@/$CP4BA_LDAP_USER_DISPLAY_NAME_ATTRIBUTE/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_LDAP_GROUP_BASE_DN@/$CP4BA_LDAP_GROUP_BASE_DN/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_LDAP_GROUP_MEMBERSHIP_SEARCH_FILTER@/$CP4BA_LDAP_GROUP_MEMBERSHIP_SEARCH_FILTER/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_LDAP_GROUP_MEMBER_ID_MAP@/$CP4BA_LDAP_GROUP_MEMBER_ID_MAP/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_LDAP_TDS_LC_USER_FILTER@/$CP4BA_LDAP_TDS_LC_USER_FILTER/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_LDAP_TDS_LC_GROUP_FILTER@/$CP4BA_LDAP_TDS_LC_GROUP_FILTER/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DC_SSL_ENABLED@/$CP4BA_DC_SSL_ENABLED/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DC_ICN_DATABASE_TYPE@/$CP4BA_DC_ICN_DATABASE_TYPE/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DC_ICN_COMMON_ICN_DATASOURCE_NAME@/$CP4BA_DC_ICN_COMMON_ICN_DATASOURCE_NAME/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DC_ICN_DATABASE_SERVERNAME@/$CP4BA_DC_ICN_DATABASE_SERVERNAME/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DC_ICN_DATABASE_PORT@/$CP4BA_DC_ICN_DATABASE_PORT/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DC_ICN_DATABASE_NAME@/$CP4BA_DC_ICN_DATABASE_NAME/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DC_ICN_DATABASE_SSL_SECRET_NAME@/$CP4BA_DC_ICN_DATABASE_SSL_SECRET_NAME/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DC_GCD_DATABASE_TYPE@/$CP4BA_DC_GCD_DATABASE_TYPE/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DC_GCD_COMMON_GCD_DATASOURCE_NAME@/$CP4BA_DC_GCD_COMMON_GCD_DATASOURCE_NAME/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DC_GCD_COMMON_GCD_XDA_DATASOURCE_NAME@/$CP4BA_DC_GCD_COMMON_GCD_XDA_DATASOURCE_NAME/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DC_GCD_DATABASE_SERVERNAME@/$CP4BA_DC_GCD_DATABASE_SERVERNAME/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DC_GCD_DATABASE_NAME@/$CP4BA_DC_GCD_DATABASE_NAME/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DC_GCD_DATABASE_PORT@/$CP4BA_DC_GCD_DATABASE_PORT/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DC_GCD_DATABASE_SSL_SECRET_NAME@/$CP4BA_DC_GCD_DATABASE_SSL_SECRET_NAME/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DC_OS_DATABASE_TYPE@/$CP4BA_DC_OS_DATABASE_TYPE/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DC_OS_LABEL@/$CP4BA_DC_OS_LABEL/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DC_OS_COMMON_DATASOURCE_NAME@/$CP4BA_DC_OS_COMMON_DATASOURCE_NAME/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DC_OS_COMMON_XA_DATASOURCE_NAME@/$CP4BA_DC_OS_COMMON_XA_DATASOURCE_NAME/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DC_OS_DATABASE_SERVERNAME@/$CP4BA_DC_OS_DATABASE_SERVERNAME/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DC_OS_DATABASE_NAME@/$CP4BA_DC_OS_DATABASE_NAME/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DC_OS_DATABASE_PORT@/$CP4BA_DC_OS_DATABASE_PORT/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DC_OS_DATABASE_SSL_SECRET_NAME@/$CP4BA_DC_OS_DATABASE_SSL_SECRET_NAME/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_IC_LDAP_ADMIN_USER_NAME@/$CP4BA_IC_LDAP_ADMIN_USER_NAME/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_IC_LDAP_ADMINS_GROUPS_NAME@/$CP4BA_IC_LDAP_ADMINS_GROUPS_NAME/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DC_OS_DATABASE_NAME@/$CP4BA_DC_OS_DATABASE_NAME/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DC_OS_DATABASE_NAME@/$CP4BA_DC_OS_DATABASE_NAME/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DC_OS_COMMON_DATASOURCE_NAME@/$CP4BA_DC_OS_COMMON_DATASOURCE_NAME/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_DC_OS_COMMON_XA_DATASOURCE_NAME@/$CP4BA_DC_OS_COMMON_XA_DATASOURCE_NAME/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/services -type f | xargs sed -i'' "s/@CP4BA_IC_OBJ_STORE_CREATION_CPE_ADMIN_USER_GROUPS@/$CP4BA_IC_OBJ_STORE_CREATION_CPE_ADMIN_USER_GROUPS/g"
}
