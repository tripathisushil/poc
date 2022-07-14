#!/bin/bash
############################################################
#Author           : Kyle Dawson
#Author email     : Kyle.Dawson@us.ibm.com
#Original Date    : 2022-01-23
#Initial Version  : v2022-02-15
############################################################
prechecksDB2()
{
  printHeaderMessage "Precheck"
  SHOULD_EXIT=0
  prepareOSDB2
  validLocalHostname

  if [ ${IS_UBUNTU} == 0 ] &&  [ ${IS_RH} == 0 ];then
    echo "${RED_TEXT}Unsupported OS.  Script only supports RHEL and Ubuntu${RESET_TEXT}"
    echo ""
    exit 9
  fi
  validateDB2Version
  variablePresent ${SOFTWARE_INSTALLS_DIR} SOFTWARE_INSTALLS_DIR
  resourcePresent ${DB2_INSTALL_FILE}
    #Test Version of OS
  #####################
  if [ ${IS_UBUNTU} == 1 ];then
    UBUNTU_SUPPORTED=`cat /etc/os-release | grep VERSION_ID | grep -c "18\|20"`
    UBUNTU_VERSION=`cat /etc/os-release | grep VERSION_ID`
    if [ ${UBUNTU_SUPPORTED} == 0 ];then
      echo "${RED_TEXT}Unsupported version of Ubuntu.  Expected 18.X\20.X but found ${UBUNTU_VERSION}${RESET_TEXT}"
      SHOULD_EXIT=1
    fi
    printHeaderMessage "Validate DB2 Software"
    resourcePresent ${DB2_INSTALL_FIXPACK_FILE}
    DB2_INSTALL_FILE=${DB2_11_1_INSTALL_FILE}
    if [ ! -f  ${DB2_INSTALL_FILE} ]; then
      echo "${RED_TEXT}FATAL ${RESET_TEXT} Missing DB2 Software - ${DB2_INSTALL_FILE}"
      echo "Please login to IBM Passport Advantage and search for this part number - CC1U0ML"
      echo "Once you have the file, please upload to this server to this folder - ${SOFTWARE_INSTALLS_DIR}/db2/"
      echo ""
      SHOULD_EXIT=1
    else
      echo "${BLUE_TEXT}PASSED ${RESET_TEXT} Found Software - ${DB2_INSTALL_FILE}"
    fi
  fi
  if [ ${IS_RH} == 1 ];then
    RHEL_8_SUPPORTED=`cat /etc/os-release | grep VERSION_ID | grep -c 8.`
    RHEL_VERSION=`cat /etc/os-release | grep VERSION_ID`
    if [ ${RHEL_8_SUPPORTED} == 1 ];then
        printHeaderMessage "Validate DB2 Software"
        DB2_INSTALL_FILE=${DB2_11_5_INSTALL_FILE}
        if [ ! -f  ${DB2_INSTALL_FILE} ] || [ -z ${DB2_INSTALL_FILE} ]; then
          echo "${RED_TEXT}FATAL ${RESET_TEXT} Missing DB2 Software - ${DB2_INSTALL_FILE}"
          echo "Please login to IBM Passport Advantage and search for this part number - CC1U0ML"
          echo "Once you have the file, please upload to this server to this folder - ${SOFTWARE_INSTALLS_DIR}/db2 "
          SHOULD_EXIT=1
        else
          echo "${BLUE_TEXT}PASSED ${RESET_TEXT} Found Software - ${DB2_INSTALL_FILE}"
        fi
    fi
    if [ ${RHEL_8_SUPPORTED} == 0 ];then
      echo "${RED_TEXT}Unsupported version of RHEL.  8.X but found ${RHEL_VERSION}${RESET_TEXT}"
      SHOULD_EXIT=1
    fi

  fi
  echo ""
  validateDBPassword
  localPortInuse ${DB2_PORT}
  shouldExit
  DB2_SETUP_INSTALL_ROOT=${SOFTWARE_INSTALLS_DIR}/db2/server_dec
  DB2_INSTALL_LIC_FILE=${DB2_SETUP_INSTALL_ROOT}/db2/license/db2ese_t.lic
  echo ""
  echo "All prechecks passed, lets get to work."
  echo ""
}

