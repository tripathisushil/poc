#!/bin/bash
############################################################
#Author           : Kyle Dawson
#Author email     : Kyle.Dawson@us.ibm.com
#Original Date    : 2022-01-25
#Initial Version  : v2022-02-15
############################################################
#Setup Variables
############################################################
DIR="$( cd "$( dirname "$0" )" && pwd )"
PRODUCT_SHORT_NAME=cp4ba
PRODUCT_FUNCTION=service
ENVIRONMENT_FILE=${1}
source ${DIR}/../env/${1}-env.sh &> /dev/null
source ${DIR}/env.sh
source ${DIR}/../env.sh
source ${DIR}/../functions.sh
source ${DIR}/functions.sh

#Source other functions
############################################################
source ${DATA_DIR}/${PROJECT_NAME}/util/ibmcloud.sh
source ${DATA_DIR}/${PROJECT_NAME}/util/providers/macos.sh
source ${DATA_DIR}/${PROJECT_NAME}/${PRODUCT_SHORT_NAME}/services/functions.sh
source ${DATA_DIR}/${PROJECT_NAME}/${PRODUCT_SHORT_NAME}/services/odm.sh
source ${DATA_DIR}/${PROJECT_NAME}/${PRODUCT_SHORT_NAME}/services/filenet.sh
source ${DATA_DIR}/${PROJECT_NAME}/${PRODUCT_SHORT_NAME}/services/bai.sh
source ${DATA_DIR}/${PROJECT_NAME}/${PRODUCT_SHORT_NAME}/services/baw.sh
source ${DATA_DIR}/${PROJECT_NAME}/${PRODUCT_SHORT_NAME}/services/ops.sh
source ${DATA_DIR}/${PROJECT_NAME}/${PRODUCT_SHORT_NAME}/services/adp.sh
mkdir -p ${TEMP_DIR}/${PRODUCT_SHORT_NAME}
mkdir -p ${LOG_DIR}/${PRODUCT_SHORT_NAME}
CP_FUNCTION_NAME="CP4BA Service"
#############################################################
OS
if [ "${MAC}" == "true" ]; then
   macCheckOCP
   macPrepareHost
   macSetupContainer
   macGetDaffy
   macCopyEnvFile
   case ${2} in
     --*)
        echo "Running container with podman exec -it daffy /bin/bash -c /data/daffy/cp4ba/service.sh ${ENVIRONMENT_FILE} ${2}"
        echo "${RESET_TEXT}"
        echo ""
        podman exec -it daffy /bin/bash -c "/data/daffy/cp4ba/service.sh ${ENVIRONMENT_FILE} ${2}"
        exit 99 # Exiting script due to work being done in container
        ;;
   esac
   echo "Running container with podman exec -it daffy /bin/bash -c /data/daffy/cp4ba/service.sh ${ENVIRONMENT_FILE}"
   podman exec -it daffy /bin/bash -c "/data/daffy/cp4ba/service.sh ${ENVIRONMENT_FILE}"
   podman cp daffy:/data/daffy/tmp/${CLUSTER_NAME}/${PRODUCT_SHORT_NAME} ${TEMP_DIR}
   podman cp daffy:/data/daffy/log/${CLUSTER_NAME}/${PRODUCT_SHORT_NAME} ${LOG_DIR}
   exit 99
fi
logIntoCluster
case ${2} in
  --precheck|--Precheck)
        precheckCP4BAService
        consoleFooter "${CP_FUNCTION_NAME}"
        exit 0
        ;;
  --Status|--status|--AllStatus)
        #validateOCPAccess
        echo "Not implemented yet!!!!!!!!!!!!!!!!!"
        echo ""
        consoleFooter "${CP_FUNCTION_NAME}"
        exit 0
        ;;
  --Console|--console)
        #validateOCPAccess
        echo "Not implemented yet!!!!!!!!!!!!!!!!!"
        echo ""
        consoleFooter "${CP_FUNCTION_NAME}"
        exit 0
        ;;
  --StarterStatus)
        #validateOCPAccess
        CP4BA_DEPLOYMENT_SERVICE=${CP4BA_DEPLOYMENT_STARTER_SERVICE}
        CP4BA_AUTO_NAMESPACE=${CP4BA_AUTO_NAMESPACE_STARTER}
        cp4baServiceStatus
        consoleFooter "${CP_FUNCTION_NAME}"
        exit 0
        ;;
  --StarterConsole)
        #validateOCPAccess
        CP4BA_DEPLOYMENT_SERVICE=${CP4BA_DEPLOYMENT_STARTER_SERVICE}
        CP4BA_AUTO_NAMESPACE=${CP4BA_AUTO_NAMESPACE_STARTER}
        cp4baServiceConsole
        consoleFooter "${CP_FUNCTION_NAME}"
        exit 0
        ;;
  --listSamples|--ListSamples|--samples)
        cp4baListSamples
        consoleFooter "${CP_FUNCTION_NAME}"
        exit 0
        ;;
   --help|--?|?|-?|help|-help|--Help|-Help)
       printHeaderMessage "Help Menu for service flags"
       echo "--Precheck                           This will precheck Services"
       echo "--StarterStatus                      This will give status all services for Starter"
       echo "--StarterConsole                     This will give console all services for Starter"
       echo "--ListSamples                        This will list avaiable samples"
       echo ""
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
mkdir -p ${LOG_DIR}/${PRODUCT_SHORT_NAME}
mkdir -p ${TEMP_DIR}/${PRODUCT_SHORT_NAME}
precheckCP4BAService
updateDaffyStats
prepareCP4BAServiceInputFiles
cp4baOPSInstall

#Run CP4BA service fuctions
############################################################
case ${CP4BA_DEPLOYMENT_STARTER_SERVICE} in
  samples|workflow|content|content-decisions|decisions)
        CP4BA_DEPLOYMENT_SERVICE=${CP4BA_DEPLOYMENT_STARTER_SERVICE}
        DEPLOYMENT_TYPE=starter
        CP4BA_AUTO_NAMESPACE=${CP4BA_AUTO_NAMESPACE_STARTER}
        cp4baDeployService
        ;;
    *)
        printHeaderMessage "Deploy Starter Service - ${CP4BA_DEPLOYMENT_STARTER_SERVICE}"
        echo "${RED_TEXT}FAILED ${RESET_TEXT} Service not supported yet"
        ;;
esac
#if [ ! -z "${CP4BA_DEPLOYMENT_PRODUCTION_SERVICE_1}"  ]; then
#  printHeaderMessage "Deploy Production Service - ${CP4BA_DEPLOYMENT_PRODUCTION_SERVICE_1}"
#  CP4BA_DEPLOYMENT_SERVICE=${CP4BA_DEPLOYMENT_PRODUCTION_SERVICE_1}
#  DEPLOYMENT_TYPE=production
#  CP4BA_AUTO_NAMESPACE=${CP4BA_AUTO_NAMESPACE_PRODUCTION_1}
#  cp4baDeployService
#fi

consoleFooter "${CP_FUNCTION_NAME}"
