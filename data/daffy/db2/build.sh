#!/bin/bash
############################################################
#Author           : Kyle Dawson
#Author email     : Kyle.Dawson@us.ibm.com
#Original Date    : 2020-04-26
#Current Version  : 3.0
############################################################
#Setup Variables
############################################################
DIR="$( cd "$( dirname "$0" )" && pwd )"
PRODUCT_SHORT_NAME=db2
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
source ${DIR}/functions.sh
source ${DIR}/../functions.sh

case ${2} in
  --precheck|--Precheck)
        prechecksDB2
        exit 0
        ;;
  --displayDB2Info|--DisplayDB2Info|--console|--Console)
        displayDB2Info
        exit 0
        ;;
  --help|--?|?|-?|help|-help|--Help|-Help)
       printHeaderMessage "Help Menu for build flags"
       echo "--Precheck                            This will just do a quick precheck to see if the environment is ready for a install"
       echo "--DisplayDB2Info                      This will disply DB2 Connection Info"
       exit 0
       ;;
   --*|-*)
       echo "${RED_TEXT}Unsupported flag in command line - ${2}. ${RESET_TEXT}"
       echo ""
       exit 9
       ;;
esac
#Main steps for install
########################################
prechecksDB2
updateDaffyStats
installDB2
if [ ! -z ${DB2_INSTALL_FIXPACK_FILE}  ]; then
  prepareDB2FixPak
  installDB2FixPak
  upgradeDB2Instances
fi
updateDB2Permission
setupDB2BootScripts
disableDB2Firewall
cleanDB2Install
displayDB2Info
echo ""
echo ""
echo "##########################################################################################################"
SCRIPT_END_TIME=`date`
echo "End Time: ${SCRIPT_END_TIME}"
if (( $SECONDS > 3600 )) ; then
    let "hours=SECONDS/3600"
    let "minutes=(SECONDS%3600)/60"
    let "seconds=(SECONDS%3600)%60"
    echo "DB2 Install Completed in $hours hour(s), $minutes minute(s) and $seconds second(s)"
elif (( $SECONDS > 60 )) ; then
    let "minutes=(SECONDS%3600)/60"
    let "seconds=(SECONDS%3600)%60"
    echo "DB2 Install Completed in $minutes minute(s) and $seconds second(s)"
else
    echo "DB2 Install Completed in $SECONDS seconds"
fi
echo "##########################################################################################################"
echo ""
echo ""
