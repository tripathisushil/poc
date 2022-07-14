#!/bin/bash
############################################################
#Author           : Kyle Dawson
#Author email     : Kyle.Dawson@us.ibm.com
#Original Date    : 2022-04-12
#Initial Version  : 1.0
############################################################
#Common Variables
######################
DIR="$( cd "$( dirname "$0" )" && pwd )"
source ${DIR}/../env.sh
PRODUCT_SHORT_NAME=db2
PRODUCT_FUNCTION=rebuild
FUNCTION_NAME="DB2 Rebuild"
case ${1} in
  --*|help|console)
        echo "${RED_TEXT}###########################################################################################"
        echo "There are no flags for rebuild, only sub scripts, not the all in one scripts."
        echo "###########################################################################################${RESET_TEXT}"
        exit 0
        ;;
esac
case ${2} in
  --*|help|console)
        echo "${RED_TEXT}###########################################################################################"
        echo "There are no flags for rebuild, only sub scripts, not the all in one scripts."
        echo "###########################################################################################${RESET_TEXT}"
        exit 0
        ;;
esac
case ${3} in
  --*|help|console)
        echo "${RED_TEXT}###########################################################################################"
        echo "There are no flags for rebuild, only sub scripts, not the all in one scripts."
        echo "###########################################################################################${RESET_TEXT}"
        exit 0
        ;;
esac
if [ $# -eq 0 ];then
    ls  ${DIR}/../env/*env* |  sed 's/-env.sh//g' | grep -v "samples" | sed 's/.*\///g'
    read -p "${BLUE_TEXT}Which env file do you want to run with    :  ${RESET_TEXT}" ENVIRONMENT_FILE
    ${DIR}/rebuild.sh ${ENVIRONMENT_FILE}
    exit 0
else
    ENVIRONMENT_FILE=$1
fi

source ~/.profile 2> /dev/null
mkdir -p ${LOG_DIR}/${PRODUCT_SHORT_NAME}/


CLEANUP_LOG=${LOG_DIR}/${PRODUCT_SHORT_NAME}/$(date +"%F-%T")-cleanup.log
echo "Cleanup Log File - ${CLEANUP_LOG}"
${DIR}/cleanup.sh ${ENVIRONMENT_FILE} | tee ${CLEANUP_LOG}
RET_VALUE=`cat ${CLEANUP_LOG} | grep -c "Exiting Script!"`
if [ ${RET_VALUE} -ne 0 ]; then
    exit ${RET_VALUE}
fi
source ~/.profile 2> /dev/null
BUILD_LOG=${LOG_DIR}/${PRODUCT_SHORT_NAME}/$(date +"%F-%T")-build.log
echo "Build Log File - ${BUILD_LOG}"
${DIR}/build.sh ${ENVIRONMENT_FILE} | tee ${BUILD_LOG}
echo "##########################################################################################################"
SCRIPT_END_TIME=`date`
echo "End Time: ${SCRIPT_END_TIME}"
if (( $SECONDS > 3600 )) ; then
    let "hours=SECONDS/3600"
    let "minutes=(SECONDS%3600)/60"
    let "seconds=(SECONDS%3600)%60"
    echo "${PRODUCT_SHORT_NAME} Full Rebuild Completed in $hours hour(s), $minutes minute(s) and $seconds second(s)"
elif (( $SECONDS > 60 )) ; then
    let "minutes=(SECONDS%3600)/60"
    let "seconds=(SECONDS%3600)%60"
    echo "${PRODUCT_SHORT_NAME}  Full Rebuild Completed in $minutes minute(s) and $seconds second(s)"
else
    echo "${PRODUCT_SHORT_NAME}  Full Rebuild Completed in $SECONDS seconds"
fi
echo "##########################################################################################################"
echo ""
echo ""
