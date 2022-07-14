#!/bin/bash
############################################################
#Author           : Kyle Dawson
#Author email     : Kyle.Dawson@us.ibm.com
#Original Date    : 2021-12-30
#Init Version     : v2022-01-18
############################################################
cloudCTLPreCaseInstallCP4D()
{
  mkdir -p ${CASE_REPO_OFFLINE_DIR}
  mkdir -p ${CASE_REPO_OFFLINE_CPFS}
  #echo "Cloud Pak for Data ${CP4D_VERSION} via Case"
  #echo "Case Version  - ${CP4D_CASE_PACKAGE_VERSION}"
  echo "Case Offline Directory                                ${CASE_REPO_OFFLINE_DIR}"
  echo "Case Foundation Services Offline Directory            ${CASE_REPO_OFFLINE_CPFS}"

  local SHOULD_EXIT=0
  echo "Downloading Common Services Case version ${CP4D_CASE_COMMON_SERVICES_PACKAGE_VERSION}       (LOG ->  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ibm-cp-common-services-save.log)"
  cloudctl case save \
  --repo ${CASE_REPO_PATH} \
  --case ibm-cp-common-services \
  --version ${CP4D_CASE_COMMON_SERVICES_PACKAGE_VERSION} \
  --outputdir ${CASE_REPO_OFFLINE_CPFS} &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ibm-cp-common-services-save.log

  if [ ! -f ${CASE_REPO_OFFLINE_CPFS}/ibm-cp-common-services-${CP4D_CASE_COMMON_SERVICES_PACKAGE_VERSION}.tgz ]; then
    echo "${RED_TEXT}Failed to download case file!"
    echo "ibm-cp-common-services-${CP4D_CASE_COMMON_SERVICES_PACKAGE_VERSION}.tgz${RESET_TEXT}"
    SHOULD_EXIT=1
  fi

  echo "Downloading Cloud Pak for Data Case version ${CP4D_CASE_PACKAGE_VERSION}    (LOG ->  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ibm-cp-datacore-save.log)"
  cloudctl case save \
   --repo ${CASE_REPO_PATH} \
   --case ibm-cp-datacore \
   --version ${CP4D_CASE_PACKAGE_VERSION} \
   --outputdir ${CASE_REPO_OFFLINE_DIR} \
   --no-dependency &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ibm-cp-datacore-save.log

  if [ ! -f ${CASE_REPO_OFFLINE_DIR}/ibm-cp-datacore-${CP4D_CASE_PACKAGE_VERSION}*.tgz ]; then
   echo "${RED_TEXT}Failed to download case file!"
   echo "ibm-cp-datacore-${CP4D_CASE_PACKAGE_VERSION}.tgz${RESET_TEXT}"
   SHOULD_EXIT=1
  fi

  echo "Downloading CPD Scheduling Case version ${CP4D_CASE_SCHEDULING_PACKAGE_VERSION}         (LOG ->  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ibm-cpd-scheduling-save.log)"
  cloudctl case save \
  --repo ${CASE_REPO_PATH} \
  --case ibm-cpd-scheduling \
  --version ${CP4D_CASE_SCHEDULING_PACKAGE_VERSION} \
  --outputdir ${CASE_REPO_OFFLINE_DIR} &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ibm-cpd-scheduling-save.log

  if [ ! -f ${CASE_REPO_OFFLINE_DIR}/ibm-cpd-scheduling-${CP4D_CASE_SCHEDULING_PACKAGE_VERSION}.tgz ]; then
    echo "${RED_TEXT}Failed to download case file!"
    echo "ibm-cpd-scheduling-${CP4D_CASE_SCHEDULING_PACKAGE_VERSION}.tgz${RESET_TEXT}"
   SHOULD_EXIT=1
  fi

  echo "Downloading DB2OLTP Case version ${CP4D_DB2OLTP_CATALOG_VERSION}                (LOG ->  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ibm-db2uoperator-save.log)"
  cloudctl case save \
  --repo ${CASE_REPO_PATH} \
  --case ibm-db2oltp \
  --version ${CP4D_DB2OLTP_CATALOG_VERSION} \
  --outputdir ${CASE_REPO_OFFLINE_DIR}  &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ibm-db2uoperator-save.log
  local DB2_CATALOG_TAR_FILE=`ls -r ${CASE_REPO_OFFLINE_DIR}/ibm-db2uoperator-*.tgz | head -1 | sed "s|${CASE_REPO_OFFLINE_DIR}/||g"`
  if [ ! -f ${CASE_REPO_OFFLINE_DIR}/${DB2_CATALOG_TAR_FILE} ]; then
    echo "${RED_TEXT}FAILED ${RESET_TEXT} DB2 case download file not found!"
    echo "Missing file: ${CASE_REPO_OFFLINE_DIR}/${DB2_CATALOG_TAR_FILE}"
    SHOULD_EXIT=1
  fi


  if [ ${SHOULD_EXIT} == 1 ] ;then
    echo ""
    echo ""
    echo "${RED_TEXT}Missing above required case resources. Exiting Script!!!!!!!${RESET_TEXT}"
    echo ""
    echo ""
    exit 1
  fi
 echo ""

}

