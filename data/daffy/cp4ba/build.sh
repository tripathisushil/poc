#!/bin/bash
############################################################
#Author           : Kyle Dawson
#Author email     : Kyle.Dawson@us.ibm.com
#Original Date    : 2022-01-11
#Initial Version  : v2022-02-15
############################################################
#Setup Variables
############################################################
DIR="$( cd "$( dirname "$0" )" && pwd )"
PRODUCT_SHORT_NAME=cp4ba
PRODUCT_FUNCTION=build
ENVIRONMENT_FILE=${1}
source ${DIR}/../env/${1}-env.sh &> /dev/null
source ${DIR}/../env.sh
source ${DIR}/env.sh
source ${DIR}/functions.sh
source ${DIR}/../functions.sh

#Source other functions
#############################################
source ${DATA_DIR}/${PROJECT_NAME}/util/ibmcloud.sh
source ${DATA_DIR}/${PROJECT_NAME}/util/providers/macos.sh

#Other Prep tasks
#############################################
CP_FUNCTION_NAME="CP4BA Build"
OS
if [ "${MAC}" == "true" ]; then
   macCheckOCP
   macPrepareHost
   macSetupContainer
   macGetDaffy
   macCopyEnvFile
   case ${2} in
     --*)
        echo "Running container with podman exec -it daffy /bin/bash -c /data/daffy/cp4ba/build.sh ${ENVIRONMENT_FILE} ${2}"
        echo "${RESET_TEXT}"
        echo ""
        podman exec -it daffy /bin/bash -c "/data/daffy/cp4ba/build.sh ${ENVIRONMENT_FILE} ${2}"
        exit 99 # Exiting script due to work being done in container
        ;;
   esac
   echo "Running container with podman exec -it daffy /bin/bash -c /data/daffy/cp4ba/build.sh ${ENVIRONMENT_FILE}"
   podman exec -it daffy /bin/bash -c "/data/daffy/cp4ba/build.sh ${ENVIRONMENT_FILE}"
   podman cp daffy:/data/daffy/tmp/${CLUSTER_NAME}/${PRODUCT_SHORT_NAME} ${TEMP_DIR}
   podman cp daffy:/data/daffy/log/${CLUSTER_NAME}/${PRODUCT_SHORT_NAME} ${LOG_DIR}
   exit 99
fi
mkdir -p ${LOG_DIR}/${PRODUCT_SHORT_NAME}
mkdir -p ${TEMP_DIR}/${PRODUCT_SHORT_NAME}
logIntoCluster
case ${2} in

  --precheck|--Precheck)
        precheckCP4BA
        consoleFooter "${CP_FUNCTION_NAME}"
        exit 0
        ;;
  --copyJDBCFiles|--CopyJDBCFiles)
        cp4baCopyJDBCFilesToPod
        consoleFooter "${CP_FUNCTION_NAME}"
        exit 0
        ;;
  --console|--Console)
        cp4baConsole
        exit 0
        ;;
  --listSamples|--ListSamples|--samples)
        cp4baListSamples
        consoleFooter "${CP_FUNCTION_NAME}"
        exit 0
        ;;
  --help|--?|?|-?|help|-help|--Help|-Help)
       printHeaderMessage "Help Menu for build flags"
       echo "--Precheck                          This will just do a quick precheck to see if the environment is ready for a build"
       echo "--CopyJDBCFiles                     This will copy JDBC jar files to ibm-cp4a-operator Pod"
       echo "--Console                           This will show Cloud Pak Console info"
       echo "--ListSamples                       This will list avaiable samples"
       consoleFooter "${CP_FUNCTION_NAME}"
       exit 0
       ;;
   --*|-*)
       echo "${RED_TEXT}Unsupported flag in command line - ${2}. ${RESET_TEXT}"
       echo ""
       consoleFooter "${CP_FUNCTION_NAME}"
       exit 9
       ;;
esac
precheckCP4BA
updateDaffyStats
prepareCP4BAInputFiles
updateIBMEntitlementInPullSecret apply

printHeaderMessage "Prepare for Starter Service - ${CP4BA_DEPLOYMENT_STARTER_SERVICE}"
case ${CP4BA_DEPLOYMENT_STARTER_SERVICE} in
    samples|workflow|content|decisions|content-decisions)
    CP4BA_AUTO_NAMESPACE=${CP4BA_AUTO_NAMESPACE_STARTER}
    CP4BA_AUTO_DEPLOYMENT_TYPE=starter
    cp4baClusterAdminSetup
    cp4baCopyJDBCFilesToPod
    ;;
  capture|capture-content-decisions-workflow|content-decisions-workflow|content-workflow | decision-workflow)
    echo "${RED_TEXT}FAILED ${RESET_TEXT} Service not supported yet"
    ;;
esac
#if [ ! -z "${CP4BA_DEPLOYMENT_PRODUCTION_SERVICE_1}"  ]; then
#  printHeaderMessage "Prepare for Production Service - ${CP4BA_DEPLOYMENT_PRODUCTION_SERVICE_1}"
#  CP4BA_AUTO_NAMESPACE=${CP4BA_AUTO_NAMESPACE_PRODUCTION_1}
#  CP4BA_AUTO_DEPLOYMENT_TYPE=production
#  cp4baClusterAdminSetup
#  cp4baCopyJDBCFilesToPod
#fi

consoleFooter "${CP_FUNCTION_NAME}"
