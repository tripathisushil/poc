#!/bin/bash
############################################################
#Author           : Kyle Dawson
#Author email     : Kyle.Dawson@us.ibm.com
#Original Date    : 2020-11-17
#Initial Version  : v2021-12-01
############################################################
#Setup Variables
############################################################
DIR="$( cd "$( dirname "$0" )" && pwd )"
PRODUCT_SHORT_NAME=ldap
PRODUCT_FUNCTION=cleanup
source ${DIR}/../env/${1}-env.sh &> /dev/null
source ${DIR}/../env.sh
source ${DIR}/env.sh
case ${2} in
  confirm)
       DAFFY_LIVE_ON_THE_EDGE="true"
       ;;
esac
if [ "${DAFFY_LIVE_ON_THE_EDGE}" != "true" ] ;then
    read -p "${RED_TEXT}Are you sure you want to destroy the ENTIRE IDS Instance ?( Enter Yes to confirm)    :  ${RESET_TEXT}" CONFIRM_DESTROY
    if [ ${CONFIRM_DESTROY} != "Yes" ] ;then
      echo "Will NOT destroy IDS Instance, Exiting Script!!!!!!!!!!!!!!!!!!!"
      exit 1
    fi
fi
if [ $# -eq 0 ]; then
    ls  ${DIR}/../env/*env* |  sed 's/-env.sh//g' | grep -v "samples" | sed 's/.*\///g'
    read -p "${BLUE_TEXT}Which env file do you want to run with    :  ${RESET_TEXT}" ENVIRONMENT_FILE
    ${DIR}/cleanup.sh ${ENVIRONMENT_FILE}
    exit 0
fi
FUNCTION_NAME="LDAP Cleanup"
#Source other functions
########################################
source ${DIR}/functions.sh
source ${DIR}/../functions.sh
source ${DIR}/util/ids.sh
source ${DIR}/util/openldap.sh
updateDaffyStats
SHOULD_EXIT=0

if  [ ${IS_RH} == 0 ] && [ ${IS_UBUNTU} == 0 ];then
  echo "${RED_TEXT}Unsupported OS.  Script only supports RHEL and Ubuntu."
  echo "${RESET_TEXT}"
  exit 9
fi

if [ ${IS_RH} == 1 ];then
  RHEL_SUPPORTED=`cat /etc/os-release | grep VERSION_ID | grep -c "7.\|8."`
  RHEL_VERSION=`cat /etc/os-release | grep VERSION_ID`
  if [ ${RHEL_SUPPORTED} == 0 ];then
    echo "${RED_TEXT}Unsupported version of RHEL.  Expected 7.X|8.X but found ${RHEL_VERSION}${RESET_TEXT}"
    SHOULD_EXIT=1
  fi
fi

if [ ${IS_UBUNTU} == 1 ];then
  UBUNTU_SUPPORTED=`cat /etc/os-release | grep VERSION_ID | grep -c 20.`
  UBUNTU_VERSION=`cat /etc/os-release | grep VERSION_ID`
  if [ ${UBUNTU_SUPPORTED} == 0 ];then
    echo "${RED_TEXT}Unsupported version of Ubuntu.  Expected 18.X but found ${UBUNTU_VERSION}${RESET_TEXT}"
    SHOULD_EXIT=1
  fi
fi
if [ "${SHOULD_EXIT}" == "1" ]
then
  echo "Missing above required files/variables. Exiting Script."
  echo "${RESET_TEXT}"
  exit 1
fi
if [ ${IS_RH} == 1 ];then
  uninstallIDS
  enableRHELFirewall
elif  [ ${IS_UBUNTU} == 1 ];then
  uninstallOpenLDAP
fi
consoleFooter "${FUNCTION_NAME}"
