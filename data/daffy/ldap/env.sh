#!/bin/bash
############################################################
#Author           : Kyle Dawson
#Author email     : Kyle.Dawson@us.ibm.com
#Original Date    : 2022-01-23
#Current Version  : v2022-02-15
############################################################
#Setup Variables
############################################################
case ${IDS_VERSION} in
    6.4)
      IDS_INSTALL_FILE=sds64-linux-x86-64.iso
      IDS_INSTALL_FEATURE_FILE=sds64-premium-feature-act-pkg.zip
      IDS_HOME=/opt/ibm/ldap/V6.4
      DB2_VERSION=11.5
      DB2_MINOR_VERSION=0.0
      IDS_JDK_FIXPACK=6.0.16.2-ISS-JAVA-LinuxX64-FP0002.tar
      ;;
esac
