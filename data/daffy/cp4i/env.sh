#!/bin/bash
############################################################
#Author           : Dave Krier
#Author email     : dakrier@us.ibm.com
#Original Date    : 2021-11-15
#Initial Version  : v2021-12-01
############################################################
#Setup Variables
############################################################
CP4I_NAMESPACE=cp4i
case ${OCP_INSTALL_TYPE} in
  roks-msp)
      #ROKS Defaults
      #######################
      CP4I_STORAGE_CLASS=ibmc-file-gold-gid
      CP4I_BLOCK_CLASS=ibmc-block-gold
      ;;
  rosa-msp)
      #ROSA Defaults
      ######################
      CP4I_STORAGE_CLASS=ocs-storagecluster-ceph-rbd
      CP4I_BLOCK_CLASS=ocs-storagecluster-ceph-rbd
      ;;
  *)
      #All Other Defaults
      #######################
      CP4I_STORAGE_CLASS=ocs-storagecluster-cephfs
      CP4I_BLOCK_CLASS=ocs-storagecluster-ceph-rbd
      ;;
esac

case ${CP4I_VERSION} in
  2021.4.1)
      CP4I_LICENSE='L-RJON-C7QG3S'
      CP4I_SUBSCRIPTION_CHANNEL='v1.5'
      CP4I_LICENSE_USE='CloudPakForIntegrationNonProduction'
      ACE_LICENSE='L-KSBM-C87FU2'
      ACE_VERSION='12.0.2.0-r2'
      APIC_LICENSE='L-RJON-C7BJ42'
      APIC_VERSION='10.0.4.0-ifix1-54'
      ASSET_REPO_LICENSE='L-PNAA-C68928'
      ES_VERSION='10.5'
      MQ_LICENSE='L-RJON-C7QG3S'
      MQ_VERSION='9.2.4.0-r1'
      ;;
  2021.3.1)
      CP4I_LICENSE='L-RJON-C5CSNH'
      CP4I_SUBSCRIPTION_CHANNEL='v1.4'
      ;;
  2021.2.1)
      CP4I_LICENSE='L-RJON-BZFQU2'
      CP4I_SUBSCRIPTION_CHANNEL='v1.3'
      ;;
   *)
     echo "${RED_TEXT}FAILED: Invalid version CP4I_VERSION=${CP4I_VERSION}${RESET_TEXT}"
     echo "${RED_TEXT}Current Supported Versions: 2021.4.1, 2021.3.1, 2021.2.1${RESET_TEXT}"
     SHOULD_EXIT=1
     ;;
esac
