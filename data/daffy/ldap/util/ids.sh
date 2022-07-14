#!/bin/bash
############################################################
#Author           : Kyle Dawson
#Author email     : Kyle.Dawson@us.ibm.com
#Original Date    : 2022-02-04
#Current Version  : 1.0
############################################################
#IDS Info
############################################################
#https://www.ibm.com/software/reports/compatibility/clarity-reports/report/html/softwareReqsForProduct?deliverableId=1404412255415&osPlatforms=Linux&duComponentIds=S003|S001|S002|S004|A006|A007|A008|A005&mandatoryCapIds=30|12|9|13|25|32|26

installIDS()
{
  printHeaderMessage "Install IDS "
  echo "Mount ${SOFTWARE_INSTALLS_DIR}/ldap/${IDS_INSTALL_FILE} /mnt/iso/"
  mkdir /mnt/iso 2> /dev/null
  unmount /mnt/iso 2> /dev/null
  mount -t iso9660 -o loop ${SOFTWARE_INSTALLS_DIR}/ldap/${IDS_INSTALL_FILE} /mnt/iso/ 2> /dev/null

  #Setup ID/groups
  #################
  printHeaderMessage "Setup ID and Groups for IDS "
  echo "groupadd idsldap"
  groupadd idsldap

  echo "useradd -g idsldap -d /home/idsldap -m -s /bin/ksh idsldap -p ${LDAP_PASSWORD}"  >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ids-setup.log 2>&1
  useradd -g idsldap -d /home/idsldap -m -s /bin/ksh idsldap -p ${LDAP_PASSWORD} >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ids-setup.log 2>&1

  echo "usermod -a -G idsldap root"
  usermod -a -G idsldap root >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ids-setup.log 2>&1

  echo "groups root"
  groups root >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ids-setup.log 2>&1

  ## Skip db2 installation
  mkdir -p ${IDS_HOME}/install
  touch ${IDS_HOME}/install/IBMLDAP_INSTALL_SKIPDB2REQ

  printHeaderMessage "Install GSKit (LOG ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ids-install-gskit.log )"
  echo "rpm -Uhv /mnt/iso/ibm_gskit/gsk*linux.x86_64.rpm"
  rpm -Uhv /mnt/iso/ibm_gskit/gsk*linux.x86_64.rpm | tee ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ids-install-gskit.log

  printHeaderMessage "Install IDS rpms (LOG ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ids-install-rpm.log)"
  echo "/mnt/iso/license/idsLicense -q"
  /mnt/iso/license/idsLicense -q
  sleep 3
  echo "rpm --force -ihv /mnt/iso/images/idsldap*rpm"
  rpm --force -ihv /mnt/iso/images/idsldap*rpm &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ids-install-rpm.log

  printHeaderMessage "Install IDS (LOG ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ids-install.log )"
  cd ${SOFTWARE_INSTALLS_DIR}/ldap/
  echo "unzip -o ${SOFTWARE_INSTALLS_DIR}/ldap/${IDS_INSTALL_FEATURE_FILE}"
  unzip -o ${SOFTWARE_INSTALLS_DIR}/ldap/${IDS_INSTALL_FEATURE_FILE} &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ids-install.log
  echo "rpm --force -ihv ${SOFTWARE_INSTALLS_DIR}/ldap/sdsV6.4/entitlement/idsldap-ent64-6.4.0-0.x86_64.rpm"
  rpm --force -ihv ${SOFTWARE_INSTALLS_DIR}/ldap/sdsV6.4/entitlement/idsldap-ent64-6.4.0-0.x86_64.rpm &>> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ids-install.log
  sleep 3

  printHeaderMessage "Install IBM JDK  (LOG ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ids-install-jdk.log )"
  echo "tar -xf /mnt/iso/ibm_jdk/$IDS_JDK_FIXPACK} -C ${IDS_HOME}/"
  tar -xf /mnt/iso/ibm_jdk/$IDS_JDK_FIXPACK} -C ${IDS_HOME}/ &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ids-install-jdk.log

  printHeaderMessage "Setup DB2 Path"
  echo "echo -e currentDB2InstallPath=/opt/ibm/db2/V${DB2_VERSION}\n  >> ${IDS_HOME}/etc/ldapdb.properties"
  echo -e "currentDB2InstallPath=/opt/ibm/db2/V${DB2_VERSION}\n"  >> ${IDS_HOME}/etc/ldapdb.properties
  echo "echo -e currentDB2Version=${DB2_VERSION}.${DB2_MINOR_VERSION}\n >> ${IDS_HOME}/etc/ldapdb.properties"
  echo -e "currentDB2Version=${DB2_VERSION}.${DB2_MINOR_VERSION}\n" >> ${IDS_HOME}/etc/ldapdb.properties

  printHeaderMessage "Add IDS User (LOG ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ids-add-user.log)"
  ${IDS_HOME}/sbin/idsadduser -n -u ${LDAP_INSTANCE_USER_ID} -g grinst1 -w ${DB_PASSWORD} | tee ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ids-add-user.log
  sleep 3

  printHeaderMessage "Create instance (LOG ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ids-instance-setup.log )"
  echo "${IDS_HOME}/sbin/idsicrt -n -I ${LDAP_INSTANCE_USER_ID} -p 389 -s 636 -e misecretkee! -l /home/${LDAP_INSTANCE_USER_ID} -G grinst1 -w ${LDAP_PASSWORD}"
  ${IDS_HOME}/sbin/idsicrt -n -I ${LDAP_INSTANCE_USER_ID} -p 389 -s 636 -e misecretkee! -l /home/${LDAP_INSTANCE_USER_ID} -G grinst1 -w ${LDAP_PASSWORD} &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ids-instance-setup.log
  local IDS_INSTANCE_FAILED=`cat ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ids-instance-setup.log | grep -c "Failed" `
  if [ ${IDS_INSTANCE_FAILED} -ge 1 ]; then
    echo "${RED_TEXT}FATAL ${RESET_TEXT} Unable to create IDS instance."
    cat ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ids-instance-setup.log
    echo "Exiting Script!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo ""
    exit 99
  fi
  sleep 3

  printHeaderMessage "Configure a database for a directory server instance (LOG ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ids-createDB2Instance.log )"
  echo "${IDS_HOME}/sbin/idscfgdb -n -I ${LDAP_INSTANCE_USER_ID} -a ${LDAP_INSTANCE_USER_ID} -w ${LDAP_PASSWORD} -t ${LDAP_INSTANCE_USER_ID} -l /home/${LDAP_INSTANCE_USER_ID}"
  ${IDS_HOME}/sbin/idscfgdb -n -I ${LDAP_INSTANCE_USER_ID} -a ${LDAP_INSTANCE_USER_ID} -w ${LDAP_PASSWORD} -t ${LDAP_INSTANCE_USER_ID} -l /home/${LDAP_INSTANCE_USER_ID} &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ids-createDB2Instance.log
  local CREATE_DB_INSTANCE_ERROR=`cat ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ids-createDB2Instance.log | grep -c "G.*E " `
  if [ ${CREATE_DB_INSTANCE_ERROR} -ge 1 ]; then
    echo "${RED_TEXT}FATAL ${RESET_TEXT} Unable to Configure a database for a directory server instance."
    cat ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ids-createDB2Instance.log | grep "G.*E "
    echo "Exiting Script!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo ""
    exit 99
  fi
  sleep 3

  printHeaderMessage "Set the administration DN and administrative password for an instance"
  echo "${IDS_HOME}/sbin/idsdnpw -I ${LDAP_INSTANCE_USER_ID} –u ${LDAP_BIND_DN}  -q -n -p ${LDAP_PASSWORD}"
  ${IDS_HOME}/sbin/idsdnpw -I ${LDAP_INSTANCE_USER_ID} –u ${LDAP_BIND_DN}  -q -n -p ${LDAP_PASSWORD}
  sleep 3

  printHeaderMessage "Add suffix"
  echo "${IDS_HOME}/sbin/idscfgsuf -n -I ${LDAP_INSTANCE_USER_ID} -s ${LDAP_BASE_DN}"
  ${IDS_HOME}/sbin//idscfgsuf -n -I ${LDAP_INSTANCE_USER_ID} -s ${LDAP_BASE_DN}
  sleep 3

  printHeaderMessage "Setup Boot Scripts (LOG ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ids-bootscripts-setup.log )"
  cp  ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/os/ldap.rhel /etc/init.d/ldap
  chmod 755 /etc/init.d/ldap | tee  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ids-bootscripts-setup.log
  chkconfig --add ldap | tee  -a ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ids-bootscripts-setup.log
  service ldap restart  &>> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ids-bootscripts-setup.log

  printHeaderMessage "Add Base Values"
  sleep 5
  echo "${IDS_HOME}/bin/idsldapadd -c -D ${LDAP_BIND_DN} -w ${LDAP_PASSWORD} -i ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/base.ldif"
  ${IDS_HOME}/bin/idsldapadd -c -D ${LDAP_BIND_DN} -w ${LDAP_PASSWORD} -i ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/base.ldif

  #cleanup
  ###################
  rm -fR ${SOFTWARE_INSTALLS_DIR}/ldap/sdsV6.4/


}

