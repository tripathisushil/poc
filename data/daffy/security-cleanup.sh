#!/bin/bash
############################################################
#Author           : Jeff Imholz
#Author email     : jimholz@us.ibm.com
#Original Date    : 2022-04-01
#Initial Version  : v2022-04-01
############################################################
#Common Variables
######################
DIR="$( cd "$( dirname "$0" )" && pwd )"
source ${DIR}/security/functions.sh
securityCleanUpHelp()
{
  printHeaderMessage "Help Menu for security cleanup flags"
  echo "--all                            This will cleanup all security including RH Pull Secret, SSH key, and IBM Entitlement keys"
  echo "--aws                            This will cleanup the aws security information"
  echo "--azure                          This will cleanup the azure security information"
  echo "--gcp                            This will cleanup the gcp credential information"
  echo "--ibm                            This will cleanup the IBM Entitlement Key and ibmcloud sesssion info"
  echo "--vsphere                        This will cleanup vsphere information"
  echo "--pullSecret                     This will cleanup your RedHat Pull Secret"
  echo "--ssh                            This will cleanup your local ssh key"
  echo "--help|--?|?|-?|help|-help       This help menu"
  echo ""
}
if [ $# -eq 0 ]; then
  securityCleanUpHelp
fi

while [ $# -ne 0 ]
do
    case ${1} in
       --All|--all)
            allCredentialsRemove all
            ;;
       --aws)
            allCredentialsRemove aws
            ;;
       --azure)
            allCredentialsRemove azure
            ;;
       --gcp)
            allCredentialsRemove gcp
            ;;
       --ibm)
            allCredentialsRemove ibm
            ;;
        --vsphere)
            allCredentialsRemove vsphere
            ;;
       --pullSecret)
            allCredentialsRemove pull-secret
            ;;
       --ssh)
            allCredentialsRemove ssh
            ;;
       --help|--?|?|-?|help|-help|--Help|-Help)
            securityCleanUpHelp
            exit 0
            ;;
      *)
            echo "${RED_TEXT}Unsupported flag in command line - ${2}. ${RESET_TEXT}"
            securityCleanUpHelp
            echo ""
            exit 9
            ;;
    esac
    shift
done
