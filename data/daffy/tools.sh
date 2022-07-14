#!/bin/bash
############################################################
#Author           : Kyle Dawson
#Author email     : Kyle.Dawson@us.ibm.com
#Original Date    : 2022-05-16
#Initial Version  : v2022-05-23
############################################################
#Setup Variables
############################################################
DIR="$( cd "$( dirname "$0" )" && pwd )"
PRODUCT_SHORT_NAME=tools
PRODUCT_FUNCTION=install
SHOULD_EXIT=0
source ${DIR}/env.sh
source ${DIR}/functions.sh "skip"


start=$SECONDS
#Source other functions
#############################################
source ${DATA_DIR}/${PROJECT_NAME}/util/functions.sh
source ${DATA_DIR}/${PROJECT_NAME}/ocp/openshift.sh
source ${DATA_DIR}/${PROJECT_NAME}/util/cloudctl.sh
source ${DATA_DIR}/${PROJECT_NAME}/util/providers/vmware.sh
source ${DATA_DIR}/${PROJECT_NAME}/util/providers/aws.sh
source ${DATA_DIR}/${PROJECT_NAME}/util/providers/azure.sh
source ${DATA_DIR}/${PROJECT_NAME}/util/providers/gcp.sh
source ${DATA_DIR}/${PROJECT_NAME}/util/ibmcloud.sh
source ${DATA_DIR}/${PROJECT_NAME}/util/providers/macos.sh
source ${DATA_DIR}/${PROJECT_NAME}/cp4d/functions.sh

mkdir -p ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/
mkdir -p ${LOG_DIR}/${PRODUCT_SHORT_NAME}/
chmod -fR 777 ${DATA_DIR}/${PROJECT_NAME}/

OCP_FUNCTION_NAME="Tools Install Process"
case ${1} in
    --prepareHost|--preparehost|prepareHost|preparehost)
        prepareHost
        ;;
    --mustGather|--mustgather|mustGather|mustgather)
        mustGather
        ;;
    --installOC|--installoc|installOC|installoc)
        printHeaderMessage "Installing oc command"
        echo -n "${BLUE_TEXT}What version of oc do you want to install(4.8.35, 4.8.36, 4.9.12, etc): ${RESET_TEXT}"
        read OCP_RELEASE
        validateOpenShiftVersion
        shouldExit
        getOpenShiftTools
        ;;
    --installAWS|--installaws|installAWS|installaws)
        printHeaderMessage "Installing aws command"
        awsInstallCommandline
        ;;
    --installAzure|--installazure|installAzure|installazure)
        printHeaderMessage "Installing az command"
        azInstallCommandline
        ;;
    --installGCloud|--installgcloud|installgcloud|installgcloud|installgcp)
        printHeaderMessage "Installing gcloud command"
        gcpInstallGCloud
        ;;
    --installGOVC|--installgovc|installGOVC|installgovc)
        printHeaderMessage "Installing govc command"
        installGOVC
        ;;
    --installCloudCTL|--installcloudctl|installCloudCTL|installcloudctl)
        printHeaderMessage "Installing cloudctl command"
        echo -n "${BLUE_TEXT}What version of cp4d is this for? (4.0.2, 4.0.7, 4.0.8, etc): ${RESET_TEXT}"
        read CP4D_VERSION
        validateCP4DVersion
        shouldExit
        cloudCTLInstall
        ;;
   *|--help|--?|?|-?|help|-help|--Help|-Help)
        printHeaderMessage "Help Menu for install flags"
        echo "--prepareHost                          This will run the prepareHost for daffy"
        echo "--mustGather                           This will run the mustGather for daffy"
        echo "--installOC                            This will install the oc command line tool"
        echo "--installAWS                           This will install the aws commandline tool"
        echo "--installAzure                         This will install the azure commandline tool"
        echo "--installGCloud                        This will install the gcloud commandline tool"
        echo "--installGOVC                          This will install the govc commandline tool(VMware)"
        echo "--installCloudCTL                      This will install the cloudctl for CP4D"
        ;;
esac
consoleFooter "${OCP_FUNCTION_NAME}"
