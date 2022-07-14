#!/bin/bash
############################################################
#Author           : Kyle Dawson
#Author email     : Kyle.Dawson@us.ibm.com
#Original Date    : 2020-10-12
#Initial Version  : v2021-12-01
############################################################
#Setup Variables
############################################################
DIR="$( cd "$( dirname "$0" )" && pwd )"
PRODUCT_SHORT_NAME=cp4d
PRODUCT_FUNCTION=service
ENVIRONMENT_FILE=${1}
source ${DIR}/../env/${1}-env.sh &> /dev/null
source ${DIR}/env.sh
source ${DIR}/../env.sh
source ${DIR}/../functions.sh
source ${DIR}/functions.sh

#Source other functions
############################################################
source ${DATA_DIR}/${PROJECT_NAME}/util/cloudctl.sh
source ${DATA_DIR}/${PROJECT_NAME}/util/ibmcloud.sh
source ${DATA_DIR}/${PROJECT_NAME}/util/providers/macos.sh
source ${DATA_DIR}/${PROJECT_NAME}/${PRODUCT_SHORT_NAME}/services/wks.sh
source ${DATA_DIR}/${PROJECT_NAME}/${PRODUCT_SHORT_NAME}/services/wkc.sh
source ${DATA_DIR}/${PROJECT_NAME}/${PRODUCT_SHORT_NAME}/services/dv.sh
source ${DATA_DIR}/${PROJECT_NAME}/${PRODUCT_SHORT_NAME}/services/ws.sh
source ${DATA_DIR}/${PROJECT_NAME}/${PRODUCT_SHORT_NAME}/services/spss.sh
source ${DATA_DIR}/${PROJECT_NAME}/${PRODUCT_SHORT_NAME}/services/wml.sh
source ${DATA_DIR}/${PROJECT_NAME}/${PRODUCT_SHORT_NAME}/services/datastage.sh
source ${DATA_DIR}/${PROJECT_NAME}/${PRODUCT_SHORT_NAME}/services/dods.sh
source ${DATA_DIR}/${PROJECT_NAME}/${PRODUCT_SHORT_NAME}/services/dmc.sh
source ${DATA_DIR}/${PROJECT_NAME}/${PRODUCT_SHORT_NAME}/services/cognosdashboards.sh

#############################################################
SERVCIES_MODE="apply"
CP_FUNCTION_NAME="CP4D Service"
OS
if [ "${MAC}" == "true" ]; then
   macCheckOCP
   macPrepareHost
   macSetupContainer
   macGetDaffy
   macCopyEnvFile
   case ${2} in
     --*)
        echo "Running container with podman exec -it daffy /bin/bash -c /data/daffy/cp4d/service.sh ${ENVIRONMENT_FILE} ${2}"
        echo "${RESET_TEXT}"
        echo ""
        podman exec -it daffy /bin/bash -c "/data/daffy/cp4d/service.sh ${ENVIRONMENT_FILE} ${2}"
        exit 99 # Exiting script due to work being done in container
        ;;
   esac
   echo "Running container with podman exec -it daffy /bin/bash -c /data/daffy/cp4d/service.sh ${ENVIRONMENT_FILE}"
   podman exec -it daffy /bin/bash -c "/data/daffy/cp4d/service.sh ${ENVIRONMENT_FILE}"
   podman cp daffy:/data/daffy/tmp/${CLUSTER_NAME}/${PRODUCT_SHORT_NAME} ${TEMP_DIR}
   podman cp daffy:/data/daffy/log/${CLUSTER_NAME}/${PRODUCT_SHORT_NAME} ${LOG_DIR}
   exit 99
fi
cp4dNamespaces
logIntoCluster
case ${2} in
  --precheck|--Precheck)
        precheckCP4DService
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
  --WKCStatus)
        cp4dServiceWKCStatus
        exit 0
        ;;
  --WKSStatus)
        cp4dServiceWKSStatus
        exit 0
        ;;
  --DVStatus)
        cp4dServiceDVStatus
        exit 0
        ;;
  --WSStatus)
        cp4dServiceWSStatus
        exit 0
        ;;
  --SPSSStatus)
        cp4dServiceSPSSStatus
        exit 0
        ;;
  --DataStageStatus)
        cp4dServiceDataStageStatus
        exit 0
        ;;
  --DODSStatus)
        cp4dServiceDODSStatus
        exit 0
        ;;
  --CognosDashboardsStatus)
        cp4dServiceCognosDashboardsStatus
        exit 0
        ;;
  --DMCStatus)
        cp4dServiceDMCStatus
        exit 0
        ;;
  --WMLStatus)
        cp4dServiceWMLStatus
        exit 0
        ;;
  --AllStatus|--status|--Status)
        cp4dServiceAllStatus
        exit 0
        ;;
   --help|--?|?|-?|help|-help|--Help|-Help)
       printHeaderMessage "Help Menu for service flags"
       echo "--Cleanup                             This will remove any services that you have enabled via environment file"
       echo "--WKCStatus                           This will Check the status of the Watson Knowledge Catalog Service"
       echo "--WKSStatus                           This will Check the status of the Watson Knowledge Studio Service"
       echo "--DVStatus                            This will Check the status of the Data Virtualization Service"
       echo "--WSStatus                            This will Check the status of the Watson Studio Service"
       echo "--SPSSStatus                          This will Check the status of the Statistical Package for the Social Sciences Service"
       echo "--WMLStatus                           This will Check the status of the Watson Mahine Learning Service"
       echo "--DataStageStatus                     This will Check the status of the DataStage Service"
       echo "--DODSStatus                          This will Check the status of the Data Optimization Service"
       echo "--DMCStatus                           This will Check the status of the DB2 Management Console Service"
       echo "--CognosDashboardsStatus              This will Check the status of the Cognos Dashboard Service"
       echo "--AllStatus                           This will Check the status of all Services"
       echo "--Operations                          This will go into operations mode for the services"
       echo "                                      wkc > clearIISStuckJob"
       echo ""
       exit 0
       ;;
   --*|-*)
       echo "${RED_TEXT}Unsupported flag in command line - ${2}. ${RESET_TEXT}"
       echo ""
       exit 9
       ;;
esac
precheckCP4DService
updateDaffyStats
prepareCP4DInputFiles

#Run CP4D service fuctions
############################################################
cp4dServiceWS ${SERVCIES_MODE} ${OPERATIONS_FUNCTION}
cp4dServiceWML ${SERVCIES_MODE} ${OPERATIONS_FUNCTION}
cp4dServiceDMC ${SERVCIES_MODE} ${OPERATIONS_FUNCTION}
cp4dServiceWKS ${SERVCIES_MODE} ${OPERATIONS_FUNCTION}
cp4dServiceWKC ${SERVCIES_MODE} ${OPERATIONS_FUNCTION}
cp4dServiceSPSS ${SERVCIES_MODE} ${OPERATIONS_FUNCTION}
cp4dServiceDataStage ${SERVCIES_MODE} ${OPERATIONS_FUNCTION}
cp4dServiceDODS ${SERVCIES_MODE} ${OPERATIONS_FUNCTION}
cp4dServiceCognosDashboards ${SERVCIES_MODE} ${OPERATIONS_FUNCTION}
cp4dServiceDV ${SERVCIES_MODE} ${OPERATIONS_FUNCTION}
consoleFooter "${CP_FUNCTION_NAME}"