cloudCTLInstallCP4DSchedulingServiceCatalog()
{
  printHeaderMessage "Case Launch - ibm-cpd-scheduling-${CP4D_CASE_SCHEDULING_PACKAGE_VERSION} (LOG ->  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ibm-cpd-scheduling-launch.log)"
  cloudctl case launch \
  --case ${CASE_REPO_OFFLINE_DIR}/ibm-cpd-scheduling-${CP4D_CASE_SCHEDULING_PACKAGE_VERSION}.tgz \
  --inventory schedulerSetup \
  --namespace openshift-marketplace \
  --action install-catalog \
  --args "--inputDir ${CASE_REPO_OFFLINE_DIR} --recursive" &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ibm-cpd-scheduling-launch.log
  #Need to check for errors in ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ibm-cpd-scheduling-launch.log
  echo "${BLUE_TEXT}COMPLETE ${RESET_TEXT}cloudclt Launch command finished"
  echo ""
  SS_STATUS=`oc get catalogsource -n openshift-marketplace ibm-cpd-scheduling-catalog -o jsonpath='{.status.connectionState.lastObservedState} {"\n"}' | sed 's/ *$//g'`
  let  LOOP_COUNT=1
  while [ "${SS_STATUS}" != "READY"  ]
  do
      blinkWaitMessage "Waiting for Cloud Pak for Data Scheduling Service Catalog to be ready." 60
      SS_STATUS=`oc get catalogsource -n openshift-marketplace ibm-cpd-scheduling-catalog -o jsonpath='{.status.connectionState.lastObservedState} {"\n"}' | sed 's/ *$//g'`
      let LOOP_COUNT=LOOP_COUNT+1
      if [ $LOOP_COUNT -ge 10 ] ;then
          echo "${RED_TEXT}FAILED:Scheduling Service Catalog could not be installed${RESET_TEXT}"
          echo "Exiting Script!!!!!!"
          exit 9
      fi
  done
  echo "${BLUE_TEXT}COMPLETE ${RESET_TEXT}Successfully installed Cloud Pak for Data Scheduling Service catalog"
}
cloudCTLInstallCPDataCatalog()
{
  printHeaderMessage "Case Launch - ibm-cp-datacore-${CP4D_CASE_PACKAGE_VERSION}  (LOG ->  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ibm-cp-datacore-launch.log)"
  local CP_DATACORE_TAR_FILE=`ls -r ${CASE_REPO_OFFLINE_DIR}/ibm-cp-datacore-*.tgz | head -1 | sed "s|${CASE_REPO_OFFLINE_DIR}/||g"`
  cloudctl case launch \
  --case ${CASE_REPO_OFFLINE_DIR}/${CP_DATACORE_TAR_FILE} \
  --inventory cpdPlatformOperator \
  --namespace openshift-marketplace \
  --action install-catalog \
  --args "--inputDir ${CASE_REPO_OFFLINE_DIR} --recursive" &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ibm-cp-datacore-launch.log
  #Need to check for errors in ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ibm-cp-datacore-launch.log
  echo "${BLUE_TEXT}COMPLETE ${RESET_TEXT}cloudclt Launch command finished"
  echo ""
  CPDC_STATUS=`oc get catalogsource -n openshift-marketplace cpd-platform -o jsonpath='{.status.connectionState.lastObservedState} {"\n"}' | sed 's/ *$//g'`
  let  LOOP_COUNT=1
  while [ "${CPDC_STATUS}" != "READY"  ]
  do
      blinkWaitMessage "Waiting for Cloud Pak Data Catalog to be ready." 60
      CPDC_STATUS=`oc get catalogsource -n openshift-marketplace cpd-platform -o jsonpath='{.status.connectionState.lastObservedState} {"\n"}' | sed 's/ *$//g'`
      let LOOP_COUNT=LOOP_COUNT+1
      if [ $LOOP_COUNT -ge 10 ] ;then
          echo "${RED_TEXT}FAILED:Cloud Pak Data Catalog could not be installed${RESET_TEXT}"
          echo "Exiting Script!!!!!!"
          exit 9
      fi
  done
  echo "${BLUE_TEXT}COMPLETE ${RESET_TEXT}Successfully installed Cloud Pak Data catalog"
}

