#!/bin/bash
############################################################
#Author           : Kyle Dawson
#Author email     : Kyle.Dawson@us.ibm.com
#Original Date    : 2020-10-12
#Initial Version  : v2021-12-01
############################################################
#Set Platform version
############################################################
CP4D_INSTALL_PLAN_APPROVAL=Automatic
CP4D_SPECIALIZED_INSTALL=false
CP4D_OPERATORS_NAMESPACE_SPECIALIZED=cpd-operators
CP4D_OPERATORS_NAMESPACE_EXPRESS=ibm-common-services
CP4D_INSTANCE_NAMESPACE_SPECIALIZED=cpd-instance
CP4D_INSTANCE_NAMESPACE_EXPRESS=cpd-instance
CP4D_LATEST_CLOUDCTL_VERSION=4.0.8

#Cloudctl
####################
CP4D_CLOUDCTL_CASE_BUILD_OUT=false

#Services Catalog
####################
IBM_CLOUD_DB2UOPERATOR_CATALOG_SOURCE=ibm-operator-catalog
IBM_CLOUD_CPD_CATALOG_SOURCE=ibm-operator-catalog
IBM_CLOUD_CPD_SCHEDULING_CATALOG_SOURCE=ibm-operator-catalog
IBM_CLOUD_CPD_WKC_CATALOG_SOURCE=ibm-operator-catalog
IBM_CLOUD_CPD_WS_CATALOG_SOURCE=ibm-operator-catalog
IBM_CLOUD_CPD_WKS_CATALOG_SOURCE=ibm-operator-catalog
IBM_CLOUD_CPD_SPSS_CATALOG_SOURCE=ibm-operator-catalog
IBM_CLOUD_CPD_DV_CATALOG_SOURCE=ibm-operator-catalog
IBM_CLOUD_CPD_WML_CATALOG_SOURCE=ibm-operator-catalog
IBM_CLOUD_CPD_EDB_CATALOG_SOURCE=ibm-operator-catalog
IBM_CLOUD_CPD_DATASTAGE_CATALOG_SOURCE=ibm-operator-catalog
IBM_CLOUD_CPD_DODS_CATALOG_SOURCE=ibm-operator-catalog
IBM_CLOUD_CPD_DMC_CATALOG_SOURCE=ibm-operator-catalog
IBM_CLOUD_CPD_COGNOS_CATALOG_SOURCE=ibm-operator-catalog


CP4D_IBM_OPERATOR_CATALOG_TAG=latest
CP4D_PLATFORM_OPERATOR_CHANNEL=v2.0
CP4D_IBM_CPD_SCHEDULING_OPERATOR_CHANNEL=v1.2
CP4D_IBM_CPD_DATASTAGE_OPERATOR_CHANNEL=v1.0
CP4D_IBM_DODS_OPERATOR_CHANNEL=v4.0
CP4D_IBM_CPD_COGNOS_OPERATOR_CHANNEL=v1.0
CP4D_IBM_DMC_OPERATOR_CHANNEL=v1.0

