#!/bin/bash
############################################################
#Author           : Kyle Dawson
#Author email     : Kyle.Dawson@us.ibm.com
#Original Date    : 2022-01-26
#Initial Version  : v2022-02-15
############################################################
ldapPreCheck()
{
  printHeaderMessage "Precheck"
  SHOULD_EXIT=0
  prepareLDAPHost
  if [ ${IS_RH} == 1 ];then
    RHEL_SUPPORTED=`cat /etc/os-release | grep VERSION_ID | grep -c "8."`
    RHEL_VERSION=`cat /etc/os-release | grep VERSION_ID`
    if [ ${RHEL_SUPPORTED} == 0 ];then
      echo "${RED_TEXT}FAILED ${RESET_TEXT} Unsupported version of RHEL.  Expected 8.x but found ${RHEL_VERSION}"
      SHOULD_EXIT=1
    fi
  else
    echo "${RED_TEXT}FAILED ${RESET_TEXT} Unsupported Linux.  Only supported is RHEL 8.X"
    echo "Exiting Script!!!!!!!!!!!!!!!!"
    echo ""
    echo ""
    exit 99
  fi

  if [ -z "${IDS_VERSION}" ]; then
    echo "${RED_TEXT}FAILED ${RESET_TEXT} Missing IDS_VERSION in your enviornment file. Valid version is 6.4"
    echo "Please add IDS_VERSION=6.4 to your enviornment file and run process again."
    echo ""
    echo "Exiting Script!!!!!!!!!!!!!!!!"
    echo ""
    echo ""
    exit 99
  fi
  #if [ ${IS_UBUNTU} == 1 ];then
  #  UBUNTU_SUPPORTED=`cat /etc/os-release | grep VERSION_ID | grep -c 20.`
  #  UBUNTU_VERSION=`cat /etc/os-release | grep VERSION_ID`
  #  if [ ${UBUNTU_SUPPORTED} == 0 ];then
  #    echo "Unsupported version of Ubuntu.  Expected 20.X but found ${UBUNTU_VERSION}"
  #    SHOULD_EXIT=1
  #  fi
  #  variablePresent ${LDAP_BIND_DN_OPENLDAP} LDAP_BIND_DN_OPENLDAP
  #fi
  if [ ${IS_RH} == 1 ];then
    printHeaderMessage "Validate IDS Software"
    variablePresent ${IDS_INSTALL_FILE} IDS_INSTALL_FILE
    if [ ! -z ${IDS_INSTALL_FILE} ]; then
      if [ ! -f  ${SOFTWARE_INSTALLS_DIR}/ldap/${IDS_INSTALL_FILE} ]; then
        echo "${RED_TEXT}FATAL ${RESET_TEXT} Missing IDS Software - ${SOFTWARE_INSTALLS_DIR}/ldap/${IDS_INSTALL_FILE}"
        echo "Please login to IBM Passport Advantage and search for this part number - CN487ML"
        echo "Once you have the file, please upload to this server to this folder - ${SOFTWARE_INSTALLS_DIR}/ldap "
        echo ""
        SHOULD_EXIT=1
      else
        echo "${BLUE_TEXT}PASSED ${RESET_TEXT} Found Software - ${SOFTWARE_INSTALLS_DIR}/ldap/${IDS_INSTALL_FILE}"
      fi
      variablePresent ${IDS_INSTALL_FEATURE_FILE} IDS_INSTALL_FEATURE_FILE
      if [ ! -f ${SOFTWARE_INSTALLS_DIR}/ldap/${IDS_INSTALL_FEATURE_FILE} ]; then
        echo "${RED_TEXT}FATAL ${RESET_TEXT} Missing IDS Software - ${SOFTWARE_INSTALLS_DIR}/ldap/${IDS_INSTALL_FEATURE_FILE}"
        echo "Please login to IBM Passport Advantage and search for this part number - CN4VJML"
        echo "Once you have the file, please upload to this server to this folder - ${SOFTWARE_INSTALLS_DIR}/ldap "
        echo ""
        SHOULD_EXIT=1
      else
        echo "${BLUE_TEXT}PASSED ${RESET_TEXT} Found Software - ${SOFTWARE_INSTALLS_DIR}/ldap/${IDS_INSTALL_FEATURE_FILE}"
      fi
      resourcePresent ${DATA_DIR}/${PROJECT_NAME}/${PRODUCT_SHORT_NAME}/templates/os/ldap.rhel
      echo ""
    fi
    variablePresent ${IDS_JDK_FIXPACK} IDS_JDK_FIXPACK
    variablePresent ${IDS_HOME} IDS_HOME
    variablePresent ${DB2_VERSION} DB2_VERSION
    variablePresent ${DB2_MINOR_VERSION} DB2_MINOR_VERSION
    variablePresent ${IDS_VERSION} IDS_VERSION
    validateDB2
    printHeaderMessage "Validate IDS Version"
    case ${IDS_VERSION} in
        6.4)
          echo "${BLUE_TEXT}PASSED ${RESET_TEXT} Valid version of IDS(LDAP) - ${IDS_VERSION}"
          ;;
        *)
          echo "${RED_TEXT}FAILED ${RESET_TEXT} Invalid version of IDS(LDAP) - ${IDS_VERSION}"
          echo "Only Supported version is 6.4."
          SHOULD_EXIT=1
    esac
  fi
  validateDBPassword
  variablePresent ${LDAP_BASE_DN} LDAP_BASE_DN
  variablePresent ${LDAP_PORT} LDAP_PORT
  validateLDAPPassword
  localPortInuse ${LDAP_PORT}
  shouldExit

  echo ""
  echo "All prechecks passed, lets get to work."
  echo ""
}

