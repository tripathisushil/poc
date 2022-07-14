#!/bin/bash
############################################################
#Author           : Kyle Dawson
#Author email     : Kyle.Dawson@us.ibm.com
#Original Date    : 2021-08-10
#Initial Version  : 0.6
############################################################
#Common Variables
######################
DIR="$( cd "$( dirname "$0" )" && pwd )"
RED_TEXT=`tput setaf 1`
GREEN_TEXT=`tput setaf 2`
BLUE_TEXT=`tput setaf 4`
RESET_TEXT=`tput sgr0`
PRODUCT_SHORT_NAME=ocp
PRODUCT_FUNCTION=rebuild

if [ $# -eq 0 ]
then
    ls  ${DIR}/../env/*env* |  sed 's/-env.sh//g' | grep -v "samples" | sed 's/.*\///g'
    read -p "${BLUE_TEXT}Which env file do you want to run with    :  ${RESET_TEXT}" ENVIRONMENT_FILE
    ${DIR}/rebuild.sh ${ENVIRONMENT_FILE}
    exit 0
else
  ENVIRONMENT_FILE=$1
fi
if [ ! -f ${DIR}/../env/${ENVIRONMENT_FILE}-env.sh ]
then
   echo "${RED_TEXT}${ENVIRONMENT_FILE} does NOT exists in ${DIR}/../env !${RESET_TEXT}"
   ${DIR}/rebuild.sh
    exit 0
fi
source ~/.profile 2> /dev/null
source ${DIR}/../env/${ENVIRONMENT_FILE}-env.sh
source ${DIR}/../env.sh
source ${DIR}/../functions.sh
source ${DATA_DIR}/${PROJECT_NAME}/util/providers/macos.sh
mkdir -p ${LOG_DIR}/${PRODUCT_SHORT_NAME}/

OS
if [ "${MAC}" == true ]; then
   macOCPCleanup
   macOCPBuild
   exit 99
fi

CLEANUP_LOG=${LOG_DIR}/${PRODUCT_SHORT_NAME}/$(date +"%F-%T")-cleanup.log
echo "Cleanup Log File - ${CLEANUP_LOG}"
${DIR}/cleanup.sh ${ENVIRONMENT_FILE} | tee ${CLEANUP_LOG}
status=`cat "${CLEANUP_LOG}" | grep -c FAILED`
## take some decision ##
if [ $status -eq 0 ];then
  echo "Cleanup was successful, moving on to build process."
  echo ""
  echo ""
else
  echo "${RED_TEXT}Cleanup failed, cannot contiue with build proces.${RESET_TEXT}"
  echo ""
  echo ""
  exit 9
fi
source ~/.profile 2> /dev/null
BUILD_LOG=${LOG_DIR}/${PRODUCT_SHORT_NAME}/$(date +"%F-%T")-build.log
echo "Build Log File - ${BUILD_LOG}"
${DIR}/build.sh ${ENVIRONMENT_FILE} | tee ${BUILD_LOG}
