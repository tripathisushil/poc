#!/bin/bash
############################################################
#Author           : Kyle Dawson
#Author email     : Kyle.Dawson@us.ibm.com
#Original Date    : 2022-04-12
#Initial Version  : v2022-04-20
############################################################
#Standard values but can be overriddn at each lower level
##########################################################
DIR="$( cd "$( dirname "$0" )" && pwd )"
source ${DIR}/env.sh
if [ -f ${DIR}/beta-tag* ]; then
  DAFFY_VERSION_BETA_DATE=`ls ${DIR} | grep beta-tag | sed "s/beta-tag-//g"`
  echo "You are running Daffy ${DAFFY_VERSION}(${DAFFY_VERSION_BETA_DATE})"
else
  echo "You are running Daffy ${DAFFY_VERSION}"
fi
