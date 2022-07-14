#!/bin/bash
############################################################
#Author           : Kyle Dawson
#Author email     : Kyle.Dawson@us.ibm.com
#Original Date    : 2022-01-01
#Initial Version  : v2022-01-18
############################################################
DIR="$( cd "$( dirname "$0" )" && pwd )"
source ${DIR}/env.sh
CURRENT_VERSION=${DAFFY_VERSION}
echo "Getting latest Production copy of Daffy tool"
curl  http://get.daffy-installer.com/download-scripts/daffy-init.sh | bash 
source ${DIR}/env.sh
echo  "Daffy version from ${CURRENT_VERSION} --> ${DAFFY_VERSION}"
