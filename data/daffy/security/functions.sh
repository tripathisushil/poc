#!/bin/bash
############################################################
#Author           : Jeff Imholz
#Author email     : jimholz@us.ibm.com
#Original Date    : 2022-04-01
#Initial Version  : v2022-04-01
############################################################
RED_TEXT=`tput setaf 1`
GREEN_TEXT=`tput setaf 2`
ORANGE_TEXT=`tput setaf 5`
BLUE_TEXT=`tput setaf 6`
RESET_TEXT=`tput sgr0`


allCredentialsRemove()
{
  case ${1} in
    *)
    if [ "${CONFIRM_DESTROY}" != "Yes" ]; then
        read -p "${RED_TEXT}Are you sure you want to clean up ${1} security info ?( Enter Yes to confirm)    :  ${RESET_TEXT}" CONFIRM_DESTROY
        if [ ${CONFIRM_DESTROY} != "Yes" ] ;then
          echo "Will NOT clean up all keys, Exiting Script!!!!!!!!!!!!!!!!!!!"
          exit 1
        fi
    fi
    ;;&
    aws|all)
      printHeaderMessage "Removing aws cloud platform keys" ${RED_TEXT}
      echo "rm -fr ~/.aws"
      rm -fr ~/.aws &> /dev/null
      echo "Remove AWS_SECRET_ACCESS_KEY from ~/.profile"
      sed -i -e "/AWS_SECRET_ACCESS_KEY/d" ~/.profile
      echo "Remove AWS_WORKER_ROOTVOLUME_KMSKEYARN from ~/.profile"
      sed -i -e "/AWS_WORKER_ROOTVOLUME_KMSKEYARN/d" ~/.profile
      echo "Cleanup of aws cloud platform keys is complete. Please logout of this session and relogin"
      echo "Or enter this at command prompt: "
      echo "${RED_TEXT}unset AWS_SECRET_ACCESS_KEY${RESET_TEXT}"
      echo "${RED_TEXT}unset AWS_WORKER_ROOTVOLUME_KMSKEYARN${RESET_TEXT}"
      ;;&
    azure|all)
      printHeaderMessage "Removing azure cloud platform keys" ${RED_TEXT}
      echo "rm -fr ~/.azure"
      rm -fr ~/.azure &> /dev/null
      echo "Remove AZURE_CLIENT_SECRET from ~/.profile"
      sed -i -e "/AZURE_CLIENT_SECRET/d" ~/.profile
      echo "Cleanup of azure cloud platform keys is complete. Please logout of this session and relogin"
      echo "Or enter this at command prompt:"
      echo "${RED_TEXT}unset AZURE_CLIENT_SECRET${RESET_TEXT}"
      ;;&
    gcp|all)
      printHeaderMessage "Removing gcp cloud platform keys" ${RED_TEXT}
      echo "rm -fr ~/.gcp "
      rm -fr ~/.gcp &> /dev/null
      echo "Cleanup of gcp cloud platform keys is complete"
      ;;&
    ibm|all)
      printHeaderMessage "Removing ibm cloud platform keys" ${RED_TEXT}
      echo "rm -fr ~/.bluemix"
      rm -fr ~/.bluemix &> /dev/null
      echo "rm -fr ~/.kube"
      rm -fr ~/.kube &> /dev/null
      echo "Remove IBM_ENTITLEMENT_KEY from ~/.profile"
      sed -i -e "/IBM_ENTITLEMENT_KEY/d" ~/.profile
      FOUND_IBMCLOUD=`which ibmcloud | grep -c ibmcloud`
      if [  ${FOUND_IBMCLOUD} -eq 1  ]; then
        echo "Logging out of ibmcloud session....."
        ibmcloud logout
      fi
      echo "Cleanup of ibm cloud platform keys is complete. Please logout of this session and relogin"
      echo "Or enter this at command prompt: "
      echo "${RED_TEXT}unset IBM_ENTITLEMENT_KEY${RESET_TEXT}"
      ;;&
    vsphere|all)
      printHeaderMessage "Removing vsphere information" ${RED_TEXT}
      echo "Remove VSPHERE_HOSTNAME from ~/.profile"
      sed -i -e "/VSPHERE_HOSTNAME/d" ~/.profile
      echo "Remove VSPHERE_USERNAME from ~/.profile"
      sed -i -e "/VSPHERE_USERNAME/d" ~/.profile
      echo "Remove VSPHERE_PASSWORD from ~/.profile"
      sed -i -e "/VSPHERE_PASSWORD/d" ~/.profile
      echo "Cleanup of all vsphere keys is complete. Please logout of this session and relogin"
      echo "Or enter these at command prompt: "
      echo "${RED_TEXT}unset VSPHERE_HOSTNAME${RESET_TEXT}"
      echo "${RED_TEXT}unset VSPHERE_USERNAME${RESET_TEXT}"
      echo "${RED_TEXT}unset VSPHERE_PASSWORD${RESET_TEXT}"
      ;;&
    pull-secret|all)
      printHeaderMessage "Removing RedHat pull secret" ${RED_TEXT}
      echo "Remove PULL_SECRET from ~/.profile"
      sed -i -e "/PULL_SECRET/d" ~/.profile
      echo "Cleanup of RedHat pull secret is complete. Please logout of this session and relogin"
      echo "Or enter this at command prompt upon exit: "
      echo "${RED_TEXT}unset PULL_SECRET${RESET_TEXT}"
      ;;&
    ssh|all)
      printHeaderMessage "Removing ssh key" ${RED_TEXT}
      echo "Removing directories where credentials are stored"
      echo "rm -fR ~/.ssh/id_rsa*"
      rm -fR ~/.ssh/id_rsa* &> /dev/null
      echo "Cleanup of all keys is complete."
      ;;&
esac
}

printHeaderMessage()
{
 echo ""
  if [  "${#2}" -ge 1 ] ;then
      echo "${2}${1}"
  else
      echo "${BLUE_TEXT}${1}"
  fi
  echo "################################################################${RESET_TEXT}"
  sleep 1
}