prepareOSDB2()
{
  printHeaderMessage "Prepare host (LOG ${LOG_DIR}/${PRODUCT_SHORT_NAME}/os-update.log )"
  mkdir -p ${LOG_DIR}/${PRODUCT_SHORT_NAME}
  mkdir -p ${TMP_DIR}/${PRODUCT_SHORT_NAME}
  if [ ${IS_UBUNTU} == 1 ];then
    echo "apt-get update -y "
    apt-get update -y &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/apt-get-update.log
    echo "apt-get install libx32stdc++6 libaio1 default-jre unzip binutils -y "
    apt-get install libx32stdc++6 libaio1 default-jre unzip binutils -y &>> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/os-update.log
  fi

  if [ ${IS_RH} == 1 ];then
    echo "yum upgrade -y"
    yum upgrade -y &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/os-update.log
    echo "yum install libaio unzip binutils tar net-tools -y"
    yum install libaio unzip binutils tar -y &>> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/os-update.log
    updateBashProfile
  fi
}
installDB2()
{
  printHeaderMessage "Installing DB2 (LOG  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/db2-install.log)"
  cd ${SOFTWARE_INSTALLS_DIR}/db2/
  echo "untar DB2 Install file ${DB2_INSTALL_FILE}"
  rm -fR ${DB2_SETUP_INSTALL_ROOT}
  tar xzvf ${DB2_INSTALL_FILE} 1>/dev/null
  DB2_RESPONSE_FILE=${DB2_SETUP_INSTALL_ROOT}/db2/linuxamd64/samples/db2server.rsp
  echo "Updating db2 response file - ${DB2_RESPONSE_FILE}"

  sed -i -e "s/DB2_INST.PASSWORD.*/DB2_INST.PASSWORD         = $DB_PASSWORD/g" ${DB2_RESPONSE_FILE}
  sed -i -e "s/DAS_PASSWORD.*/DB2_INST.PASSWORD         = $DB_PASSWORD/g" ${DB2_RESPONSE_FILE}
  sed -i -e "s/DB2_INST.FENCED_PASSWORD.*/DB2_INST.PASSWORD         = $DB_PASSWORD/g" ${DB2_RESPONSE_FILE}
  sed -i -e "s/DB2_INST.HOME_DIRECTORY.*/DB2_INST.HOME_DIRECTORY   = \/home\/${DB_ADMIN}/g" ${DB2_RESPONSE_FILE}
  sed -i -e "s/LIC_AGREEMENT.*/LIC_AGREEMENT             = ACCEPT/g" ${DB2_RESPONSE_FILE}
  sed -i -e "s/.*DB2_INST.TYPE.*/DB2_INST.TYPE             = ESE/g" ${DB2_RESPONSE_FILE}
  sed -i -e "s/.*DB2_INST.SVCENAME.*/DB2_INST.SVCENAME        = db2c_${DB_ADMIN} /g" ${DB2_RESPONSE_FILE}
  sed -i -e "s/.*DB2_INST.PORT_NUMBER .*/DB2_INST.PORT_NUMBER     = 50000/g" ${DB2_RESPONSE_FILE}
  sed -i -e "s/.*DB2_INST.FCM_PORT_NUMBER.*/DB2_INST.FCM_PORT_NUMBER = 60000/g" ${DB2_RESPONSE_FILE}
  sed -i -e "s/.*DB2_INST.MAX_LOGICAL_NODES.*/DB2_INST.MAX_LOGICAL_NODES = 4/g" ${DB2_RESPONSE_FILE}
  sed -i -e "s/.*DB2_INST.FENCED_HOME_DIRECTORY.*/DB2_INST.FENCED_HOME_DIRECTORY = \/home\/db2fenc1 /g" ${DB2_RESPONSE_FILE}
  sed -i -e "s/.*DB2_INST.CONFIGURE_TEXT_SEARCH.*/DB2_INST.CONFIGURE_TEXT_SEARCH = NO/g" ${DB2_RESPONSE_FILE}
  sed -i -e "s/.*DAS_USERNAME .*/DAS_USERNAME              = dasusr1/g" ${DB2_RESPONSE_FILE}
  sed -i -e "s/.*DAS_GROUP_NAME.*/DAS_GROUP_NAME            = dasadm1/g" ${DB2_RESPONSE_FILE}
  sed -i -e "s/.*DAS_HOME_DIRECTORY.*/DAS_HOME_DIRECTORY        = \/home\/dasusr1/g" ${DB2_RESPONSE_FILE}
  sed -i -e "s/.*DB2_INST.FENCED_USERNAME.*/DB2_INST.FENCED_USERNAME = db2fenc1/g" ${DB2_RESPONSE_FILE}
  sed -i -e "s/.*DB2_INST.FENCED_GROUP_NAME.*/DB2_INST.FENCED_GROUP_NAME = db2fadm1/g" ${DB2_RESPONSE_FILE}

  groupadd db2fadm1 2> /dev/null
  useradd -m db2fenc1 -p ${DB_PASSWORD} -g db2fadm1 2> /dev/null

  groupadd dasadm1 2> /dev/null
  useradd -m dasusr1 -p ${DB_PASSWORD} -g dasadm1 2> /dev/null

  #Run install with response file
  echo "${DB2_SETUP_INSTALL_ROOT}/db2setup -r ${DB2_RESPONSE_FILE}"
  echo "${BLUE_TEXT}INFO ${RESET_TEXT} PLease Wait this can take upto 5 mins ...... you can monitor via above log file - db2-install.log"
  ${DB2_SETUP_INSTALL_ROOT}/db2setup -r ${DB2_RESPONSE_FILE} &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/db2-install.log

}
prepareDB2FixPak()
{
  printHeaderMessage "Stopping all instances and prep for fixpak"
  su - ${DB_ADMIN} -c "db2 list application"
  su - ${DB_ADMIN} -c "db2 force applications all"
  su - ${DB_ADMIN} -c "db2 terminate"
  su - ${DB_ADMIN} -c "db2stop force"
  su - ${DB_ADMIN} -c "db2licd -end"
  su - ${DB_ADMIN} -c "db2set DB2_DEFERRED_PREPARE_SEMANTICS=YES"
  su - ${DB_ADMIN} -c "db2set DB2_COMPATIBILITY_VECTOR=ORA"
  su - ${DB_ADMIN} -c "db2set DB2COMM=TCPIP"
  su - ${DB_ADMIN} -c "db2set DB2AUTOSTART=YES"
  ${DB2_INSTALL_PATH}/instance/db2iauto -off ${DB_ADMIN}
  su - ${DB_ADMIN} -c "ipclean"
  su - ${DB_ADMIN} -c "${DB2_INSTALL_PATH}/das/bin/db2admin stop"

}
installDB2FixPak()
{
  printHeaderMessage "Installing DB2 Fixpak (LOG  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/db2-fixpak-install.log)"
  echo "DB2 Fixpak file - ${DB2_INSTALL_FIXPACK_FILE}"
  tar xvf ${DB2_INSTALL_FIXPACK_FILE} 1>/dev/null
  cd ${SOFTWARE_INSTALLS_DIR}/db2/universal
  ./installFixPack -n -b ${DB2_INSTALL_PATH}  -c ${SOFTWARE_INSTALLS_DIR}/db2/universal &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/db2-fixpak-install.log
}
upgradeDB2Instances()
{
  printHeaderMessage "Upgrade DB2 instance"
  echo "${DB2_INSTALL_PATH}/instance/db2iupdt ${DB_ADMIN} (LOG  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/db2-update-db2iupdt.log)"
  ${DB2_INSTALL_PATH}/instance/db2iupdt ${DB_ADMIN} &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/db2-update-db2iupdt.log
  echo "${DB2_INSTALL_PATH}/instance/db2iauto -on ${DB_ADMIN} (LOG ${LOG_DIR}/${PRODUCT_SHORT_NAME}/db2-update-db2iauto.log)"
  ${DB2_INSTALL_PATH}/instance/db2iauto -on ${DB_ADMIN} &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/db2-update-db2iauto.log
  su - ${DB_ADMIN} -c "db2start;db2level"
}

