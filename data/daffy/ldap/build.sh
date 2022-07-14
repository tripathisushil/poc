#!/bin/bash
############################################################
#Author           : Kyle Dawson
#Author email     : Kyle.Dawson@us.ibm.com
#Original Date    : 2020-04-26
#Current Version  : 3.0
############################################################
DIR="$( cd "$( dirname "$0" )" && pwd )"
PRODUCT_SHORT_NAME=ldap
PRODUCT_FUNCTION=build
source ${DIR}/../env/${1}-env.sh &> /dev/null
source ${DIR}/../env.sh
source ${DIR}/env.sh
if [ $# -eq 0 ]; then
    ls  ${DIR}/../env/*env* |  sed 's/-env.sh//g' | grep -v "samples" | sed 's/.*\///g'
    read -p "${BLUE_TEXT}Which env file do you want to run with    :  ${RESET_TEXT}" ENVIRONMENT_FILE
    ${DIR}/build.sh ${ENVIRONMENT_FILE}
    exit 0
fi
FUNCTION_NAME="LDAP Build"
#Source other functions
########################################
source ${DIR}/functions.sh
source ${DIR}/../functions.sh
source ${DIR}/util/ids.sh
source ${DIR}/util/openldap.sh

case ${2} in
  --precheck|--Precheck)
        ldapPreCheck
        exit 0
        ;;
  --displayLDAPInfo|--DisplayLDAPInfo|--console|--Console)
        if [ ${IS_RH} == 1 ];then
          displayIDSLDAPInfo
        fi
        if [ ${IS_UBUNTU} == 1 ];then
          displayOpenLDAPInfo
        fi
        exit 0
        ;;
  --help|--?|?|-?|help|-help|--Help|-Help)
       printHeaderMessage "Help Menu for build flags"
       echo "--Precheck                            This will just do a quick precheck to see if the environment is ready for a install"
       echo "--DisplayLDAPInfo                     This will disply DB2 Connection Info"
       echo ""
       echo ""
       echo ""
       exit 0
       ;;
   --*|-*)
       echo "${RED_TEXT}Unsupported flag in command line - ${2}. ${RESET_TEXT}"
       echo ""
       exit 9
       ;;
esac
mkdir -p ${TEMP_DIR}/${PRODUCT_SHORT_NAME}
mkdir -p ${LOG_DIR}/${PRODUCT_SHORT_NAME}
ldapPreCheck
updateDaffyStats
prepareLDAPInputFiles
#Start Install
#######################
if [ ${IS_RH} == 1 ];then
  installIDS
  disableRHELFirewall
  displayIDSLDAPInfo
else
  installSldap
  displayOpenLDAPInfo
fi
consoleFooter "${FUNCTION_NAME}"