#https://www.ibm.com/docs/en/cloud-paks/cp-data/4.0?topic=planning-operator-operand-versions#versions__cpd-platform
#https://www.ibm.com/docs/en/cpfs?topic=313-installing-foundational-services-by-using-cli
case ${CP4D_VERSION} in
  4.02|4.0.2)
      CP4D_VERSION=4.0.2
      CP4D_CASE_PACKAGE_VERSION=2.0.5
      CP4D_CASE_COMMON_SERVICES_PACKAGE_VERSION=1.8.0
      CP4D_CASE_SCHEDULING_PACKAGE_VERSION=1.2.3
      CP4D_DB2OLTP_CATALOG_VERSION=4.0.3
      CP4D_DV_VERSION=1.7.2
      CP4D_CASE_SPSS_VERSION=1.0.2
      CP4D_CASE_WS_VERSION=2.0.2
      CP4D_CASE_WML_VERSION=4.0.3
      CP4D_CASE_DATASTAGE_VERSION=4.0.3
      CP4D_CASE_DODS_VERSION=4.0.2
      CP4D_CASE_DMC_VERSION=4.0.2
      CP4D_CASE_WKS_VERSION=4.0.2
      CP4D_WKS_VERSION=4.0.2
      CP4D_CASE_COGNOS_VERSION=2.0.2
      ;;
   4.0.3)
      CP4D_CASE_PACKAGE_VERSION=2.0.8
      CP4D_CASE_COMMON_SERVICES_PACKAGE_VERSION=1.9.0
      CP4D_CASE_SCHEDULING_PACKAGE_VERSION=1.3.0
      CP4D_DB2OLTP_CATALOG_VERSION=4.0.5
      CP4D_DV_VERSION=1.7.3
      CP4D_CASE_SPSS_VERSION=1.0.3
      CP4D_CASE_WS_VERSION=2.0.3
      CP4D_CASE_WML_VERSION=4.0.4
      CP4D_CASE_DATASTAGE_VERSION=4.04
      CP4D_CASE_DODS_VERSION=4.0.3
      CP4D_CASE_DMC_VERSION=4.0.3
      CP4D_CASE_WKS_VERSION=4.0.3
      CP4D_WKS_VERSION=4.0.3
      CP4D_CASE_COGNOS_VERSION=2.0.3
      ;;
   4.0.4)
      CP4D_CASE_PACKAGE_VERSION=2.0.8
      CP4D_CASE_COMMON_SERVICES_PACKAGE_VERSION=1.10.1
      CP4D_CASE_SCHEDULING_PACKAGE_VERSION=1.3.1
      CP4D_DB2OLTP_CATALOG_VERSION=4.0.6
      CP4D_DV_VERSION=1.7.3
      CP4D_CASE_SPSS_VERSION=1.0.4
      CP4D_CASE_WS_VERSION=2.0.4
      CP4D_CASE_WML_VERSION=4.0.5
      CP4D_CASE_DATASTAGE_VERSION=4.0.5
      CP4D_CASE_DODS_VERSION=4.0.4
      CP4D_CASE_DMC_VERSION=4.0.3
      CP4D_CASE_WKS_VERSION=4.0.4
      CP4D_WKS_VERSION=4.0.4
      CP4D_CASE_COGNOS_VERSION=2.0.4
      ;;
  4.0.5)
       CP4D_CASE_PACKAGE_VERSION=2.0.10
       CP4D_CASE_COMMON_SERVICES_PACKAGE_VERSION=1.10.1
       CP4D_CASE_SCHEDULING_PACKAGE_VERSION=1.3.1
       CP4D_DB2OLTP_CATALOG_VERSION=4.0.7
       CP4D_DV_VERSION=1.7.5
       CP4D_CASE_SPSS_VERSION=1.0.5
       CP4D_CASE_WS_VERSION=2.0.5
       CP4D_CASE_WML_VERSION=4.0.6
       CP4D_CASE_DATASTAGE_VERSION=4.0.6
       CP4D_CASE_DODS_VERSION=4.0.5
       CP4D_CASE_DMC_VERSION=4.0.5
       CP4D_CASE_WKS_VERSION=4.0.5
       CP4D_WKS_VERSION=4.0.5
       CP4D_CASE_COGNOS_VERSION=2.0.5
       ;;
   4.0.6)
        CP4D_CASE_PACKAGE_VERSION=2.0.10
        CP4D_CASE_COMMON_SERVICES_PACKAGE_VERSION=1.11.0
        CP4D_CASE_SCHEDULING_PACKAGE_VERSION=1.3.2
        CP4D_DB2OLTP_CATALOG_VERSION=4.0.8
        CP4D_DV_VERSION=1.7.6
        CP4D_CASE_SPSS_VERSION=1.0.6
        CP4D_CASE_WS_VERSION=2.0.6
        CP4D_CASE_WML_VERSION=4.0.7
        CP4D_CASE_DATASTAGE_VERSION=4.0.7
        CP4D_CASE_DODS_VERSION=4.0.6
        CP4D_CASE_DMC_VERSION=4.0.6
        CP4D_CASE_WKS_VERSION=4.0.5
        CP4D_WKS_VERSION=4.0.5
        CP4D_CASE_COGNOS_VERSION=2.0.6
        ;;
    4.0.7)
         CP4D_IBM_CPD_SCHEDULING_OPERATOR_CHANNEL=v1.3
         CP4D_CASE_PACKAGE_VERSION=2.0.12
         CP4D_CASE_COMMON_SERVICES_PACKAGE_VERSION=1.12.3
         CP4D_CASE_SCHEDULING_PACKAGE_VERSION=1.3.3
         CP4D_DB2OLTP_CATALOG_VERSION=4.0.9
         CP4D_DV_VERSION=1.7.7
         CP4D_CASE_SPSS_VERSION=1.0.7
         CP4D_CASE_WS_VERSION=2.0.7
         CP4D_CASE_WML_VERSION=4.0.8
         CP4D_CASE_DATASTAGE_VERSION=4.0.8
         CP4D_CASE_DODS_VERSION=4.0.7
         CP4D_CASE_DMC_VERSION=4.0.7
         CP4D_CASE_WKS_VERSION=4.0.7
         CP4D_WKS_VERSION=4.0.7
         CP4D_CASE_COGNOS_VERSION=2.0.7
         ;;
    4.0.8)
         CP4D_IBM_CPD_SCHEDULING_OPERATOR_CHANNEL=v1.3
         CP4D_CASE_PACKAGE_VERSION=2.0.13
         CP4D_CASE_COMMON_SERVICES_PACKAGE_VERSION=1.13.0
         CP4D_CASE_SCHEDULING_PACKAGE_VERSION=1.3.4
         CP4D_DB2OLTP_CATALOG_VERSION=4.0.10
         CP4D_DV_VERSION=1.7.8
         CP4D_CASE_SPSS_VERSION=1.0.8
         CP4D_CASE_WS_VERSION=2.0.8
         CP4D_CASE_WML_VERSION=4.0.9
         CP4D_CASE_DATASTAGE_VERSION=4.0.9
         CP4D_CASE_DODS_VERSION=4.0.8
         CP4D_CASE_DMC_VERSION=4.0.8
         CP4D_CASE_WKS_VERSION=4.0.7
         CP4D_WKS_VERSION=4.0.7
         CP4D_CASE_COGNOS_VERSION=2.0.8
         ;;
esac
case ${OCP_INSTALL_TYPE} in
  roks-msp)
      #ROKS Defaults
      #######################
      if [ "${CP4D_STORAGE_ENABLE_PORTWORX}" == "true"  ]; then
        CP4D_STORAGE_VENDOR=portworx
        CP4D_STORAGE_CLASS=portworx-shared-gp3
      else
        CP4D_STORAGE_VENDOR=
        CP4D_STORAGE_CLASS=ibmc-file-gold-gid
      fi
      CP4D_WKC_DB2U_SET_KERNAL_PARMS=True
      CP4D_IIS_DB2U_SET_KERNAL_PARMS=True
      ;;
  *)
      #All Other Defaults
      #######################
      CP4D_STORAGE_VENDOR=ocs
      CP4D_STORAGE_CLASS=ocs-storagecluster-cephfs
      CP4D_WKC_DB2U_SET_KERNAL_PARMS=False
      CP4D_IIS_DB2U_SET_KERNAL_PARMS=False
      ;;
esac