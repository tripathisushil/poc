#!/bin/bash
############################################################
#Author           : Kyle Dawson
#Author email     : Kyle.Dawson@us.ibm.com
#Original Date    : 2022-02-04
#Current Version  : 1.0
############################################################
installSldap()
{
  printHeaderMessage "Install sldap"
  echo "Setup noninteractive install - DEBIAN_FRONTEND=noninteractive"
  export DEBIAN_FRONTEND="noninteractive"
  echo -e "slapd slapd/root_password password $LDAP_PASSWORD" |debconf-set-selections
  echo -e "slapd slapd/root_password_again password $LDAP_PASSWORD" |debconf-set-selections
  echo -e "slapd slapd/internal/adminpw password $LDAP_PASSWORD" |debconf-set-selections
  echo -e "slapd slapd/internal/generated_adminpw password $LDAP_PASSWORD" |debconf-set-selections
  echo -e "slapd slapd/password2 password $LDAP_PASSWORD" |debconf-set-selections
  echo -e "slapd slapd/password1 password $LDAP_PASSWORD" |debconf-set-selections
  echo -e "slapd slapd/domain string ibm.com" |debconf-set-selections
  echo -e "slapd shared/organization string IBM" |debconf-set-selections
  echo -e "slapd slapd/backend string HDB" |debconf-set-selections
  echo -e "slapd slapd/purge_database boolean true" |debconf-set-selections
  echo -e "slapd slapd/move_old_database boolean true" |debconf-set-selections
  echo -e "slapd slapd/allow_ldap_v2 boolean false" |debconf-set-selections
  echo -e "slapd slapd/no_configuration boolean false" |debconf-set-selections

  # Grab slapd and ldap-utils (pre-seeded)
  echo "Install ldap  - apt-get install -y slapd ldap-utils phpldapadmin"
  apt-get install -y slapd ldap-utils phpldapadmin >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/apt-get-Install.log 2>&1
  echo ""

  printHeaderMessage "Configure Base LDAP Tree"
  echo "ldapadd -x -D "${LDAP_BIND_DN_OPENLDAP}" -w $LDAP_PASSWORD  -c -H ldap:// -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/base.ldif"
  ldapadd -x -D "${LDAP_BIND_DN_OPENLDAP}" -w $LDAP_PASSWORD  -c -H ldap:// -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/base.ldif


}
uninstallOpenLDAP()
{
  printHeaderMessage "Removing LDAP" ${RED_TEXT}
  echo "apt-get remove --purge slapd ldap-utils -y"
  apt-get remove --purge slapd ldap-utils -y >> ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/apt-get-Uninstall.log 2>&1
}

displayOpenLDAPInfo()
{
  getBastionIP
  LDAP_BIND_DN=${LDAP_BIND_DN_OPENLDAP}
  printHeaderMessage "OpenLDAP Connection Info"
  echo "OpenLDAP Host          : ${BASTION_HOST}"
  echo "OpenLDAP Port          : 389"
  echo "Your new root ID       : ${LDAP_BIND_DN}"
  echo "Your new root password : $LDAP_PASSWORD"
  echo ""

}
