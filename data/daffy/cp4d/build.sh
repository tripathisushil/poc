#!/bin/bash
############################################################
#Author           : Kyle Dawson
#Author email     : Kyle.Dawson@us.ibm.com
#Original Date    : 2020-09-10
#Initial Version  : v2021-12-01
############################################################
#Setup Variables
############################################################
DIR="$( cd "$( dirname "$0" )" && pwd )"
PRODUCT_SHORT_NAME=cp4d
PRODUCT_FUNCTION=build
ENVIRONMENT_FILE=${1}
source ${DIR}/../env/${1}-env.sh &> /dev/null
source ${DIR}/../env.sh
source ${DIR}/env.sh
source ${DIR}/functions.sh
source ${DIR}/../functions.sh
source ${DIR}/../fixpaks/env.sh

#Source other functions
#############################################
source ${DATA_DIR}/${PROJECT_NAME}/util/ibmcloud.sh
source ${DATA_DIR}/${PROJECT_NAME}/util/cloudctl.sh
source ${DIR}/util/cloudctl.sh
source ${DATA_DIR}/${PROJECT_NAME}/util/providers/macos.sh
OS
if [ "${MAC}" == "true" ]; then
   macCheckOCP
   macPrepareHost
   macSetupContainer
   macGetDaffy
   macCopyEnvFile
   case ${2} in
     --*)
        echo "Running container with podman exec -it daffy /bin/bash -c /data/daffy/cp4d/build.sh ${ENVIRONMENT_FILE} ${2}"
        echo "${RESET_TEXT}"
        echo ""
        podman exec -it daffy /bin/bash -c "/data/daffy/cp4d/build.sh ${ENVIRONMENT_FILE} ${2}"
        exit 99 # Exiting script due to work being done in container
        ;;
   esac
   echo "Running container with podman exec -it daffy /bin/bash -c /data/daffy/cp4d/build.sh ${ENVIRONMENT_FILE}"
   podman exec -it daffy /bin/bash -c "/data/daffy/cp4d/build.sh ${ENVIRONMENT_FILE}"
   podman cp daffy:/data/daffy/tmp/${CLUSTER_NAME}/${PRODUCT_SHORT_NAME} ${TEMP_DIR}
   podman cp daffy:/data/daffy/log/${CLUSTER_NAME}/${PRODUCT_SHORT_NAME} ${LOG_DIR}
   exit 99
fi
mkdir -p ${LOG_DIR}/${PRODUCT_SHORT_NAME}
mkdir -p ${TEMP_DIR}/${PRODUCT_SHORT_NAME}
CP_FUNCTION_NAME="CP4D Build"
cp4dNamespaces
logIntoCluster
case ${2} in
  --precheck|--Precheck)
        precheckCP4D
        exit 0
        ;;
  --console|--Console)
        displayCP4DAdminConsoleInfo
        exit 0
        ;;
  --status|--Status|--AllStatus)
        displayCP4DStatus
        exit 0
        ;;
  --processCP4DInstance|--ProcessCP4DInstance)
        processCP4DInstance
        exit 0
        ;;
  --processCP4DMachineConfigs|--ProcessCP4DMachineConfigs)
        processCP4DMachineConfigs apply
        exit 0
        ;;
  --applyFix|--ApplyFix)
      applyFix $3
      exit 0
      ;;
  --restartRoksNodes|--RestartRoksNodes)
      restartRoksNodes
      exit 0
      ;;
  --buildPortworxStorageClasses|--BuildPortworxStorageClasses)
      prepareCP4DInputFiles
      cp4dBuildPortworxStroageClasses apply
      exit 0
      ;;
  --RemovePortworxStorageClasses|--RemovePortworxStorageClasses)
      prepareCP4DInputFiles
      cp4dBuildPortworxStroageClasses delete
      exit 0
      ;;
  --help|--?|?|-?|help|-help|--Help|-Help)
       printHeaderMessage "Help Menu for build flags"
       echo "--Precheck                            This will just do a quick precheck to see if the environment is ready for a build"
       echo "--ProcessCP4DInstance                 This will create IBM CP4D Zen UI after all other CP4D settings are applied."
       echo "--ProcessCP4DMachineConfigs           This will update CP4D Machine Configs and wait until all nodes restart."
       echo "--Status                              This will display Cloud Pak for Data Platform Status"
       echo "--Console                             This will display Console Connection info"
       echo "--ApplyFix                            This will apply a given fix to your Daffy env, pass the fix number to command"
       echo "--RestartRoksNodes                    This will restart ROKS nodes"
       echo "--BuildPortworxStorageClasses         This will build Portworx storage classes"
       echo "--RemovePortworxStorageClasses        This will remove Portworx storage classes"
       echo ""
       exit 0
       ;;
   --*|-*)
       echo "${RED_TEXT}Unsupported flag in command line - ${2}. ${RESET_TEXT}"
       echo ""
       exit 9
       ;;
esac
precheckCP4D
updateDaffyStats
prepareCP4DInputFiles
updateIBMEntitlementInPullSecret apply
if [ "${CP4D_CLOUDCTL_CASE_BUILD_OUT}"  = "false" ]; then
    printHeaderMessage "Cloud Pak for Data"
    echo "Deploying Cloud Pak for Data version ${CP4D_VERSION} via Single Catalog (ibm-operator-catalog)"
    echo ""
    processCP4DNameSpaces apply
    processCP4DCatalogSource apply
    processCP4DOperators apply
    processCP4DMachineConfigs apply
    processCP4DTuneNodes apply
    processCP4DInstance apply
    displayCP4DAdminConsoleInfo
else
    printHeaderMessage "Cloud Pak for Data"
    echo "Deploying Cloud Pak for Data version ${CP4D_VERSION} via CloudCTL Case ${CP4D_CASE_PACKAGE_VERSION}"
    echo ""
    cloudCTLPreCaseInstallCP4D
    cloudCTLInstallCP4DCloudFountaionServicesCatalog
    cloudCTLInstallCP4DSchedulingServiceCatalog
    cloudCTLInstallDb2OperatorCatalog
    cloudCTLInstallCPDataCatalog
    processCP4DNameSpaces apply
    processCP4DOperators apply
    processCP4DMachineConfigs apply
    processCP4DTuneNodes apply
    processCP4DInstance apply
    displayCP4DAdminConsoleInfo
fi
consoleFooter "${CP_FUNCTION_NAME}"
