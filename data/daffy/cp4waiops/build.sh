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
PRODUCT_SHORT_NAME=cp4waiops
PRODUCT_FUNCTION=build
ENVIRONMENT_FILE=${1}
source ${DIR}/../env/${1}-env.sh &> /dev/null
source ${DIR}/../env.sh
source ${DIR}/../functions.sh
source ${DIR}/functions.sh
source ${DIR}/env.sh
source ${DIR}/../fixpaks/env.sh

#Source other functions
#############################################
source ${DATA_DIR}/${PROJECT_NAME}/util/ibmcloud.sh
source ${DATA_DIR}/${PROJECT_NAME}/util/providers/macos.sh

#Begin Prep
#############################################
mkdir -p ${LOG_DIR}/${PRODUCT_SHORT_NAME}
mkdir -p ${TEMP_DIR}/${PRODUCT_SHORT_NAME}
CP_FUNCTION_NAME="CP4WAIOPS Build"
if [ "${MAC}" == "true" ]; then
   macCheckOCP
   macPrepareHost
   macSetupContainer
   macGetDaffy
   macCopyEnvFile
   case ${2} in
     --*)
        echo "Running container with podman exec -it daffy /bin/bash -c /data/daffy/cp4waiops/build.sh ${ENVIRONMENT_FILE} ${2}"
        echo "${RESET_TEXT}"
        echo ""
        podman exec -it daffy /bin/bash -c "/data/daffy/cp4waiops/build.sh ${ENVIRONMENT_FILE} ${2}"
        exit 99 # Exiting script due to work being done in container
        ;;
   esac
   echo "Running container with podman exec -it daffy /bin/bash -c /data/daffy/cp4waiops/build.sh ${ENVIRONMENT_FILE}"
   podman exec -it daffy /bin/bash -c "/data/daffy/cp4waiops/build.sh ${ENVIRONMENT_FILE}"
   podman cp daffy:/data/daffy/tmp/${CLUSTER_NAME}/${PRODUCT_SHORT_NAME} ${TEMP_DIR}
   podman cp daffy:/data/daffy/log/${CLUSTER_NAME}/${PRODUCT_SHORT_NAME} ${LOG_DIR}
   exit 99
fi
logIntoCluster
case ${2} in
  --prereqcheck|--Prereqcheck)
        precheckCP4WAIOPS
        exit 0
        ;;
  --console|--Console)
        displayCP4WAIOPSAdminConsoleInfo
        exit 0
        ;;
  --status|--Status|--AllStatus)
        displayCP4WAIOPSStatus
        exit 0
        ;;
  --help|--?|?|-?|help|-help|--Help|-Help)
       printHeaderMessage "Help Menu for build flags"
       echo "--Prereqcheck                           This will check to ensure all prerequisites are met for the install"
       echo "--Console                               This will display Console Connection info"
       echo "--Status                                This will display Cloud Pak Status"
       echo ""
       exit 0
       ;;
   --*|-*)
       echo "${RED_TEXT}Unsupported flag in command line ${2}. ${RESET_TEXT}"
       echo ""
       exit 9
       ;;
esac
updateDaffyStats
precheckCP4WAIOPS
updateIBMEntitlementInPullSecret apply
installCP4WAIOPS
if [ "${CP4WAIOPS_DEPLOY_EMGR}" == "true" ] ;then
  installCP4WAIOPS_EventMgr
fi

displayCP4WAIOPSAdminConsoleInfo
consoleFooter "${CP_FUNCTION_NAME}"
