#!/bin/bash
############################################################
#Author           : Kyle Dawson
#Author email     : Kyle.Dawson@us.ibm.com
#Original Date    : 2022-01-21
#Initial Version  : v2022-02-15
############################################################
#Setup Variables
############################################################
DIR="$( cd "$( dirname "$0" )" && pwd )"
PRODUCT_SHORT_NAME=wsa
PRODUCT_FUNCTION=build
ENVIRONMENT_FILE=${1}
source ${DIR}/../env/${1}-env.sh &> /dev/null
source ${DIR}/../env.sh
source ${DIR}/env.sh
source ${DIR}/functions.sh

if [ $# -eq 0 ]; then
    ls  ${DIR}/../env/*env* |  sed 's/-env.sh//g' | grep -v "samples" | sed 's/.*\///g'
    read -p "${BLUE_TEXT}Which env file do you want to run with    :  ${RESET_TEXT}" ENVIRONMENT_FILE
    ${DIR}/build.sh ${ENVIRONMENT_FILE}
    exit 0
fi
if [ ! -f ${DIR}/../env/${1}-env.sh ]; then
   echo "${RED_TEXT}${1} does NOT exists in ${DIR}/../env !${RESET_TEXT}"
   ls  ${DIR}/../env/*env* |  sed 's/-env.sh//g' | grep -v "samples" | sed 's/.*\///g'
   read -p "${BLUE_TEXT}Which env file do you want to run with    :  ${RESET_TEXT}" ENVIRONMENT_FILE
   ${DIR}/build.sh ${ENVIRONMENT_FILE}
   exit 0
fi
source ${DIR}/../functions.sh

#Source other functions
#############################################
source ${DATA_DIR}/${PROJECT_NAME}/util/ibmcloud.sh
source ${DATA_DIR}/${PROJECT_NAME}/util/providers/macos.#!/bin/sh
OS
if [ "${MAC}" == "true" ]; then
   macCheckOCP
   macPrepareHost
   macSetupContainer
   macGetDaffy
   macCopyEnvFile
   case ${2} in
     --*)
        echo "Running container with podman exec -it daffy /bin/bash -c /data/daffy/wsa/build.sh ${ENVIRONMENT_FILE} ${2}"
        echo "${RESET_TEXT}"
        echo ""
        podman exec -it daffy /bin/bash -c "/data/daffy/wsa/build.sh ${ENVIRONMENT_FILE} ${2}"
        exit 99 # Exiting script due to work being done in container
        ;;
   esac
   echo "Running container with podman exec -it daffy /bin/bash -c /data/daffy/wsa/build.sh ${ENVIRONMENT_FILE}"
   podman exec -it daffy /bin/bash -c "/data/daffy/cp4i/build.sh ${ENVIRONMENT_FILE}"
   podman cp daffy:/data/daffy/tmp/${CLUSTER_NAME}/${PRODUCT_SHORT_NAME} ${TEMP_DIR}
   podman cp daffy:/data/daffy/log/${CLUSTER_NAME}/${PRODUCT_SHORT_NAME} ${LOG_DIR}
   exit 99
fi

mkdir -p ${LOG_DIR}/${PRODUCT_SHORT_NAME}
mkdir -p ${TEMP_DIR}/${PRODUCT_SHORT_NAME}
CP_FUNCTION_NAME="WebSphere Automation Build"
logIntoCluster
case ${2} in

  --precheck|--Precheck)
       precheckWSA
       consoleFooter "${CP_FUNCTION_NAME}"
       exit 0
       ;;
 --console|--Console)
      displayWSAAdminConsoleInfo
      consoleFooter "${CP_FUNCTION_NAME}"
      exit 0
      ;;
--status|--Status|--AllStatus)
     displayWSAStatus
     consoleFooter "${CP_FUNCTION_NAME}"
     exit 0
     ;;
  --help|--?|?|-?|help|-help)
       printHeaderMessage "Help Menu for build flags"
       echo "--Precheck                                         This will do a precheck of WebSphere Automation"
       echo "--Console                                          This will display WebSphere Automation Console Info "
       echo "--Status                                           This will display WebSphere Automation Status Info "
       exit 0
       ;;
   --*|-*)
       echo "${RED_TEXT}Unsupported flag in command line - ${2}. ${RESET_TEXT}"
       echo ""
       exit 9
       ;;
esac
precheckWSA
updateDaffyStats
prepareWSAInputFiles
updateIBMEntitlementInPullSecret apply
#setDefaultStorgeClass ${WSA_STORAGE_CLASS}
processWSANameSpaces apply
processWSACatalogSource apply
processWSAOperators apply
consoleFooter "${CP_FUNCTION_NAME}"