updateDB2Permission()
{
  printHeaderMessage "Fixing permissions"
  echo "chmod -fR 755 ${DB2_INSTALL_PATH}"
  chmod -fR 755 ${DB2_INSTALL_PATH}
}
setupDB2BootScripts()
{
  printHeaderMessage "Setting up Boot Scripts"
  if [ ${IS_RH} == 1 ];then
    cp ${DATA_DIR}/${PROJECT_NAME}/db2/templates/db2.rhel /etc/init.d/db2
    sed -i -e 's|.*DB2_INSTALL_PATH=.*|DB2_INSTALL_PATH='${DB2_INSTALL_PATH}'|g' /etc/init.d/db2
    chmod 755 /etc/init.d/db2
    echo "chkconfig --add db2"
    chkconfig --add db2
    echo "service db2 restart"
    service db2 restart
  fi

  if [ ${IS_UBUNTU} == 1 ];then
    echo "cp ${DATA_DIR}/${PROJECT_NAME}/db2/templates/db2.ubuntu /etc/init.d/db2"
    cp ${DATA_DIR}/${PROJECT_NAME}/db2/templates/db2.ubuntu /etc/init.d/db2
    chmod 755 /etc/init.d/db2
    echo "cp ${DATA_DIR}/${PROJECT_NAME}/db2/templates/db2.service /etc/systemd/system/db2.service"
    cp ${DATA_DIR}/${PROJECT_NAME}/db2/templates/db2.service /etc/systemd/system/db2.service
    chmod 644 /etc/systemd/system/db2.service
    #echo "update-rc.d db2 defaults 80 10"
    #update-rc.d db2 defaults 80 10
    echo "systemctl enable db2"
    systemctl enable db2
    #echo "/etc/init.d/db2 start"
    #/etc/init.d/db2 start
    #ln -s  /etc/init.d/db2 /etc/rc5.d/S02db2 &> /dev/null
    #ln -s  /etc/init.d/db2 /etc/rc6.d/S02db2 &> /dev/null
    #ln -s  /etc/init.d/db2 /etc/rc5.d/K02db2 &> /dev/null
    #ln -s  /etc/init.d/db2 /etc/rc6.d/K02db2 &> /dev/null
  fi
}
cleanDB2Install()
{
  printHeaderMessage "Cleanup"
  echo "rm -fR ${DB2_SETUP_INSTALL_ROOT}"
  rm -fR ${DB2_SETUP_INSTALL_ROOT}
  echo "rm -fR ${SOFTWARE_INSTALLS_DIR}/db2/universal"
  rm -fR ${SOFTWARE_INSTALLS_DIR}/db2/universal
}