uninstallIDS()
{
  #Stop LDAP
  ###########################
  printHeaderMessage "Stopping IDS Server"
  service ldap stop

  #Drop DB2 Instance for LDAP
  ###########################
  printHeaderMessage "Dropping DB2 instance - ${LDAP_INSTANCE_USER_ID} (LOG ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ids-dropdb2-instances.log )"
  ${IDS_HOME}/sbin/idsidrop -I ${LDAP_INSTANCE_USER_ID} -r -n &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ids-dropdb2-instances.log
  db2greg -delinstrec service=DB2,version=${DB2_VERSION}.${DB2_MINOR_VERSION},instancename=${LDAP_INSTANCE_USER_ID} &>> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ids-dropdb2-instances.log

  #Remove GSK
  ###########################
  printHeaderMessage "Removing gsk"
  rpm -e `rpm -qa | grep -i gsk`

  # Remove all the other rpm
  ###########################
  printHeaderMessage "Removing idsldap support RPMs (LOG ${LOG_DIR}/${PRODUCT_SHORT_NAME}/remove-idsldap-rpm.log )"
  rpm -ev `rpm -qa | grep -i idsldap` &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/remove-idsldap-rpm.log

  # Remove users
  ###########################
  printHeaderMessage "Cleanup Users/Groups"
  userdel -f ${LDAP_INSTANCE_USER_ID}
  rm -fR /home/${LDAP_INSTANCE_USER_ID}
  groupdel -f idsldap
  userdel -f idsldap
  rm -fR /home/idsldap

  # Clean files/directories
  ###########################
  printHeaderMessage "Cleanup Ldap directories"
  echo "rm -fR /opt/IBM/ldap"
  rm -fR /opt/IBM/ldap
  echo "rm -fR /opt/ibm/ldap"
  rm -fR /opt/ibm/ldap

  #Cleanup boot stuff
  ###########################
  printHeaderMessage "Cleanup boot scripts"
  echo "chkconfig --del ldap"
  chkconfig --del ldap
  echo "rm -fR /etc/init.d/ldap"
  rm -fR /etc/init.d/ldap

}

