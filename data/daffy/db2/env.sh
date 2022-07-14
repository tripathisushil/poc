#!/bin/bash
############################################################
#Author           : Kyle Dawson
#Author email     : Kyle.Dawson@us.ibm.com
#Original Date    : 2022-01-23
#Current Version  : v2022-02-15
############################################################
#Setup Variables
############################################################
case ${DB2_VERSION} in
   11.1)
       DB2_11_1_INSTALL_FILE=${SOFTWARE_INSTALLS_DIR}/db2/DB2_AWSE_REST_Svr_11.1_Lnx_86-64.tar.gz
       DB2_INSTALL_FIXPACK_FILE=${SOFTWARE_INSTALLS_DIR}/db2/v11.1.4fp4a_linuxx64_universal_fixpack.tar.gz
       DB2_INSTALL_PATH=/opt/ibm/db2/V11.1
       ;;
    11.5)
       DB2_11_5_INSTALL_FILE=${SOFTWARE_INSTALLS_DIR}/db2/DB2_Svr_11.5_Linux_x86-64.tar.gz
       #DB2_INSTALL_FIXPACK_FILE=${SOFTWARE_INSTALLS_DIR}/db2/???????
       DB2_INSTALL_PATH=/opt/ibm/db2/V11.5
       ;;
esac
