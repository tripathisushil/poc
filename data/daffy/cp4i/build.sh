#!/bin/bash
############################################################
#Author           : Dave Krier
#Author email     : dakrier@us.ibm.com
#Original Date    : 2021-25-10
#Initial Version  : v2021-12-01
############################################################
#Setup Variables
############################################################
DIR="$( cd "$( dirname "$0" )" && pwd )"
PRODUCT_SHORT_NAME=cp4i
PRODUCT_FUNCTION=build
ENVIRONMENT_FILE=${1}
source ${DIR}/../env/${1}-env.sh &> /dev/null
source ${DIR}/../env.sh
source ${DIR}/env.sh
source ${DIR}/../functions.sh
source ${DIR}/functions.sh
source ${DIR}/../fixpaks/env.sh

#Source other functions
#############################################
source ${DATA_DIR}/${PROJECT_NAME}/util/ibmcloud.sh
source ${DATA_DIR}/${PROJECT_NAME}/util/providers/rosa.sh
source ${DATA_DIR}/${PROJECT_NAME}/util/providers/macos.sh
CP_FUNCTION_NAME="CP4I Build"
OS
if [ "${MAC}" == "true" ]; then
   macCheckOCP
   macPrepareHost
   macSetupContainer
   macGetDaffy
   macCopyEnvFile
   case ${2} in
     --*)
        echo "Running container with podman exec -it daffy /bin/bash -c /data/daffy/cp4i/build.sh ${ENVIRONMENT_FILE} ${2}"
        echo "${RESET_TEXT}"
        echo ""
        podman exec -it daffy /bin/bash -c "/data/daffy/cp4i/build.sh ${ENVIRONMENT_FILE} ${2}"
        exit 99 # Exiting script due to work being done in container
        ;;
   esac
   echo "Running container with podman exec -it daffy /bin/bash -c /data/daffy/cp4i/build.sh ${ENVIRONMENT_FILE}"
   podman exec -it daffy /bin/bash -c "/data/daffy/cp4i/build.sh ${ENVIRONMENT_FILE}"
   podman cp daffy:/data/daffy/tmp/${CLUSTER_NAME}/${PRODUCT_SHORT_NAME} ${TEMP_DIR}
   podman cp daffy:/data/daffy/log/${CLUSTER_NAME}/${PRODUCT_SHORT_NAME} ${LOG_DIR}
   exit 99
fi
mkdir -p ${LOG_DIR}/${PRODUCT_SHORT_NAME}
mkdir -p ${TEMP_DIR}/${PRODUCT_SHORT_NAME}
logIntoCluster
case ${2} in
  --precheck|--Precheck)
        precheckCP4I
        exit 0
        ;;
  --console|--Console)
        displayPlatformNavigatorInfo
        exit 0
        ;;
  --status|--Status|--AllStatus)
        displayCP4IStatus
        exit 0
        ;;
  --applyFix|--ApplyFix)
      applyFix $3
      exit 0
      ;;
  --help|--?|?|-?|help|-help|--Help|-Help)
       printHeaderMessage "Help Menu for build flags"
       echo "--Precheck                            This will just do a quick precheck to see if the environment is ready for a build"
       echo "--Status                              This will display Cloud Pak for Integration Platform Status"
       echo "--Console                             This will display Platform Navigator Connection info"
       echo "--ApplyFix                            This will apply a given fix to your Daffy env, pass the fix number to command"
       echo ""
       exit 0
       ;;
   --*|-*)
       echo "${RED_TEXT}Unsupported flag in command line - ${2}. ${RESET_TEXT}"
       echo ""
       exit 9
       ;;
esac
precheckCP4I
updateDaffyStats
prepareCP4IInputFiles
printHeaderMessage "Deploying Cloud Pak for Integration version ${CP4I_VERSION}"
echo ""
updateIBMEntitlementInPullSecret apply
processCP4IYaml apply
waitForPlatformNavigatorOperatorToComplete
deployPlatformNavInstance apply
waitForPFNInstanceToComplete
displayPlatformNavigatorInfo apply
consoleFooter "${CP_FUNCTION_NAME}"