displayDB2Info()
{
    printHeaderMessage "DB2 Connection Info"
    getBastionIP
    if [ ${IS_RH} == 1 ];then
        echo "DB2 Host:                 ${BASTION_HOST}"
        echo "DB2 ID:                   ${DB_ADMIN}"
        echo "DB2 Password:             ${DB_PASSWORD}"
    fi
    if [ ${IS_UBUNTU} == 1 ];then
      echo "DB2 Host:                 ${BASTION_HOST}"
      echo "DB2 ID:                   ${DB_ADMIN}"
      echo "DB2 Password:             ${DB_PASSWORD}"
    fi
    echo ""
    echo ""
}

disableDB2Firewall()
{
  if [ ${IS_RH} == 1 ];then
    local FIREWALL_NOT_RUNNING=`firewall-cmd --state 2>&1 | grep -c "not running"`
    if [  ${FIREWALL_NOT_RUNNING} -eq 0 ]; then
        printHeaderMessage "Open RedHat firewalld for DB2"
        echo "firewall-cmd --zone=public --add-port=${DB2_PORT}/tcp --permanent"
        firewall-cmd --zone=public --add-port=${DB2_PORT}/tcp --permanent 2>/dev/null
        echo "firewall-cmd --reload"
        firewall-cmd --reload
    fi
  fi
}
enableDB2Firewall()
{
  if [ ${IS_RH} == 1 ];then
    local FIREWALL_NOT_RUNNING=`firewall-cmd --state 2>&1 | grep -c "not running"`
    if [  ${FIREWALL_NOT_RUNNING} -eq 0 ]; then
        printHeaderMessage "Close RedHat firewalld for DB2"
        echo "firewall-cmd --zone=public --remove-port=${DB2_PORT}/tcp --permanent"
        firewall-cmd --zone=public --remove-port=${DB2_PORT}/tcp --permanent 2>/dev/null
        echo "firewall-cmd --reload"
        firewall-cmd --reload
    fi
  fi
}
validateDB2Version()
{
  variablePresent ${DB2_VERSION} DB2_VERSION
  if [ ${IS_RH} == 1 ];then
      case ${DB2_VERSION} in
         11.5)
            echo "${BLUE_TEXT}PASSED ${RESET_TEXT} Valid version DB2_VERSION=${DB2_VERSION}"
            ;;
         *)
           echo "${RED_TEXT}FAILED: Invalid version DB2_VERSION=${DB2_VERSION}${RESET_TEXT}"
           echo "${RED_TEXT}Current Supported Versions 11.5${RESET_TEXT}"
           echo ""
           echo ""
          echo "${RED_TEXT}Missing above required files/variables. Exiting Script!!!!!!!!!!!!!!!!!!!!!!${RESET_TEXT}"
           echo ""
           exit 99
           ;;
      esac
  fi
  if [ ${IS_UBUNTU} == 1 ];then
      case ${DB2_VERSION} in
         11.1)
            echo "${BLUE_TEXT}PASSED ${RESET_TEXT} Valid version DB2_VERSION=${DB2_VERSION}"
            ;;
         *)
           echo "${RED_TEXT}FAILED: Invalid version DB2_VERSION=${DB2_VERSION}${RESET_TEXT}"
           echo "${RED_TEXT}Current Supported Versions 11.1${RESET_TEXT}"
           echo ""
           echo ""
           echo "${RED_TEXT}Missing above required files/variables. Exiting Script!!!!!!!!!!!!!!!!!!!!!!${RESET_TEXT}"
           echo ""
           echo ""
           exit 99
           ;;
      esac
  fi
}
