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
    read -p "${RED_TEXT}Are you sure you want to destroy the ENTIRE DB2 Instances ?( Enter Yes to confirm)    :  ${RESET_TEXT}" CONFIRM_DESTROY
    if [ ${CONFIRM_DESTROY} != "Yes" ] ;then
      echo "Will NOT destroy DB2 Instances, Exiting Script!!!!!!!!!!!!!!!!!!!"
      exit 1
    fi
fi
if [ $# -eq 0 ]; then
    ls  ${DIR}/../env/*env* |  sed 's/-env.sh//g' | grep -v "samples" | sed 's/.*\///g'
    read -p "${BLUE_TEXT}Which env file do you want to run with    :  ${RESET_TEXT}" ENVIRONMENT_FILE
    ${DIR}/uninstall.sh ${ENVIRONMENT_FILE}
    exit 0
fi
source ${DIR}/functions.sh
source ${DIR}/../functions.sh
updateDaffyStats
if [ ${IS_UBUNTU} == 1 ];then
  UBUNTU_SUPPORTED=`cat /etc/os-release | grep VERSION_ID | grep -c "18\|20"`
  UBUNTU_VERSION=`cat /etc/os-release | grep VERSION_ID`
  if [ ${UBUNTU_SUPPORTED} == 0 ];then
    echo "${RED_TEXT}Unsupported version of Ubuntu.  Expected 18.X|20.X but found ${UBUNTU_VERSION}${RESET_TEXT}"
    SHOULD_EXIT=1
  fi
  DB2_INSTALL_PATH=/opt/ibm/db2/V11.1
fi
if [ ${RHEL_8_SUPPORTED} == 1 ];then
    DB2_INSTALL_PATH=/opt/ibm/db2/V11.5
fi
printHeaderMessage "Precheck"
variablePresent ${DB2_INSTALL_PATH} DB2_INSTALL_PATH

if [ ${SHOULD_EXIT} == 1 ];then
  echo "${RED_TEXT}Missing above required files/variables. Exiting Script.${RESET_TEXT}"
  echo "${RESET_TEXT}"
  exit 1
fi
echo ""
echo "All prechecks passed, lets get to work."
echo ""

printHeaderMessage "Drop all Database"
DATABASE_LIST=`su - ${DB_ADMIN} -c "db2 list db directory | grep 'Database name'| sort | sed 's/.*=//g'"`
for DB in ${DATABASE_LIST}
do
   echo "Dropping Database - $DB"
   su - ${DB_ADMIN} -c "db2 drop database ${DB}" 2>/dev/null
done


printHeaderMessage "Stop Database Instance" ${RED_TEXT}
echo "su - ${DB_ADMIN} -c "db2stop force""
su - ${DB_ADMIN} -c "db2stop force" 2>/dev/null
echo "service db2 stop"
service db2 stop 2>/dev/null

printHeaderMessage "Drop Database Instances" ${RED_TEXT}
echo "${DB2_INSTALL_PATH}/instance/db2idrop ${DB_ADMIN}"
${DB2_INSTALL_PATH}/instance/db2idrop ${DB_ADMIN} 2>/dev/null
echo "${DB2_INSTALL_PATH}/instance/dasdrop"
${DB2_INSTALL_PATH}/instance/dasdrop 2>/dev/null

printHeaderMessage "Uninstall DB2 Files" ${RED_TEXT}
kill -9 $(ps -ef | grep "${DB2_INSTALL_PATH}" | grep -v grep | awk '{print $2}')
echo "${DB2_INSTALL_PATH}/install/db2_deinstall -a"
${DB2_INSTALL_PATH}/install/db2_deinstall -a 2>/dev/null
echo "rm -fR ${DB2_INSTALL_PATH}"
rm -fR ${DB2_INSTALL_PATH} 2>/dev/null

enableDB2Firewall

printHeaderMessage "Cleanup boot stuff" ${RED_TEXT}
if [ ${IS_RH} == 1 ];then
  chkconfig --del db2 2>/dev/null
fi
if [ ${IS_UBUNTU} == 1 ];then
  update-rc.d -f db2 remove 2>/dev/null
  rm -fR /usr/lib/systemd/system/db2.service 2>/dev/null
fi
rm -fR /etc/init.d/db2 2>/dev/null

systemctl daemon-reload 2>/dev/null

printHeaderMessage "Cleanup Users and Groups" ${RED_TEXT}
userdel -r db2fenc1 2> /dev/null
userdel -r dasusr1 2> /dev/null
userdel -r db2inst1  2> /dev/null
groupdel dasadm1 2> /dev/null
groupdel db2fadm1 2> /dev/null

echo ""
echo ""
echo "##########################################################################################################"
SCRIPT_END_TIME=`date`
echo "End Time: ${SCRIPT_END_TIME}"
if (( $SECONDS > 3600 )) ; then
    let "hours=SECONDS/3600"
    let "minutes=(SECONDS%3600)/60"
    let "seconds=(SECONDS%3600)%60"
    echo "DB2 Uninstall Completed in $hours hour(s), $minutes minute(s) and $seconds second(s)"
elif (( $SECONDS > 60 )) ; then
    let "minutes=(SECONDS%3600)/60"
    let "seconds=(SECONDS%3600)%60"
    echo "DB2 Uninstall Completed in $minutes minute(s) and $seconds second(s)"
else
    echo "DB2 Uninstall Completed in $SECONDS seconds"
fi
echo "##########################################################################################################"
echo ""
echo ""
