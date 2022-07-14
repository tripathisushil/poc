#!/bin/bash
############################################################
#Author           : Dave Krier
#Author email     : dakrier@us.ibm.com
#Original Date    : 2021-11-15
#Initial Version  : v2021-12-01
############################################################
#Setup Variables
############################################################
CP4WAIOPS_NAMESPACE=cp4waiops
CP4WAIOPS_EMGR_NAMESPACE=cp4waiops-emgr
CP4WAIOPS_IMAGE_PULL_SECRET=ibm-entitlement-key

case ${CP4WAIOPS_VERSION} in
  3.3.1)
    CP4WAIOPS_EMGR_SUBSCRIPTION_CHANNEL=v1.7
    ;;
esac

case ${OCP_INSTALL_TYPE} in
  roks-msp)
      #ROKS Defaults
      #######################
      CP4WAIOPS_STORAGE_CLASS=ibmc-file-gold-gid
      CP4WAIOPS_BLOCK_STORAGE_CLASS=ibmc-block-gold
      ;;
  *)
      #All Other Defaults
      #######################
      CP4WAIOPS_STORAGE_CLASS=ocs-storagecluster-cephfs
      CP4WAIOPS_BLOCK_STORAGE_CLASS=ocs-storagecluster-ceph-rbd
      ;;
esac