displayIDSLDAPInfo()
{
  printHeaderMessage "IDS LDAP Connection Info"
  getBastionIP
  LDAP_BIND_DN=${LDAP_BIND_DN_IDS}
  echo "OpenLDAP Host          : ${BASTION_HOST}"
  echo "OpenLDAP Port          : 389"
  echo "Your new root ID       : ${LDAP_BIND_DN}"
  echo "Your new root password : ${LDAP_PASSWORD}"
  echo ""
}
disableRHELFirewall()
{
  if [ ${IS_RH} == 1 ];then
    local FIREWALL_NOT_RUNNING=`firewall-cmd --state 2>&1 | grep -c "not running"`
    if [  ${FIREWALL_NOT_RUNNING} -eq 0 ]; then
        printHeaderMessage "Open RedHat firewalld for IDS(LDAP)"
        echo "firewall-cmd --zone=public --add-port=389/tcp --permanent"
        firewall-cmd --zone=public --add-port=389/tcp --permanent 2>/dev/null
        echo "firewall-cmd --reload"
        firewall-cmd --reload
    fi
  fi
}
enableRHELFirewall()
{
  if [ ${IS_RH} == 1 ];then
    local FIREWALL_NOT_RUNNING=`firewall-cmd --state 2>&1 | grep -c "not running"`
    if [  ${FIREWALL_NOT_RUNNING} -eq 0 ]; then
        printHeaderMessage "Close RedHat firewalld for IDS(LDAP)"
        echo "firewall-cmd --zone=public --remove-port=389/tcp --permanent"
        firewall-cmd --zone=public --remove-port=389/tcp --permanent 2>/dev/null
        echo "firewall-cmd --reload"
        firewall-cmd --reload
    fi
  fi
}