cloudCTLInstallDb2OperatorCatalog()
{
  local DB2_CATALOG_TAR_FILE=`ls -r ${CASE_REPO_OFFLINE_DIR}/ibm-db2uoperator-*.tgz | head -1 | sed "s|${CASE_REPO_OFFLINE_DIR}/||g"`
  printHeaderMessage "Case Launch - ${DB2_CATALOG_TAR_FILE} (LOG ->  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ibm-db2uoperator-launch.log)"
   cloudctl case launch \
   --case ${CASE_REPO_OFFLINE_DIR}/${DB2_CATALOG_TAR_FILE} \
   --inventory db2uOperatorSetup \
   --namespace openshift-marketplace \
   --action install-catalog \
   --args "--inputDir ${CASE_REPO_OFFLINE_DIR} --recursive"  &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ibm-db2uoperator-launch.log
  #Need to check for errors in ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ibm-db2uoperator-launch.log
  echo "${BLUE_TEXT}COMPLETE ${RESET_TEXT}cloudclt Launch command finished"
  echo ""
  local CLOUD_CTL_LAUNCH_FAILED=`cat ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ibm-db2uoperator-launch.log | grep -c FAILED`
  if [ ${CLOUD_CTL_LAUNCH_FAILED} -ge 1 ]; then
     echo "${RED_TEXT} FAILED  ${RESET_TEXT} Unable to install DB2Operator"
     echo "Exiting Script!!!!!!!!!!!!!!!!!!!"
     exit 99
  fi

  CPDC_STATUS=`oc get catalogsource -n openshift-marketplace ibm-db2uoperator-catalog -o jsonpath='{.status.connectionState.lastObservedState} {"\n"}' | sed 's/ *$//g'`
  let  LOOP_COUNT=1
  while [ "${CPDC_STATUS}" != "READY"  ]
  do
      blinkWaitMessage "Waiting for DB2 Operator Catalog to be ready." 60
      CPDC_STATUS=`oc get catalogsource -n openshift-marketplace ibm-db2uoperator-catalog -o jsonpath='{.status.connectionState.lastObservedState} {"\n"}' | sed 's/ *$//g'`
      let LOOP_COUNT=LOOP_COUNT+1
      if [ $LOOP_COUNT -ge 10 ] ;then
          echo "${RED_TEXT}FAILED:DB2 Operator Catalog could not be installed${RESET_TEXT}"
          echo "Exiting Script!!!!!!"
          exit 9
      fi
  done
  echo "${BLUE_TEXT}COMPLETE ${RESET_TEXT}Successfully installed DB2 Operator catalog"
}
cloudCTLInstallCP4DCloudFountaionServicesCatalog()
{
  printHeaderMessage "Case Launch - ibm-cp-common-services-${CP4D_CASE_COMMON_SERVICES_PACKAGE_VERSION} (LOG ->  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ibm-cp-common-services-launch.log)"
  cloudctl case launch \
    --case ${CASE_REPO_OFFLINE_CPFS}/ibm-cp-common-services-${CP4D_CASE_COMMON_SERVICES_PACKAGE_VERSION}.tgz \
    --inventory ibmCommonServiceOperatorSetup \
    --namespace openshift-marketplace \
    --action install-catalog \
    --args "--registry icr.io --inputDir ${OFFLINEDIR_CPFS} --recursive" &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ibm-cp-common-services-launch.log
  #Need to check for errors in ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ibm-cp-common-services-launch.log
  echo "${BLUE_TEXT}COMPLETE ${RESET_TEXT}cloudclt Launch command finished"
  echo ""
  OCO_STATUS=`oc get catalogsource -n openshift-marketplace opencloud-operators  -o jsonpath='{.status.connectionState.lastObservedState} {"\n"}' | sed 's/ *$//g'`
  let  LOOP_COUNT=1
  while [ "${OCO_STATUS}" != "READY"  ]
  do
      blinkWaitMessage "Waiting for opencloud-operators(IBM Common Serivces) catalog to be ready." 60
      OCO_STATUS=`oc get catalogsource -n openshift-marketplace opencloud-operators  -o jsonpath='{.status.connectionState.lastObservedState} {"\n"}' | sed 's/ *$//g'`
      let LOOP_COUNT=LOOP_COUNT+1
      if [ $LOOP_COUNT -ge 10 ] ;then
          echo "${RED_TEXT}FAILED:opencloud-operators catalog could not be installed${RESET_TEXT}"
          echo "Exiting Script!!!!!!"
          exit 9
      fi
  done
  echo "${BLUE_TEXT}COMPLETE ${RESET_TEXT}Successfully installed opencloud-operators(IBM Common Serivces) catalog"
}