prepareLDAPHost()
{
  mkdir -p ${TEMP_DIR}/${PRODUCT_SHORT_NAME}
  if [ "${IS_RH}" == 1 ];then
    printHeaderMessage "Prepare Host ( LOG ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/yum.log )"
    echo "yum upgrade -y"
    yum upgrade -y > ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/yum.log  2>&1
    echo "yum install libaio unzip binutils ksh net-tools -y"
    yum install libaio unzip binutils ksh -y >> ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/yum.log 2>&1
    updateBashProfile
  fi
  if [ "${IS_UBUNTU}" == 1 ];then
    printHeaderMessage "Prepare Host ( LOG ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/apt-get.log )"
    echo "Install updates - apt-get upgrade -y"
    apt-get update -y > ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/apt-get.log 2>&1
    echo "Install upgrades - apt-get upgrade -y"
    apt-get upgrade -y >> ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/apt-get.log 2>&1
    echo ""
  fi
 echo ""
}

prepareLDAPInputFiles()
{
  printHeaderMessage "Prepare Input Files"
  mkdir -p ${TEMP_DIR}/${PRODUCT_SHORT_NAME}
  cd ${TEMP_DIR}/${PRODUCT_SHORT_NAME}
  cp -fR ${DIR}/templates/* ${TEMP_DIR}/${PRODUCT_SHORT_NAME}
  if [ ${IS_RH} == 1 ];then
      LDAP_BIND_DN=${LDAP_BIND_DN_IDS}
  fi
  if [ ${IS_UBUNTU} == 1 ];then
      LDAP_BIND_DN=${LDAP_BIND_DN_OPENLDAP}
  fi

  #if userPasswords are set, replace with variable
  sed -i'' -e "s/.*userPassword.*/userPassword: $LDAP_PASSWORD/g" ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/base.ldif
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s|@IDS_HOME@|$IDS_HOME|g"
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@LDAP_INSTANCE_USER_ID@/$LDAP_INSTANCE_USER_ID/g"
}


validateDB2()
{
      printHeaderMessage "Validate Local DB2"
      local FOUND_DB2=`su - ${DB_ADMIN} -c "db2licm -l" 2>/dev/null | grep "Version information" |  grep -c ${DB2_VERSION}`
      if [ ${FOUND_DB2} -le 0 ]; then
        SHOULD_EXIT=1
        echo "${RED_TEXT}FAILED ${RESET_TEXT} Unable to find local DB2 - ${DB2_VERSION}"
        su - ${DB_ADMIN} -c "db2licm -l" 2>/dev/null
      else
        local RUNNING_DB2=`su - ${DB_ADMIN} -c "db2ilist" 2>/dev/null |  grep -c ${DB_ADMIN}`
        if [ ${RUNNING_DB2} -le 0 ]; then
          SHOULD_EXIT=1
          echo "${RED_TEXT}FAILED ${RESET_TEXT} Unable to find local DB2 - ${DB2_VERSION}"
          su - ${DB_ADMIN} -c "db2ilist" 2>/dev/null
        else
          echo "${BLUE_TEXT}PASSED ${RESET_TEXT} Valid version of local DB2 - ${DB2_VERSION}"
          echo "Local Db2 Instances"
          su - ${DB_ADMIN} -c "db2ilist" 2>/dev/null
          echo ""
        fi
      fi
}
