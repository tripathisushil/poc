#!/bin/bash
############################################################
#Author           : Kyle Dawson
#Author email     : Kyle.Dawson@us.ibm.com
#Original Date    : 2022-03-24
#Initial Version  : v2022-03-31
############################################################
#Common Variables
######################
DIR="$( cd "$( dirname "$0" )" && pwd )"
source ~/.profile 2> /dev/null
source ${DIR}/env/${1}-env.sh &> /dev/null
source ${DIR}/env.sh
PRODUCT_SHORT_NAME=ocp
PRODUCT_FUNCTION=master-cleanup
ENVIRONMENT_FILE=$1
case ${2} in
  confirm)
       DAFFY_LIVE_ON_THE_EDGE="true"
       ;;
  --*|help|console)
        echo "${RED_TEXT}###########################################################################################"
        echo "There are no flags at this level, only sub scripts, not the all in one scripts."
        echo "###########################################################################################${RESET_TEXT}"
        exit 0
        ;;
esac
if [ $# -eq 0 ]; then
    ls  ${DIR}/env/*env* |  sed 's/-env.sh//g' | grep -v "samples" | sed 's/.*\///g'
    read -p "${BLUE_TEXT}Which env file do you want to run with    :  ${RESET_TEXT}" ENVIRONMENT_FILE
    ${DIR}/cleanup.sh ${ENVIRONMENT_FILE}
    exit 0
fi
if [ ! -f ${DIR}/env/${ENVIRONMENT_FILE}-env.sh ]; then
   echo "${RED_TEXT}${ENVIRONMENT_FILE} does NOT exists in ${DIR}/env !${RESET_TEXT}"
   ls  ${DIR}/env/*env* |  sed 's/-env.sh//g' | grep -v "samples" | sed 's/.*\///g'
   read -p "${BLUE_TEXT}Which env file do you want to run with    :  ${RESET_TEXT}" ENVIRONMENT_FILE
   ${DIR}/cleanup.sh ${ENVIRONMENT_FILE}
   exit 0
fi
source ${DIR}/env/${ENVIRONMENT_FILE}-env.sh
source ${DIR}/env.sh
source ${DIR}/functions.sh

mkdir -p ${LOG_DIR}/${PRODUCT_SHORT_NAME}/


CLEANUP_LOG=${LOG_DIR}/${PRODUCT_SHORT_NAME}/$(date +"%F-%T")-cleanup.log
echo "Cleanup Log File - ${CLEANUP_LOG}"
${DIR}/${PRODUCT_SHORT_NAME}/cleanup.sh ${ENVIRONMENT_FILE} | tee ${CLEANUP_LOG}
RET_VALUE=`cat ${CLEANUP_LOG} | grep -c "Exiting Script!"`
if [ ${RET_VALUE} -ne 0 ]; then
    exit ${RET_VALUE}
fi
