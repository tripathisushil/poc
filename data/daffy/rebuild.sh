#!/bin/bash
############################################################
#Author           : Kyle Dawson
#Author email     : Kyle.Dawson@us.ibm.com
#Original Date    : 2022-01-01
#Initial Version  : v2022-01-18
############################################################
#Common Variables
######################
DIR="$( cd "$( dirname "$0" )" && pwd )"
source ~/.profile 2> /dev/null
source ${DIR}/env/${1}-env.sh &> /dev/null
source ${DIR}/env.sh
PRODUCT_SHORT_NAME=ocp
PRODUCT_FUNCTION=master-rebuild
ENVIRONMENT_FILE=$1
CLOUD_PAK=$2
case ${1} in
  --*|help|console)
        echo "${RED_TEXT}###########################################################################################"
        echo "There are no flags at this level, only sub scripts, not the all in one scripts."
        echo "###########################################################################################${RESET_TEXT}"
        exit 0
        ;;
esac
case ${2} in
  --*|help|console)
        echo "${RED_TEXT}###########################################################################################"
        echo "There are no flags at this level, only sub scripts, not the all in one scripts."
        echo "###########################################################################################${RESET_TEXT}"
        exit 0
        ;;
esac
case ${3} in
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
    ${DIR}/rebuild.sh ${ENVIRONMENT_FILE}
    exit 0
fi
if [ ! -f ${DIR}/env/${ENVIRONMENT_FILE}-env.sh ]; then
   echo "${RED_TEXT}${ENVIRONMENT_FILE} does NOT exists in ${DIR}/env !${RESET_TEXT}"
   ls  ${DIR}/env/*env* |  sed 's/-env.sh//g' | grep -v "samples" | sed 's/.*\///g'
   read -p "${BLUE_TEXT}Which env file do you want to run with    :  ${RESET_TEXT}" ENVIRONMENT_FILE
   ${DIR}/rebuild.sh ${ENVIRONMENT_FILE} ${CLOUD_PAK}
   exit 0
fi

if [ -z ${CLOUD_PAK} ]; then
    ls  ${DIR}/ | grep "cp4\|wsa" | sed 's/.*\///g'
    read -p "${BLUE_TEXT}Which cloud pak do you want to run with    :  ${RESET_TEXT}" CLOUD_PAK
fi
if [ "${CLOUD_PAK}" != "none" ]; then
  if [ ! -f ${DIR}/${CLOUD_PAK}/build.sh ]; then
     echo "${RED_TEXT}Cloud Pak name ${CLOUD_PAK} does NOT exists.${RESET_TEXT}"
     ls  ${DIR}/ | grep "cp4\|wsa" | sed 's/.*\///g'
     read -p "${BLUE_TEXT}Which cloud pak do you want to run with    :  ${RESET_TEXT}" CLOUD_PAK
     ${DIR}/rebuild.sh ${ENVIRONMENT_FILE} ${CLOUD_PAK}
     exit 0
  fi
fi

source ${DIR}/env/${ENVIRONMENT_FILE}-env.sh
source ${DIR}/env.sh
source ${DIR}/functions.sh
getIBMEntitlementKey "suppress"

mkdir -p ${LOG_DIR}/${PRODUCT_SHORT_NAME}/


CLEANUP_LOG=${LOG_DIR}/${PRODUCT_SHORT_NAME}/$(date +"%F-%T")-cleanup.log
echo "Cleanup Log File - ${CLEANUP_LOG}"
${DIR}/${PRODUCT_SHORT_NAME}/cleanup.sh ${ENVIRONMENT_FILE} | tee ${CLEANUP_LOG}
RET_VALUE=`cat ${CLEANUP_LOG} | grep -c "Exiting Script!"`
if [ ${RET_VALUE} -ne 0 ]; then
    exit ${RET_VALUE}
fi

${DIR}/build.sh ${ENVIRONMENT_FILE} ${CLOUD_PAK}
echo "##########################################################################################################"
SCRIPT_END_TIME=`date`
echo "End Time: ${SCRIPT_END_TIME}"
if (( $SECONDS > 3600 )) ; then
    let "hours=SECONDS/3600"
    let "minutes=(SECONDS%3600)/60"
    let "seconds=(SECONDS%3600)%60"
    echo "OpenShift & Cloud Pak(${CLOUD_PAK}) Full Rebuild Completed in $hours hour(s), $minutes minute(s) and $seconds second(s)"
elif (( $SECONDS > 60 )) ; then
    let "minutes=(SECONDS%3600)/60"
    let "seconds=(SECONDS%3600)%60"
    echo "OpenShift & Cloud Pak(${CLOUD_PAK}) Full Rebuild Completed in $minutes minute(s) and $seconds second(s)"
else
    echo "OpenShift & Cloud Pak(${CLOUD_PAK}) Full Rebuild Completed in $SECONDS seconds"
fi
echo "##########################################################################################################"
echo ""
echo ""
