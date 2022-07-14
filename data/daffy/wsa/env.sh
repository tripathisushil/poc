#!/bin/bash
############################################################
#Author           : Kyle Dawson
#Author email     : Kyle.Dawson@us.ibm.com
#Original Date    : 2022-01-21
#Initial Version  : v2022-02-15
############################################################
WSA_OPERATOR_NAMESPACE=websphere-automation
WSA_INSTANCE_NAMESPACE=websphere-automation
IBM_COMMON_SERVICES_NAMESPACE=ibm-common-services
WSA_STORAGE_SIZE=50Gi
WSA_SECURE=false

case ${OCP_INSTALL_TYPE} in
  roks-msp)
      #ROKS Defaults
      #######################
      WSA_STORAGE_CLASS=ibmc-file-gold-gid
      WSA_BLOCK_CLASS=ibmc-block-gold
      ;;
  *)
      #All Other Defaults
      #######################
      WSA_STORAGE_CLASS=ocs-storagecluster-cephfs
      WSA_BLOCK_CLASS=ocs-storagecluster-ceph-rbd
      ;;
esac
