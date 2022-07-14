#!/bin/bash
############################################################
#Author           : Kyle Dawson
#Author email     : jimholz@us.ibm.com
#Original Date    : 2022-05-17
#Initial Version  : v2022-05-23
############################################################
mustGather()
{
  printHeaderMessage "Running ${PROJECT_NAME} Must Gather script"
  rm -fR /tmp/${PROJECT_NAME}/${PROJECT_NAME}_mustgather.tar.gz
  mkdir -p /tmp/${PROJECT_NAME}/{log,tmp,env}
  echo "Getting history of daffy commands"
  cat ~/.bash_history | grep ${PROJECT_NAME} > /tmp/${PROJECT_NAME}/history.txt
  echo "Getting current version of ${PROJECT_NAME}"
  ${DATA_DIR}/${PROJECT_NAME}/version.sh > /tmp/${PROJECT_NAME}/version.txt
  echo "Copy all environment files"
  cp -fR  ${DATA_DIR}/${PROJECT_NAME}/env/*-env.sh /tmp/${PROJECT_NAME}/env/
  echo "Copy all log files"
  cp -fR ${DATA_DIR}/${PROJECT_NAME}/log/* /tmp/${PROJECT_NAME}/log/
  echo "Copy all tmp files"
  cp -fR ${DATA_DIR}/${PROJECT_NAME}/tmp/* /tmp/${PROJECT_NAME}/tmp/
  cd /tmp/${PROJECT_NAME}
  echo "Creating mustGather package"
  tar -czf ${PROJECT_NAME}_mustgather.tar.gz *
  rm -fr env; rm -fr log; rm -fr tmp; rm -fr history.txt; rm -fr version.txt
  echo "Please send your tar file ${BLUE_TEXT}/tmp/${PROJECT_NAME}/${PROJECT_NAME}_mustgather.tar.gz${RESET_TEXT} to the daffy team"
  echo "Follow-up on our Slack channel ${BLUE_TEXT}#daffy-user-group${RESET_TEXT}. Have a nice day!"
}
