#!/bin/bash
############################################################
#Author           : Jeff Imholz
#Author email     : jimholz@us.ibm.com
#Original Date    : 2022-03-04
#Initial Version  : v2022-03-04
############################################################
#Setup Variables
############################################################
DIR="$( cd "$( dirname "$0" )" && pwd )"
PRODUCT_SHORT_NAME=cp4i
PRODUCT_FUNCTION=service
ENVIRONMENT_FILE=${1}
source ${DIR}/../env/${1}-env.sh &> /dev/null
source ${DIR}/env.sh
source ${DIR}/../env.sh
if [ "${SHOULD_EXIT}" == 1 ] ;then
    echo ""
    echo "${X_MARK}  ${RED_TEXT} *** PRE-CHECK FAILED ********  Exiting Script!!!!!!!${RESET_TEXT}"
    echo ""
    exit 1
fi
source ${DIR}/../functions.sh
source ${DIR}/functions.sh

#Source other functions
############################################################
source ${DATA_DIR}/${PROJECT_NAME}/util/ibmcloud.sh
source ${DATA_DIR}/${PROJECT_NAME}/util/providers/macos.sh
source ${DATA_DIR}/${PROJECT_NAME}/${PRODUCT_SHORT_NAME}/services/acedash.sh
source ${DATA_DIR}/${PROJECT_NAME}/${PRODUCT_SHORT_NAME}/services/acedesign.sh
source ${DATA_DIR}/${PROJECT_NAME}/${PRODUCT_SHORT_NAME}/services/repo.sh
source ${DATA_DIR}/${PROJECT_NAME}/${PRODUCT_SHORT_NAME}/services/tracing.sh
source ${DATA_DIR}/${PROJECT_NAME}/${PRODUCT_SHORT_NAME}/services/mq-single.sh
source ${DATA_DIR}/${PROJECT_NAME}/${PRODUCT_SHORT_NAME}/services/apic.sh
source ${DATA_DIR}/${PROJECT_NAME}/${PRODUCT_SHORT_NAME}/services/mq-ha.sh
source ${DATA_DIR}/${PROJECT_NAME}/${PRODUCT_SHORT_NAME}/services/eventstreams.sh
#############################################################
SERVICES_MODE="apply"
CP_FUNCTION_NAME="CP4I Service"
OS
if [ "${MAC}" == "true" ]; then
   macCheckOCP
   macPrepareHost
   macSetupContainer
   macGetDaffy
   macCopyEnvFile
   case ${2} in
     --*)
        echo "Running container with podman exec -it daffy /bin/bash -c /data/daffy/cp4i/service.sh ${ENVIRONMENT_FILE} ${2}"
        echo "${RESET_TEXT}"
        echo ""
        podman exec -it daffy /bin/bash -c "/data/daffy/cp4i/service.sh ${ENVIRONMENT_FILE} ${2}"
        exit 99 # Exiting script due to work being done in container
        ;;
   esac
   echo "Running container with podman exec -it daffy /bin/bash -c /data/daffy/cp4i/service.sh ${ENVIRONMENT_FILE}"
   podman exec -it daffy /bin/bash -c "/data/daffy/cp4i/service.sh ${ENVIRONMENT_FILE}"
   podman cp daffy:/data/daffy/tmp/${CLUSTER_NAME}/${PRODUCT_SHORT_NAME} ${TEMP_DIR}
   podman cp daffy:/data/daffy/log/${CLUSTER_NAME}/${PRODUCT_SHORT_NAME} ${LOG_DIR}
   exit 99
fi
logIntoCluster
case ${2} in
  --precheck|--Precheck)
        precheckCP4I
        exit 0
        ;;
  --cleanup|--Cleanup)
        printHeaderMessage "Services Cleanup"
        echo ""
        SERVCIES_MODE="delete"
        ;;
  --operations|--Operations)
        printHeaderMessage "Operations Mode"
        echo ""
        SERVCIES_MODE="operations"
        OPERATIONS_FUNCTION=${3}
        ;;
  --AceDashStatus)
        cp4iServiceAceDashStatus
        exit 0
        ;;
  --AceDesignStatus)
        cp4iServiceAceDesignStatus
        exit 0
        ;;
  --AssetRepoStatus)
        cp4iServiceAssetRepoStatus
        exit 0
        ;;
  --TracingStatus)
        cp4iServiceTracingStatus
        exit 0
        ;;
  --MQSingleStatus)
        cp4iServiceMQSingleStatus
        exit 0
        ;;
  --APICStatus)
        cp4iServiceAPICStatus
        exit 0
        ;;
  --MQHAStatus)
        cp4iServiceMQHAStatus
        exit 0
        ;;
  --EventStreamsStatus)
        cp4iServiceEventStreamsStatus
        exit 0
        ;;
  --AllStatus|--status|--Status)
        cp4iServiceAllStatus
        exit 0
        ;;
   --help|--?|?|-?|help|-help|--Help|-Help)
       printHeaderMessage "Help Menu for service flags"
       echo "--Cleanup                             This will remove any services that you have enabled via environment file"
       echo "--AceDashStatus                       This will Check the status of the Ace Dashboard Service"
       echo "--AceDesignStatus                     This will Check the status of the Ace Designer Service"
       echo "--AssetRepoStatus                     This will Check the status of the Asset Repository Service"
       echo "--TracingStatus                       This will Check the status of the Tracing Service"
       echo "--MQSingleStatus                      This will Check the status of MQ Single Instance Service"
       echo "--APICStatus                          This will Check the status of API Connect Service"
       echo "--MQHAStatus                          This will Check the status of MQ Prod HA Instance Service"
       echo "--EventStreamsStatus                  This will Check the status of Event Streams Service"
       echo "--AllStatus                           This will Check the status of all Services"
       echo "--Operations                          This will go into operations mode for the services"
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
validateCP4IServiceVersion
validateTracingService

#Run CP4I service fuctions
############################################################
cp4iServiceAceDash ${SERVICES_MODE} ${OPERATIONS_FUNCTION}
cp4iServiceAceDesign ${SERVICES_MODE} ${OPERATIONS_FUNCTION}
cp4iServiceAssetRepo ${SERVICES_MODE} ${OPERATIONS_FUNCTION}
cp4iServiceMQSingle ${SERVICES_MODE} ${OPERATIONS_FUNCTION}
cp4iServiceAPIC ${SERVICES_MODE} ${OPERATIONS_FUNCTION}
cp4iServiceMQHA ${SERVICES_MODE} ${OPERATIONS_FUNCTION}
cp4iServiceEventStreams ${SERVICES_MODE} ${OPERATIONS_FUNCTION}
consoleFooter "${CP_FUNCTION_NAME}"
