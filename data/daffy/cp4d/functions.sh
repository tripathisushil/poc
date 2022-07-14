#!/bin/bash
############################################################
#Author           : Kyle Dawson
#Author email     : Kyle.Dawson@us.ibm.com
#Original Date    : 2020-09-10
#Initial Version  : v2021-12-01
############################################################
#Setup Variables
############################################################

cp4dNamespaces()
{
  if [[ "${CP4D_SPECIALIZED_INSTALL}" == "true" ]]; then
    CP4D_INSTALL_TYPE=Specialized
    CP4D_OPERATORS_NAMESPACE=${CP4D_OPERATORS_NAMESPACE_SPECIALIZED}
    CP4D_INSTANCE_NAMESPACE=${CP4D_INSTANCE_NAMESPACE_SPECIALIZED}
  else
    CP4D_INSTALL_TYPE=Express
    CP4D_OPERATORS_NAMESPACE=${CP4D_OPERATORS_NAMESPACE_EXPRESS}
    CP4D_INSTANCE_NAMESPACE=${CP4D_INSTANCE_NAMESPACE_EXPRESS}
  fi
}
validateCP4DVersion()
{
  case ${CP4D_VERSION} in
     4.0.2|4.0.3|4.0.4|4.0.5|4.0.6|4.0.7|4.0.8)
        echo "${BLUE_TEXT}PASSED ${RESET_TEXT} Valid version CP4D_VERSION=${CP4D_VERSION}"
        ;;
     *)
       echo "${RED_TEXT}FAILED: Invalid version CP4D_VERSION=${CP4D_VERSION}${RESET_TEXT}"
       echo "${RED_TEXT}Current Supported Versions 4.0.2, 4.0.3, 4.0.4, 4.0.5, 4.0.6 4.0.7 or 4.0.8${RESET_TEXT}"
       SHOULD_EXIT=1
       ;;
  esac

  CP4D_ZEN_VERSION=`oc get ZenService lite-cr -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.status.currentVersion} {"\n"}' 2> /dev/null`
  if [ -z ${CP4D_ZEN_VERSION} ]; then
    CP4D_ZEN_VERSION="Not Found"
  fi
  OCP_SERVER_VERSION=`oc version 2> /dev/null| grep Server | awk '{print $3}'`
  if [ -z ${OCP_SERVER_VERSION} ]; then
    OCP_SERVER_VERSION="Not Found"
  fi

}
precheckCP4D()
{
  printHeaderMessage "Prechecks"

  baseValidation
  prepareHost
  validateCloudPakSize
  #Namespaces
  resourcePresent ${DIR}/templates/namespaces/ibm-common-services.yaml
  resourcePresent ${DIR}/templates/namespaces/cpd-operators.yaml
  resourcePresent ${DIR}/templates/namespaces/cpd-instance.yaml
  #Tunning/Configs
  resourcePresent ${DIR}/templates/machineconfig/99-worker-cp4d-crio-conf.yaml
  resourcePresent ${DIR}/templates/machineconfig/99-worker-cp4d-crio.conf
  resourcePresent ${DIR}/templates/tuned/cp4d-wkc-ipc.yaml
  resourcePresent ${DIR}/templates/kubeletconfig/db2u-kubelet.yaml

  #security
  resourcePresent ${DIR}/templates/scc/wkc-iis-scc.yaml

  #security
  resourcePresent ${DIR}/templates/namespacescope/cpd-operators.yaml

  #CP4D Specific
  resourcePresent ${DIR}/templates/customresource/ibmcpd.yaml
  resourcePresent ${DIR}/templates/operatorgroup/ibm-common-services.yaml
  resourcePresent ${DIR}/templates/operatorgroup/cpd-operators.yaml

  #Catalog Source
  resourcePresent ${DIR}/templates/catalogsource/ibm-operator-catalog/catalogsource.yaml
  resourcePresent ${DIR}/templates/catalogsource/ibm-db2uoperator-catalog/catalogsource.yaml

  getIBMEntitlementKey
  variablePresent ${CP4D_VERSION} CP4D_VERSION
  variablePresent ${IBM_ENTITLEMENT_KEY} IBM_ENTITLEMENT_KEY
  variablePresent ${CP_REGISTRY} CP_REGISTRY
  variablePresent ${CP_REGISTRY_EMAIL} CP_REGISTRY_EMAIL
  validateCP4DVersion
  validOCPVersion
  validateStorage ${CP4D_STORAGE_CLASS}
  case ${OCP_INSTALL_TYPE} in
    roks-msp)
        testIBMCloudLogin
        waitForROKSClusterReady
        ;;
  esac
  getOpenShiftTools
  validateOCPAccess
  echo ""
  if [ "${CP4D_CLOUDCTL_CASE_BUILD_OUT}"  == "true" ]; then
    if [ "${CP4D_LATEST_CLOUDCTL_VERSION}" == "${CP4D_VERSION}" ]; then
      cloudCTLInstall
    else
      echo "${RED_TEXT}FAILED ${RESET_TEXT} CP4D_CLOUDCTL_CASE_BUILD_OUT=true not suppported. Daffy only supports case build out with latest tested CP4D CloudCTL version - ${CP4D_LATEST_CLOUDCTL_VERSION}"
      echo "${BLUE_TEXT}INFO ${RESET_TEXT} If you wish to install CP4D ${CP4D_VERSION}, please set CP4D_CLOUDCTL_CASE_BUILD_OUT=false and try again."
      SHOULD_EXIT="1"
   fi
  fi
  if [[ "${CP4D_SPECIALIZED_INSTALL}" == "true" ]]; then
      SHOULD_EXIT=1
      echo "${RED_TEXT}FAILED ${RESET_TEXT} CP4D_SPECIALIZED_INSTALL=true not suppported yet. Please remove from env file and try again."
  fi
  echo ""
  shouldExit
  echo ""
  echo "All prechecks passed, lets get to work."
  echo ""

}
prepareCP4DInputFiles()
{
  printHeaderMessage "Prepare CP4D Input Files"
  mkdir -p ${TEMP_DIR}/${PRODUCT_SHORT_NAME}
  cd ${TEMP_DIR}/${PRODUCT_SHORT_NAME}
  cp -fR ${DIR}/templates/* ${TEMP_DIR}/${PRODUCT_SHORT_NAME}
  cp4dSetCatalogSource

  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@CP4D_PLATFORM_OPERATOR_CHANNEL@/$CP4D_PLATFORM_OPERATOR_CHANNEL/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@CP4D_IBM_CPD_SCHEDULING_OPERATOR_CHANNEL@/$CP4D_IBM_CPD_SCHEDULING_OPERATOR_CHANNEL/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@CP4D_INSTALL_PLAN_APPROVAL@/$CP4D_INSTALL_PLAN_APPROVAL/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s|@TEMP_DIR@|$TEMP_DIR|g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@PRODUCT_SHORT_NAME@/$PRODUCT_SHORT_NAME/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@CP4D_STORAGE_CLASS@/$CP4D_STORAGE_CLASS/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@CP4D_STORAGE_VENDOR@/$CP4D_STORAGE_VENDOR/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@CP4D_WKC_DB2U_SET_KERNAL_PARMS@/$CP4D_WKC_DB2U_SET_KERNAL_PARMS/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@CP4D_IIS_DB2U_SET_KERNAL_PARMS@/$CP4D_IIS_DB2U_SET_KERNAL_PARMS/g"

  #Versions
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@CP4D_VERSION@/$CP4D_VERSION/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@CP4D_DV_VERSION@/$CP4D_DV_VERSION/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@CP4D_CASE_WKS_VERSION@/$CP4D_CASE_WKS_VERSION/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@CP4D_WKS_VERSION@/$CP4D_WKS_VERSION/g"

  #Catalogs main
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@IBM_CLOUD_CATALOG_SOURCE@/$IBM_CLOUD_CATALOG_SOURCE/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@IBM_CLOUD_CPD_CATALOG_SOURCE@/$IBM_CLOUD_CPD_CATALOG_SOURCE/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@IBM_CLOUD_CPD_SCHEDULING_CATALOG_SOURCE@/$IBM_CLOUD_CPD_SCHEDULING_CATALOG_SOURCE/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@IBM_CLOUD_DB2UOPERATOR_CATALOG_SOURCE@/$IBM_CLOUD_DB2UOPERATOR_CATALOG_SOURCE/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@CP4D_IBM_OPERATOR_CATALOG_TAG@/$CP4D_IBM_OPERATOR_CATALOG_TAG/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@CP4D_IBM_CPD_DATASTAGE_OPERATOR_CHANNEL@/$CP4D_IBM_CPD_DATASTAGE_OPERATOR_CHANNEL/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@CP4D_IBM_DODS_OPERATOR_CHANNEL@/$CP4D_IBM_DODS_OPERATOR_CHANNEL/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@CP4D_IBM_DMC_OPERATOR_CHANNEL@/$CP4D_IBM_DMC_OPERATOR_CHANNEL/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@CP4D_IBM_CPD_COGNOS_OPERATOR_CHANNEL@/$CP4D_IBM_CPD_COGNOS_OPERATOR_CHANNEL/g"

  #Catalogs Services
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@IBM_CLOUD_CPD_WKC_CATALOG_SOURCE@/$IBM_CLOUD_CPD_WKC_CATALOG_SOURCE/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@IBM_CLOUD_CPD_WKS_CATALOG_SOURCE@/$IBM_CLOUD_CPD_WKS_CATALOG_SOURCE/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@IBM_CLOUD_CPD_SPSS_CATALOG_SOURCE@/$IBM_CLOUD_CPD_SPSS_CATALOG_SOURCE/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@IBM_CLOUD_CPD_DV_CATALOG_SOURCE@/$IBM_CLOUD_CPD_DV_CATALOG_SOURCE/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@IBM_CLOUD_CPD_WS_CATALOG_SOURCE@/$IBM_CLOUD_CPD_WS_CATALOG_SOURCE/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@IBM_CLOUD_CPD_WML_CATALOG_SOURCE@/$IBM_CLOUD_CPD_WML_CATALOG_SOURCE/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@IBM_CLOUD_CPD_EDB_CATALOG_SOURCE@/$IBM_CLOUD_CPD_EDB_CATALOG_SOURCE/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@IBM_CLOUD_CPD_DATASTAGE_CATALOG_SOURCE@/$IBM_CLOUD_CPD_DATASTAGE_CATALOG_SOURCE/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@IBM_CLOUD_CPD_DODS_CATALOG_SOURCE@/$IBM_CLOUD_CPD_DODS_CATALOG_SOURCE/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@IBM_CLOUD_CPD_DMC_CATALOG_SOURCE@/$IBM_CLOUD_CPD_DMC_CATALOG_SOURCE/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@IBM_CLOUD_CPD_COGNOS_CATALOG_SOURCE@/$IBM_CLOUD_CPD_COGNOS_CATALOG_SOURCE/g"

  #Install Type for Namespace
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@CP4D_OPERATORS_NAMESPACE@/$CP4D_OPERATORS_NAMESPACE/g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@CP4D_INSTANCE_NAMESPACE@/$CP4D_INSTANCE_NAMESPACE/g"


}

displayCP4DAdminConsoleInfo()
{
  ZEN_SERVICE_STATUS=`oc get ZenService lite-cr -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath="{.status.url}{'\n'}" 2>&1| grep -c Error`
  CP4D_URL=`oc get ZenService lite-cr -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath="{.status.url}{'\n'}"`
  if [ "${ZEN_SERVICE_STATUS}" == "0" ] && [ -n ${CP4D_URL}  ]; then
      CP4D_USER="admin"
      CP4D_PASSWORD=`oc extract secret/admin-user-details --keys=initial_admin_password --to=- -n ${CP4D_INSTANCE_NAMESPACE} 2> /dev/null`

      echo "${BLUE_TEXT}Here is the login info for the CP4D Navigator console:"
      echo "##########################################################################################################${RESET_TEXT}"
      echo "Super User            :      ${CP4D_USER}"
      echo "Password              :      ${CP4D_PASSWORD}"
      echo "CP4D Web Console      :      ${BLUE_TEXT}https://${CP4D_URL}${RESET_TEXT}"
      printf "\n\n\n${RESET_TEXT}"
  else
    echo "${RED_TEXT}Zen Service is not available.${RESET_TEXT}"
    printf "\n\n\n"
  fi

}

waitForZenServiceToComplete()
{
  startWaitForZenService=$SECONDS
  printHeaderMessage "Wait for ZenService to complete"
  echo ""
  blinkWaitMessage "Waiting 15 minutes before we start to check (Go get a Coffee!)" 900
  ZENSERVICE_STATUS=`oc get ZenService lite-cr -n ${CP4D_INSTANCE_NAMESPACE}  -o jsonpath="{.status.zenStatus}{'\\n'}" 2>/dev/null`
  while [ "${ZENSERVICE_STATUS}" != "Completed" ]
  do
    blinkWaitMessage "Still waiting  - almost there, will keep checking every 60 seconds" 60
    ZENSERVICE_STATUS=`oc get ZenService lite-cr  -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath="{.status.zenStatus}{'\\n'}" 2>/dev/null`

  done
  now=$SECONDS
  let "diff=now-startWaitForZenService"
  startWaitForZenService=${diff}
  if (( $startWaitForZenService > 3600 )) ; then
      let "hours=startWaitForZenService/3600"
      let "minutes=(startWaitForZenService%3600)/60"
      let "seconds=(startWaitForZenService%3600)%60"
      echo "${BLUE_TEXT}COMPLETE ${RESET_TEXT}Zen Service was created in $hours hour(s), $minutes minute(s) and $seconds second(s)( :( Your system is really slow, you may think about just shutting it down and going home?)"
  elif (( $startWaitForZenService > 60 )) ; then
      let "minutes=(startWaitForZenService%3600)/60"
      let "seconds=(startWaitForZenService%3600)%60"
      echo "${BLUE_TEXT}COMPLETE ${RESET_TEXT}Zen Service was created in $minutes minute(s) and $seconds second(s)"
  else
      echo "${BLUE_TEXT}COMPLETE ${RESET_TEXT}Zen Service was created in $startWaitForZenService seconds (WOW insane speed, you have a great system)"
  fi
}

processCP4DOperators()
{
  if [ "${1}" == "apply" ];then
    printHeaderMessage "Creating CP4D Operators"
  else
    printHeaderMessage "Deleting CP4D Operators"  ${RED_TEXT}
  fi
  oc ${1} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/operatorgroup/ibm-common-services.yaml
  oc ${1} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/operatorgroup/cpd-instance.yaml
  if [[ "${CP4D_SPECIALIZED_INSTALL}" == "true" ]]; then
    oc ${1} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/operatorgroup/cpd-operators.yaml
  fi
  oc ${1} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/subscriptions/ibm-common-service-operator/subscription.yaml
  oc ${1} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/subscriptions/ibm-cpd-scheduling-catalog-subscription/subscription.yaml
  oc ${1} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/subscriptions/cpd-operator/subscription.yaml
  oc ${1} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/subscriptions/ibm-db2u-operator/subscription.yaml
  IBM_NAMESPACESCOPE_OPERATOR_READY=`oc get csv -A 2> /dev/null | grep ibm-namespace-scope-operator 2> /dev/null | grep -c Succeeded`
  while [ "${IBM_NAMESPACESCOPE_OPERATOR_READY}" != "1"  ]
  do
    blinkWaitMessage "Waiting for NamespaceScope Operator to be installed before we create instance" 10
    IBM_NAMESPACESCOPE_OPERATOR_READY=`oc get csv -A 2> /dev/null | grep ibm-namespace-scope-operator 2> /dev/null | grep -c Succeeded`
  done
  echo "${BLUE_TEXT}COMPLETE ${RESET_TEXT}NamespaceScope Operator exist"
  oc ${1} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/namespacescope/cpd-operators.yaml

  if [ "${1}" == "delete" ];then
      echo "Before we can continue, you must us the console to remove the following Operators manually:"
      echo "Cloud Pak for Data"
      echo "IBM Cert Manager"
      echo "IBM Cloud Pak founditional services"
      echo "IBM NamespaceScope Operator"
      echo "Operand Deployment Lifecycle Manager"
      read -p "Press [Enter] key once they have been removed."
  fi
  echo ""
}
processCP4DNameSpaces()
{
  if [ "${1}" == "apply" ];then
    printHeaderMessage "Creating CP4D Namespaces for ${CP4D_INSTALL_TYPE} install"
  else
    printHeaderMessage "Deleting CP4D Namespaces"  ${RED_TEXT}
  fi
  oc ${1} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/namespaces/ibm-common-services.yaml
  applyNameSpaceLabels ibm-common-services 'IBM Common Services'

  oc ${1} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/namespaces/cpd-instance.yaml
  applyNameSpaceLabels ${CP4D_INSTANCE_NAMESPACE} 'IBM CP4D Services'

  if [[ "${CP4D_SPECIALIZED_INSTALL}" == "true" ]]; then
    oc ${1} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/namespaces/cpd-operators.yaml
    applyNameSpaceLabels ${CP4D_OPERATORS_NAMESPACE} 'IBM CP4D Operators'
  fi
  echo ""
}

processCP4DCatalogSource()
{
  if [ "${1}" == "apply" ];then
    printHeaderMessage "Processing CP4D CatalogSources"
  else
    printHeaderMessage "Deleting CP4D CatalogSources"  ${RED_TEXT}
  fi
  oc ${1} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/catalogsource/ibm-operator-catalog/catalogsource.yaml
  oc ${1} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/catalogsource/ibm-db2uoperator-catalog/catalogsource.yaml
  echo ""

}

processCP4DMachineConfigs()
{
  if [ "${1}" == "apply" ];then
    printHeaderMessage "Processing CP4D Machine-Configs"
  else
    printHeaderMessage "Deleting CP4D Machine-Configs"  ${RED_TEXT}
  fi
  if [ ${1} == "apply" ];then
    case ${OCP_INSTALL_TYPE} in
      vsphere-upi|vsphere-ipi|aws-ipi|gcp-ipi|azure-ipi|kvm-upi)
          cp ${DATA_DIR}/${PROJECT_NAME}/${PRODUCT_SHORT_NAME}/templates/machineconfig/* ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/machineconfig
          local CP4D_CRIO_CONFIG_VALUE_BASE64="$(cat ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/machineconfig/99-worker-cp4d-crio.conf | base64 -w0)"
          find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@CP4D_CRIO_CONFIG_VALUE_BASE64@/$CP4D_CRIO_CONFIG_VALUE_BASE64/g"
          oc ${1} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/machineconfig/99-worker-cp4d-crio-conf.yaml
          echo ""
          waitForNodesToFinishUpdate
          ;;
    esac

  fi

}
processCP4DTuneNodes()
{
  if [ "${1}" == "apply" ];then
    printHeaderMessage "Processing CP4D Tuning"
  else
    printHeaderMessage "Deleting CP4D Tuning"  ${RED_TEXT}
  fi
  if [ ${1} == "delete" ];then
    case ${OCP_INSTALL_TYPE} in
      vsphere-upi|vsphere-ipi|aws-ipi|gcp-ipi|azure-ipi|kvm-upi)
          oc label machineconfigpool worker db2u-kubelet-
          ;;
    esac
  fi
  if [ ${1} == "apply" ];then
    case ${OCP_INSTALL_TYPE} in
      vsphere-upi|vsphere-ipi|aws-ipi|gcp-ipi|azure-ipi|kvm-upi)
          oc ${1} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/kubeletconfig/db2u-kubelet.yaml
          oc ${1} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/tuned/cp4d-wkc-ipc.yaml
          oc label machineconfigpool worker db2u-kubelet=sysctl --overwrite
          waitForNodesToFinishUpdate
          ;;
    esac
  fi

  echo ""

}
processCP4DInstance()
{
  if [ "${1}" == "apply" ];then
    printHeaderMessage "Processing CP4D Instance"
  else
    printHeaderMessage "Deleting CP4D Instance" ${RED_TEXT}
  fi
  echo ""
  let  LOOP_COUNT=1
  #Create CP4D Instance
  ######################################
  IBMCDS_KIND_READY="NOT_READY"
  while [ "${IBMCDS_KIND_READY}" != "1"  ]
  do
      blinkWaitMessage "Waiting for Ibmcpd to be installed - wait 15 minutes(${LOOP_COUNT})" 30
      IBMCDS_KIND_READY=`oc get crd | grep -c ibmcpds.cpd.ibm.com`
      if [ "${IBMCDS_KIND_READY}" == "1" ]  ;then
            if [ ${CP4D_CLOUDCTL_CASE_BUILD_OUT} == "true" ]; then
              oc ${1} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/operand/request-case.yaml
            else
              oc ${1} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/operand/request-empty.yaml
            fi
          #fi
          oc ${1} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/customresource/ibmcpd.yaml
          echo ""
          if [ ${1} == "apply" ];then
            waitForZenServiceToComplete
          fi
      fi
      if [ $LOOP_COUNT -ge 30 ] ;then
          echo "IBM Cloud Pak for Data Service could not be installed"
          echo "After some time, you can run the following command to finsish the setup"
          echo "                           ${RED_TEXT}oc ${1} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/operandrequest.yaml${RESET_TEXT}"
          echo "                           ${RED_TEXT}oc ${1} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/customresource/ibmcpd.yaml${RESET_TEXT}"
          echo ""
          break
      fi
      let  LOOP_COUNT=LOOP_COUNT+1
  done
  echo ""
}

precheckCP4DService()
{
    printHeaderMessage "Prechecks CP4D Services"
    prepareHost
    validateCloudPakSize
    #Subscriptions
    resourcePresent ${DIR}/templates/subscriptions/ibm-cpd-scheduling-catalog-subscription/subscription.yaml
    resourcePresent ${DIR}/templates/subscriptions/cpd-operator/subscription.yaml
    resourcePresent ${DIR}/templates/subscriptions/ibm-db2u-operator/subscription.yaml
    resourcePresent ${DIR}/templates/subscriptions/ibm-dv-operator-catalog-subscription/subscription.yaml
    resourcePresent ${DIR}/templates/subscriptions/ibm-cpd-wkc-operator-catalog-subscription/subscription.yaml
    resourcePresent ${DIR}/templates/subscriptions/ibm-watson-ks-operator-subscription/subscription.yaml
    resourcePresent ${DIR}/templates/subscriptions/ibm-cpd-ws-operator-catalog-subscription/subscription.yaml

    #Custom Resource
    resourcePresent ${DIR}/templates/customresource/dvservice.yaml
    resourcePresent ${DIR}/templates/customresource/ibmcpd.yaml
    resourcePresent ${DIR}/templates/customresource/knowledgestudio.yaml
    resourcePresent ${DIR}/templates/customresource/spss.yaml
    resourcePresent ${DIR}/templates/customresource/wkc.yaml
    resourcePresent ${DIR}/templates/customresource/wml.yaml
    resourcePresent ${DIR}/templates/customresource/ws.yaml
    resourcePresent ${DIR}/templates/customresource/cognos.yaml

    #Machine Config
    resourcePresent ${DIR}/templates/machineconfig/99-worker-cp4d-crio-conf.yaml
    resourcePresent ${DIR}/templates/machineconfig/99-worker-cp4d-crio.conf

    #DBD Config
    resourcePresent ${DIR}/templates/kubeletconfig/db2u-kubelet.yaml

    #Operand Config
    resourcePresent ${DIR}/templates/operand/request-case.yaml
    resourcePresent ${DIR}/templates/operand/request-empty.yaml

    #Tuned Config
    resourcePresent ${DIR}/templates/tuned/cp4d-wkc-ipc.yaml

    #SCC Config
    resourcePresent ${DIR}/templates/scc/wkc-iis-scc.yaml

    getOpenShiftTools
    validateCP4DVersion
    validateOCPAccess
    variablePresent ${CP4D_PLATFORM_OPERATOR_CHANNEL} CP4D_PLATFORM_OPERATOR_CHANNEL
    variablePresent ${CP4D_IBM_CPD_SCHEDULING_OPERATOR_CHANNEL} CP4D_IBM_CPD_SCHEDULING_OPERATOR_CHANNEL
    if [ "${CP4D_CLOUDCTL_CASE_BUILD_OUT}"  == "true" ]; then
      if [ "${CP4D_LATEST_CLOUDCTL_VERSION}" == "${CP4D_VERSION}" ]; then
          echo "${BLUE_TEXT}PASSED ${RESET_TEXT} Cloud CTL support on this version of CP4D ${CP4D_VERSION}"
          cloudCTLInstall
      else
        echo "${RED_TEXT}FAILED ${RESET_TEXT} CP4D_CLOUDCTL_CASE_BUILD_OUT=true not suppported. Daffy only supports latest CP4D - ${CP4D_LATEST_CLOUDCTL_VERSION}"
        SHOULD_EXIT="1"
      fi
    fi
    validateStorage ${CP4D_STORAGE_CLASS}
    # Validate CP4D DODS service has dependant services enabled.
    if [ "${CP4D_ENABLE_SERVICE_DODS}" == "true" ] && [ "${SERVCIES_MODE}" == "apply" ]; then
      # These are 2 services that are REQUIRED for the DODS service to be installed.
      if [ "${CP4D_ENABLE_SERVICE_WML}" != "true" ] || [ "${CP4D_ENABLE_SERVICE_WS}" != "true" ]; then
        printHeaderMessage "Missing DDOS Services Dependency Requirements " ${RED_TEXT}
        echo "Please enable the following services in your env file and re-run the services deployment!"
        echo "    CP4D_ENABLE_SERVICE_WS=true"
        echo "    CP4D_ENABLE_SERVICE_WML=true"
        echo " "
        SHOULD_EXIT="1"
      fi
    fi
    if [ "${CP4D_ENABLE_SERVICE_SPSS}" == "true" ] && [ "${SERVCIES_MODE}" == "apply" ] && [ "${CP4D_ENABLE_SERVICE_WS}" != "true" ]; then
        printHeaderMessage "Missing SPSS Services Dependency Requirements " ${RED_TEXT}
        echo "Please enable the following services in your env file and re-run the services deployment!"
        echo "    CP4D_ENABLE_SERVICE_WS=true"
        echo " "
        SHOULD_EXIT="1"
    fi
    if [ "${CP4D_ENABLE_SERVICE_DV}" == "true" ] && [ "${SERVCIES_MODE}" == "apply" ] && [ "${CP4D_ENABLE_SERVICE_DMC}" != "true" ]; then
        printHeaderMessage "Missing Data Virtualization Dependency Requirements " ${RED_TEXT}
        echo "Please enable the following services in your env file and re-run the services deployment!"
        echo "    CP4D_ENABLE_SERVICE_DMC=true"
        echo " "
        SHOULD_EXIT="1"
    fi
    if [ "${CP4D_ENABLE_SERVICE_COGNOS}" == "true" ]; then
        SHOULD_EXIT="1"
        echo "${RED_TEXT}ERROR  ${RESET_TEXT} CP4D_ENABLE_SERVICE_COGNOS=true was removed, please update your environment file with CP4D_ENABLE_SERVICE_COGNOS_DASHBOARDS=true"
    fi
    shouldExit
    echo "All prechecks passed, lets get to work."
    echo ""

}



displayCP4DStatus()
{
  printHeaderMessage "Display Cloud Pak for Data Status"
  validateCP4DVersion
  echo "Daffy Version                 :  ${DAFFY_VERSION}"
  echo "Bastion OS                    :  ${OS_FLAVOR}"
  echo "Platform Install Type         :  ${OCP_INSTALL_TYPE}"
  echo "OpenShift Version             :  ${OCP_SERVER_VERSION}"
  local CONTROL_PLANE_STATUS=`oc get Ibmcpd ibmcpd-cr -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath="{.status.controlPlaneStatus}{'\n'}" 2> /dev/null`
  local CONTROL_PLANE_VERSION=`oc get Ibmcpd ibmcpd-cr -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath="{.spec.version}{'\n'}" 2> /dev/null`
  if [ -z ${CONTROL_PLANE_STATUS} ]; then
        CONTROL_PLANE_STATUS="Not Found"
  else
    if [ ${CONTROL_PLANE_STATUS} != "InProgress" ]  && [ ${CONTROL_PLANE_STATUS} != "Completed" ]; then
        CONTROL_PLANE_STATUS="Not Found"
    fi
  fi
  echo "Control Plane Status          :  ${CONTROL_PLANE_STATUS} - ${CONTROL_PLANE_VERSION}"

  local ZEN_STATUS=`oc get ZenService lite-cr -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath="{.status.zenStatus}{'\n'}" 2> /dev/null`
  if [ -z ${ZEN_STATUS} ]; then
      ZEN_STATUS="Not Found"
  else
      if [ ${ZEN_STATUS} != "InProgress" ]  && [ ${ZEN_STATUS} != "Completed" ]; then
          ZEN_STATUS="Not Found"
      fi
  fi
  echo "Zen Status                    :  ${ZEN_STATUS} - ${CP4D_ZEN_VERSION}"
  echo ""
}

cp4dSetCatalogSource()
{
  if [ "${CP4D_CLOUDCTL_CASE_BUILD_OUT}"  = "true" ]; then
    mkdir -p ${CASE_REPO_OFFLINE_DIR}
    mkdir -p ${CASE_REPO_OFFLINE_CPFS}
    IBM_CLOUD_CATALOG_SOURCE=opencloud-operators
    IBM_CLOUD_CPD_CATALOG_SOURCE=cpd-platform
    IBM_CLOUD_CPD_SCHEDULING_CATALOG_SOURCE=ibm-cpd-scheduling-catalog
    IBM_CLOUD_DB2UOPERATOR_CATALOG_SOURCE=ibm-db2uoperator-catalog
    IBM_CLOUD_CPD_WKC_CATALOG_SOURCE=ibm-cpd-wkc-operator-catalog
    IBM_CLOUD_CPD_WKS_CATALOG_SOURCE=ibm-watson-ks-operator-catalog
    IBM_CLOUD_CPD_DV_CATALOG_SOURCE=ibm-dv-operator-catalog
    IBM_CLOUD_CPD_SPSS_CATALOG_SOURCE=ibm-cpd-spss-operator-catalog
    IBM_CLOUD_CPD_WS_CATALOG_SOURCE=ibm-cpd-ws-operator-catalog
    IBM_CLOUD_CPD_WML_CATALOG_SOURCE=ibm-cpd-wml-operator-catalog
    IBM_CLOUD_CPD_EDB_CATALOG_SOURCE=cloud-native-postgresql-catalog
    IBM_CLOUD_CPD_DATASTAGE_CATALOG_SOURCE=ibm-cpd-datastage-operator-catalog
    IBM_CLOUD_CPD_DODS_CATALOG_SOURCE=ibm-cpd-dods-operator-catalog
    IBM_CLOUD_CPD_DMC_CATALOG_SOURCE=ibm-dmc-operator-catalog
    IBM_CLOUD_CPD_COGNOS_CATALOG_SOURCE=ibm-cde-operator-catalog
  fi

}

cp4dBuildPortworxStroageClasses()
{
    if [  "${CP4D_STORAGE_ENABLE_PORTWORX}" == "true"  ]; then

      if [ "${1}" == "apply" ];then
        printHeaderMessage "Build Portworx Storage Classes"
        local MODE="apply"
      else
        printHeaderMessage "Remove Portworx Storage Classes" ${RED_TEXT}
        local MODE="delete"
      fi
      oc ${MODE} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/storage/portworx/portworx-cassandra-sc.yaml
      oc ${MODE} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/storage/portworx/portworx-couchdb-sc.yaml
      oc ${MODE} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/storage/portworx/portworx-db-gp.yaml
      oc ${MODE} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/storage/portworx/portworx-db-gp2-sc.yaml
      oc ${MODE} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/storage/portworx/portworx-db-gp3-sc.yaml
      oc ${MODE} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/storage/portworx/portworx-db2-rwo-sc.yaml
      oc ${MODE} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/storage/portworx/portworx-db2-rwx-sc.yaml
      #Does not work
      #oc ${MODE} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/storage/portworx/portworx-db2-sc.yaml
      oc ${MODE} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/storage/portworx/portworx-dv-shared-gp3.yaml
      oc ${MODE} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/storage/portworx/portworx-elastic-sc.yaml
      oc ${MODE} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/storage/portworx/portworx-gp3-sc.yaml
      #Does not work
      #oc ${MODE} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/storage/portworx/portworx-informix-sc.yaml
      oc ${MODE} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/storage/portworx/portworx-kafka-sc.yaml
      oc ${MODE} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/storage/portworx/portworx-metastoredb-sc.yaml
      oc ${MODE} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/storage/portworx/portworx-nonshared-gp2.yaml
      oc ${MODE} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/storage/portworx/portworx-rwx-gp-sc.yaml
      oc ${MODE} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/storage/portworx/portworx-rwx-gp2-sc.yaml
      oc ${MODE} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/storage/portworx/portworx-rwx-gp3-sc.yaml
      oc ${MODE} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/storage/portworx/portworx-shared-gp-allow.yaml
      oc ${MODE} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/storage/portworx/portworx-shared-gp.yaml
      oc ${MODE} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/storage/portworx/portworx-shared-gp1.yaml
      oc ${MODE} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/storage/portworx/portworx-shared-gp3.yaml
      oc ${MODE} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/storage/portworx/portworx-solr-sc.yaml
      oc ${MODE} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/storage/portworx/portworx-watson-assistant-sc.yaml
    fi

}
cp4dServiceAllStatus()
{
  printHeaderMessage "Cloud Pak for Data Service - All Status"
  validateCP4DVersion &>/dev/null
  echo "Daffy Version                               :  ${DAFFY_VERSION}"
  echo "Bastion OS                                  :  ${OS_FLAVOR}"
  echo "Platform Install Type                       :  ${OCP_INSTALL_TYPE}"
  echo "OpenShift Version                           :  ${OCP_SERVER_VERSION}"
  echo "Zen Version                                 :  ${CP4D_ZEN_VERSION}"
  local DV_VERSION=`oc get DvService dv-service -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.spec.version}' 2> /dev/null`
  if [ -z ${DV_VERSION} ]; then
    DV_VERSION=""
  fi
  local DV_STATUS=`oc get DvService dv-service -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.status.reconcileStatus}' 2> /dev/null`
  if [ -z ${DV_STATUS} ]; then
    DV_STATUS="Not Found"
  fi
  echo "Data Virtualization                         :  ${DV_STATUS} - ${DV_VERSION}"
  local SPSS_VERSION=`oc get Spss spss -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.spec.version}' 2> /dev/null`
  local SPSS_CR_STATUS=`oc get Spss spss -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.status.spssmodelerStatus} {"\n"}' 2> /dev/null | sed 's/ *$//g'`
  if [ -z ${SPSS_CR_STATUS} ]; then
    SPSS_CR_STATUS="Not Found"
  fi
  echo "Statistical Package for the Social Sciences :  ${SPSS_CR_STATUS} - ${SPSS_VERSION}"
  local WKC_STATUS=`oc get WKC wkc-cr -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.status.wkcStatus} {"\n"}' 2> /dev/null | sed 's/ *$//g'`
  local WKC_LOCAL_VERSION=`oc get WKC wkc-cr -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.spec.version} {"\n"}' 2> /dev/null`
  if [ -z ${WKC_STATUS} ]; then
    WKC_STATUS="Not Found"
  else
    if [ ${WKC_STATUS} != "InProgress" ] &&  [ ${WKC_STATUS} != "Completed" ]; then
      WKC_STATUS="Not Found"
    fi
  fi
  echo "Watson Knowledge Catalog                    :  ${WKC_STATUS} - ${WKC_LOCAL_VERSION}"
  local WKS_CR_STATUS=`oc get wks wks -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.status.conditions[?(@.type=="Deployed")].status}' 2> /dev/null`
  local WKS_CR_STATUS_ERROR=`oc get wks wks -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.status.conditions[?(@.type=="ReleaseFailed")].reason}' 2> /dev/null`
  local WKS_VERSION=`oc get wks wks -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.spec.version}' 2> /dev/null`
  if [ "${WKS_CR_STATUS_ERROR}" != "" ]; then
    WKS_CR_STATUS=${WKS_CR_STATUS_ERROR}
  fi
  if [ -z ${WKS_CR_STATUS} ]; then
    WKS_CR_STATUS="Not Found"
    WKS_VERSION=""
  fi
  echo "Watson Knowledge Studio                     :  ${WKS_CR_STATUS} - ${WKS_VERSION}"
  local WML_VERSION=`oc get WmlBase wml-cr -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.spec.version}' 2> /dev/null`
  local WML_CR_STATUS=`oc get WmlBase wml-cr -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.status.wmlStatus} {"\n"}' 2> /dev/null | sed 's/ *$//g'`
  if [ -z ${WML_CR_STATUS} ]; then
    WML_CR_STATUS="Not Found"
    WML_VERSION=""
  fi

  echo "Watson Machine Learning                     :  ${WML_CR_STATUS} - ${WML_VERSION}"
  CP4D_WS_VERSION=`oc get WS ws-cr -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.spec.version} {"\n"}' 2> /dev/null`
  CP4D_WS_STATUS=`oc get WS ws-cr -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.status.wsStatus} {"\n"}' 2> /dev/null | sed 's/ *$//g'`
  if [ -z ${CP4D_WS_VERSION} ]; then
      CP4D_WS_VERSION=""
  fi
  if [ -z ${CP4D_WS_STATUS} ]; then
      CP4D_WS_STATUS="Not Found"
  fi
  echo "Watson Studio                               :  ${CP4D_WS_STATUS} - ${CP4D_WS_VERSION}"
  local DATASTAGE_VERSION=`oc get DATASTAGE datastage -n ${CP4D_INSTANCE_NAMESPACE}  -o jsonpath='{.spec.version} {"\n"}' 2>/dev/null`
  local DATASTAGE_VERSION_MIN=`oc get DATASTAGE datastage -n ${CP4D_INSTANCE_NAMESPACE}  -o jsonpath='{.status.dsBuildNumber} {"\n"}' 2>/dev/null`
  local DATASTAGE_CR_STATUS=`oc get DATASTAGE datastage -n ${CP4D_INSTANCE_NAMESPACE}  -o jsonpath='{.status.dsStatus} {"\n"}' 2>/dev/null | sed 's/ *$//g'`
  if [ -z ${DATASTAGE_CR_STATUS} ]; then
    DATASTAGE_CR_STATUS="Not Found"
  fi
  echo "DataStage                                   :  ${DATASTAGE_CR_STATUS} - ${DATASTAGE_VERSION}"
  local DODS_CR_STATUS=`oc get DODS dods-cr -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.status.dodsStatus} {"\n"}' 2> /dev/null | sed 's/ *$//g'`
  local DODS_CR_VERSION=`oc get DODS dods-cr -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.spec.version} {"\n"}' 2> /dev/null`
  if [ -z ${DODS_CR_STATUS} ]; then
    DODS_CR_STATUS="Not Found"
  fi
  echo "Decision Optimization                       :  ${DODS_CR_STATUS} - ${DODS_CR_VERSION}"

  local DMC_CR_STATUS=`oc get Dmcaddon dmc-cr -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.status.dmcAddonStatus} {"\n"}' 2> /dev/null | sed 's/ *$//g'`
  local DMC_CR_VERSION=`oc get Dmcaddon dmc-cr -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.spec.version} {"\n"}' 2> /dev/null`
  if [ -z ${DMC_CR_STATUS} ]; then
    DMC_CR_STATUS="Not Found"
  fi
  echo "DB2 Management Console                      :  ${DMC_CR_STATUS} - ${DMC_CR_VERSION}"

  local COGNOS_CR_STATUS=`oc get CdeProxyService cdeproxyservice-cr -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.status.cdeStatus} {"\n"}' 2> /dev/null | sed 's/ *$//g'`
  local COGNOS_CR_VERSION=`oc get CdeProxyService cdeproxyservice-cr -n ${CP4D_INSTANCE_NAMESPACE} -o jsonpath='{.spec.version} {"\n"}' 2> /dev/null`
  if [ -z ${COGNOS_CR_STATUS} ]; then
    COGNOS_CR_STATUS="Not Found"
  fi
  echo "Cognos Dashboard                            :  ${COGNOS_CR_STATUS} - ${COGNOS_CR_VERSION}"

}
