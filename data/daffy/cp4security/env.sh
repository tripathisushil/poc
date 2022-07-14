############################################################
#Author           : Jeff Imholz
#Author email     : jimholz@us.ibm.com
#Original Date    : 2022-04-27
#Initial Version  : v2022-05-15
############################################################
#Setup Variables
############################################################
CP4SEC_NAMESPACE=cp4security
case ${OCP_INSTALL_TYPE} in
  roks-msp)
      #ROKS Defaults
      #######################
      CP4SEC_STORAGE_CLASS=ibmc-file-gold-gid
      CP4SEC_BLOCK_CLASS=ibmc-block-gold
      ;;
  rosa-msp)
      #ROSA Defaults
      ######################
      CP4SEC_STORAGE_CLASS=gp2
      CP4SEC_BLOCK_CLASS=gp2
      ;;
  *)
      #All Other Defaults
      #######################
      CP4SEC_STORAGE_CLASS=ocs-storagecluster-cephfs
      CP4SEC_BLOCK_CLASS=ocs-storagecluster-ceph-rbd
      ;;
esac

case ${CP4SEC_VERSION} in
  1.9)
      CP4SEC_SUBSCRIPTION_CHANNEL='v1.9'
      CP4SEC_ADMIN=secadmin
      CP4SEC_ADMIN_PWD=cp4security
      ;;
   *)
     echo "${RED_TEXT}FAILED: Invalid version CP4SEC_VERSION=${CP4SEC_VERSION}${RESET_TEXT}"
     echo "${RED_TEXT}Current Supported Versions: 1.9${RESET_TEXT}"
     SHOULD_EXIT=1
     ;;
esac
