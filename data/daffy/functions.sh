#!/bin/bash
############################################################
#Author           : Kyle Dawson
#Author email     : Kyle.Dawson@us.ibm.com
#Original Date    : 2021-08-15
#Initial Version  : v2021-12-01
############################################################
if [  "${PRODUCT_FUNCTION}"  !=  "master-build" ] && [  "${PRODUCT_FUNCTION}"  !=  "master-rebuild" ]; then
  echo "##########################################################################################################"
  echo "                              Running daffy ${PRODUCT_FUNCTION} process ${DAFFY_VERSION}"
  echo "##########################################################################################################"
fi
SCRIPT_START_TIME=`date`
echo "Start time : ${SCRIPT_START_TIME}"
#Setup to allow copy of files with out prompt if target exist
############################################################
alias cp=cp
alias rm=rm
ENV_FILE_NAME=$1

OS()
{
printHeaderMessage "Checking OS before continuing on"
OS=`find /etc | grep -c os-release`
  if [ $OS = 1 ]; then
    IS_UBUNTU=`cat /etc/*-release | grep ID | grep -c Ubuntu`
    IS_RH=`cat /etc/os-release | grep ID | grep -c rhel`
    CURRENT_NUMBER_OF_CPU=`lscpu | egrep '^CPU\(s\):' | awk '{print $2}'`
    CURRENT_SCRIPT_NAME=`basename "$0"`
    echo "Linux is being used"
    source ~/.profile 2> /dev/null
  else
    IS_MAC=`sw_vers | grep ProductName | awk '{print $2}' | grep -c macOS`
    echo "macOS is being used"
  fi
  if [ "$IS_MAC" == "1" ]; then
    MAC=true
  fi
}

#Common Variables
######################
#CURRENT_NUMBER_OF_CPU=`lscpu | egrep '^CPU\(s\):' | awk '{print $2}'`
#CURRENT_SCRIPT_NAME=`basename "$0"`
source ~/.profile 2> /dev/null

validOS()
{
  if  [ "${IS_UBUNTU}" == 0 ] && [ "${IS_RH}" == 0 ]; then
      SHOULD_EXIT=1
      OS_FLAVOR="${RED_TEXT}Unsupported OS${RESET_TEXT}"
      echo "${RED_TEXT}FAILED: Unsupported OS.  Script only supports Ubuntu or RHEL.${RESET_TEXT}"
      echo "Exiting Script!!!!!!!"
      exit 99
  fi
    if [ "${IS_UBUNTU}" == 1 ]; then
      UBUNTU_SUPPORTED=`cat /etc/os-release | grep VERSION_ID | grep -c 20.`
      UBUNTU_VERSION=`cat /etc/os-release | grep VERSION_ID |sed  -e 's/VERSION_ID\=//g' | sed  -e 's/\"//g'`
      OS_FLAVOR=`printenv 2> /dev/null | grep OS_FLAVOR | sed -e 's/OS_FLAVOR\=//g'`
      OS_INSTALL=apt-get
      if [ "${OS_FLAVOR}" != "macOS" ]; then
          OS_FLAVOR="ubuntu - ${UBUNTU_VERSION}"
      fi
    elif [ "${IS_RH}" == 1 ]; then
      RH_SUPPORTED=`cat /etc/os-release | grep VERSION_ID | grep -c 8.`
      RH_VERSION=`cat /etc/os-release | grep VERSION_ID | sed  -e 's/VERSION_ID\=//g' | sed  -e 's/\"//g'`
      OS_INSTALL=yum
      OS_FLAVOR="rhel - ${RH_VERSION}"
    fi
}

printHeaderMessage()
{
 echo ""
  if [  "${#2}" -ge 1 ] ;then
      echo "${2}${1}"
  else
      echo "${BLUE_TEXT}${1}"
  fi
  echo "################################################################${RESET_TEXT}"
  sleep 1
  if [ ${DEBUG} = "true" ] ;then
        read -p "Press [Enter] key to resume ..."
  fi

}

validateOpenShiftVersion()
{
   if [ "${OCP_VALIDATE_VERSION_SITE}" == "true" ]; then
       wget -S --spider "${OPENSHIFT_SITE_DOWNLOAD}/pub/openshift-v4/clients/ocp/${OCP_RELEASE}" >  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ocpVersionCheck.log 2>&1
       local GOOD_OCP_VERSION=`cat ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ocpVersionCheck.log | grep -c 'HTTP/1.1 200 OK'`
       if [ "${GOOD_OCP_VERSION}" !=  "1" ]; then
         echo "${RED_TEXT}Invalid version of OpenShift. ${OCP_RELEASE}${RESET_TEXT}"
         echo "You can look here for valid version - ${OPENSHIFT_SITE_DOWNLOAD}/pub/openshift-v4/clients/ocp/"
         SHOULD_EXIT=1
       else
         echo "${BLUE_TEXT}PASSED ${RESET_TEXT} Valid Version of OpenShift - ${OCP_RELEASE}"
       fi
   else
       echo "Skipping Validation because OCP_VALIDATE_VERSION_SITE=false" > ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ocpVersionCheck.log
       echo "SKIPPING: Validate Version of OpenShift - ${OCP_RELEASE}"
   fi
}
validOCPVersion()
{
  mkdir -p ${LOG_DIR}/${PRODUCT_SHORT_NAME}/
 if [[ "${CURRENT_SCRIPT_NAME}" == *build.sh ]];then
       if [ -n "${OCP_RELEASE}" ];then
              printHeaderMessage "Validate Version of OpenShift (LOG ->  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ocpVersionCheck.log)"
              validateOpenShiftVersion
              if [[ -n "${OCP_RELEASE}" ]]; then
                if [[ -z "${OCP_BASE_VERSION}" ]]; then
                  OCP_BASE_VERSION=`echo ${OCP_RELEASE} | sed "s/\.[0-9][0-9]$//g"`
                  OCP_BASE_VERSION_LENGTH=`echo $OCP_BASE_VERSION | wc -c`
                  if [[ ${OCP_BASE_VERSION_LENGTH} -gt 4 ]]; then
                    OCP_BASE_VERSION=`echo ${OCP_BASE_VERSION} | sed "s/\.[0-9]$//g"`
                  fi
                fi
              fi
              case ${OCP_BASE_VERSION} in
                4.6)
                    case ${CP4D_VERSION} in
                        4.0.*)
                            SHOULD_EXIT=1
                            echo "${RED_TEXT}FAILED ${RESET_TEXT} Unsupported version of OpenShift(${OCP_BASE_VERSION}) for CP4D ${CP4D_VERSION}. CP4D requirment not Daffy. "
                            echo "${RED_TEXT}FAILED ${RESET_TEXT} Cloud Paks currently only support OpenShift  - 4.8 "
                            ;;
                    esac
                    COREOS_ISO_IMAGE=${OCP_ISO_NAME_4_6}
                    OCP_NET_CONNECTION_PROFILE="Wired Connection"
                    OCS_OPERATOR_VERSION=${OCP_BASE_VERSION}
                    ;;
                4.7)
                    case ${PRODUCT_SHORT_NAME} in
                        ocp)
                            echo "${BLUE_TEXT}PASSED ${RESET_TEXT} OpenShift Valid ${OCP_BASE_VERSION}"
                            ;;
                        *)
                            SHOULD_EXIT=1
                            echo "${RED_TEXT}FAILED ${RESET_TEXT} Unsupported version of OpenShift(${OCP_BASE_VERSION}) for ${PRODUCT_SHORT_NAME}. This is a Cloud Pak requirment, not Daffy."
                            ;;
                    esac
                    COREOS_ISO_IMAGE=${OCP_ISO_NAME_4_7}
                    OCP_NET_CONNECTION_PROFILE="Wired connection 1"
                    OCS_OPERATOR_VERSION=${OCS_BASE_VERSION}
                    ;;
                4.8)
                    COREOS_ISO_IMAGE=${OCP_ISO_NAME_4_8}
                    OCP_NET_CONNECTION_PROFILE="Wired connection 1"
                    OCS_OPERATOR_VERSION=${OCP_BASE_VERSION}
                    ;;
                4.9)
                    case ${PRODUCT_SHORT_NAME} in
                        ocp|cp4ba)
                            echo "${BLUE_TEXT}PASSED ${RESET_TEXT} OpenShift Valid ${OCP_BASE_VERSION}"
                            ;;
                        *)
                            SHOULD_EXIT=1
                            echo "${RED_TEXT}FAILED ${RESET_TEXT} Unsupported version of OpenShift(${OCP_BASE_VERSION}) for ${PRODUCT_SHORT_NAME}. This is a Cloud Pak requirment, not Daffy."
                            ;;
                    esac
                    COREOS_ISO_IMAGE=${OCP_ISO_NAME_4_9}
                    OCP_NET_CONNECTION_PROFILE="Wired connection 1"
                    OCS_OPERATOR_VERSION=${OCS_OPERATOR_VERSION_4_9}
                    ;;
                4.10)
                    case ${PRODUCT_SHORT_NAME} in
                        ocp|cp4ba)
                            echo "${BLUE_TEXT}PASSED ${RESET_TEXT} Product  ${PRODUCT_SHORT_NAME} is supported for ${OCP_BASE_VERSION}"
                            ;;
                        *)
                            SHOULD_EXIT=1
                            echo "${RED_TEXT}FAILED ${RESET_TEXT} Unsupported version of OpenShift(${OCP_BASE_VERSION}) for ${PRODUCT_SHORT_NAME}. This is a Cloud Pak requirment, not Daffy."
                            ;;
                    esac
                    COREOS_ISO_IMAGE=${OCP_ISO_NAME_4_10}
                    OCP_NET_CONNECTION_PROFILE="Wired connection 1"
                    OCS_OPERATOR_VERSION=${OCS_OPERATOR_VERSION_4_10}
                    ;;
                *)
                    SHOULD_EXIT=1
                    echo "${RED_TEXT}FAILED: Unsupported version number(${OCP_BASE_VERSION}). Currently only supports - 4.6, 4.8, 4.9, or 4.10${RESET_TEXT}"
              esac
        else
            echo "${RED_TEXT}FAILED: Missing OCP_RELEASE variable or is blank. ${RESET_TEXT}"
        fi
        echo ""
 fi
}
isRootUser()
{
  if [ ${OS_NAME} == "Linux" ] ;then
    if [ "$EUID" -ne 0 ] ; then
      echo "${RED_TEXT}Please run as root!!!!!!"
      echo "${RED_TEXT}Exiting Script!!!!!!!${RESET_TEXT}"
      exit 99
    fi
  fi
}
resourcePresent()
{
  if [ ! -f ${1} ]; then
    SHOULD_EXIT=1
    echo "${RED_TEXT}FAILED ${RESET_TEXT} ${1} file does NOT exists!"
  fi
}
directoryPresent()
{
  if [ ! -d "${1}" ]; then
    SHOULD_EXIT=1
    echo "${RED_TEXT}FAILED ${RESET_TEXT} ${1} directory does NOT exists!"
  fi
}
variablePresent()
{
  if [[ -z "${2}" ]] ;then
    SHOULD_EXIT=1
    echo "${RED_TEXT}FAILED ${RESET_TEXT} ${1} Variable does NOT exists or is blank!"
  fi
}

userExist()
{
  USER_EXIST=`cat /etc/passwd | grep -c ${1}`
  if [ ${USER_EXIST} == 0 ] ;then
    SHOULD_EXIT=1
    echo "${RED_TEXT}FAILED ${RESET_TEXT} ${1} User does NOT exists!"
  fi
}


blinkWaitMessage()
{
    BLINK_MESSAGE_VALUE=${1}
    #SPACE_FROM_STRING="${BLINK_MESSAGE_VALUE//[^[:space:]]/ }"
    local SCREEN_WIDTH=`tput cols`
    local SPACE_FROM_STRING=""
    local LOOP_COUNT=2
    while [ ${LOOP_COUNT} -le ${SCREEN_WIDTH} ]
    do
        SPACE_FROM_STRING+=" "
        let LOOP_COUNT=LOOP_COUNT+1
    done
    #SPACE_FROM_STRING="                                                                                                                 "
    if [ -z "${2}" ]; then
        let BLINK_MESSAGE_WAIT_TIME=60/2
    else
        let BLINK_MESSAGE_WAIT_TIME=${2}/2
    fi

    for (( i=0;i<=${BLINK_MESSAGE_WAIT_TIME};i++))
    do
        #Below line will deleted the before printed line
        echo -en "\033[1A"
        echo -en "${BLINK_MESSAGE_VALUE}\n";
        sleep 1
        #Below line to print a blank line
        echo -en "\033[1A "
        echo -en "${SPACE_FROM_STRING}\n";
        sleep 1
    done
    #echo -en "${BLINK_MESSAGE_VALUE}\n";
    #echo -en "\033[1A"
    tput sgr0
}
preChecks()
{
  SHOULD_EXIT=0
  isRootUser
  validOS
}
validIPAddressNotInUse()
{
    if [[ "${CURRENT_SCRIPT_NAME}" == *build.sh ]];then
        IP_ADDRESS_AVAILIABLE=`ping ${1} -c 1 2> /dev/null | grep -c "ttl"`
        if [ "${IP_ADDRESS_AVAILIABLE}" == "1" ] ;then
          SHOULD_EXIT=1
          echo "${RED_TEXT}FAILED: ${2}(${1}) in use, IP needs to be unused. Please pick another IP.${RESET_TEXT}"
        else
          echo "${BLUE_TEXT}PASSED ${RESET_TEXT} ${2}(${1}) is an available current static IP."
        fi
    fi
}


validHostName()
{

  if [[ "${CURRENT_SCRIPT_NAME}" == *build.sh ]];then
      printHeaderMessage "Validate DNS entries"
      generateRandomString

      case ${OCP_INSTALL_TYPE} in
        *-upi)
              NOT_VALID_HOST_NAME=`ping api-int.${1}  -c 1 2>&1 | grep -c "service not known"`
              if [ "${NOT_VALID_HOST_NAME}"  ==  "1" ] ;then
                SHOULD_EXIT=1
                echo "${RED_TEXT}api-int.${1} DNS entry does NOT exists!!!!!!!${RESET_TEXT}"
              else
                  echo "${BLUE_TEXT}PASSED ${RESET_TEXT} api-int.${1} hostname is valid in DNS Server."
              fi
              ;;
        *)
              NOT_VALID_HOST_NAME=`ping console-openshift-console.apps.${1} -c 1 2>&1 | grep -c "service not known"`
              if [ "${NOT_VALID_HOST_NAME}"  ==  "1" ] ;then
                SHOULD_EXIT=1
                echo "${RED_TEXT}*.apps.${1} DNS entry does NOT exists!!!!!!${RESET_TEXT}"
              else
                echo "${BLUE_TEXT}PASSED ${RESET_TEXT} *.apps.${1} hostname is valid in DNS Server."
              fi
              NOT_VALID_HOST_NAME=`ping api.${1} -c 1 2>&1 | grep -c "service not known"`
              if [ "${NOT_VALID_HOST_NAME}"  ==  "1" ] ;then
                SHOULD_EXIT=1
                echo "${RED_TEXT}api.${1} DNS entry does NOT exists!!!!!!${RESET_TEXT}"
              else
                echo "${BLUE_TEXT}PASSED ${RESET_TEXT} api.${1} hostname is valid in DNS Server."
              fi
              ;;
      esac
      echo ""
  fi
}

validPullSecret()
{
  check=${#1}
  if [ $check -le 50 ]; then
    SHOULD_EXIT=1
    echo "${RED_TEXT} Pull secret does not look valid OR IS blank.${RESET_TEXT}"
    echo "${RED_TEXT}${1} ${RESET_TEXT}"
  fi
}

getSSHPublicKey()
{
  printHeaderMessage "SSH Public Key"
  if [ ! -f ${SSH_KEY_FILE}.pub ]
  then
    echo "${BLUE_TEXT} ${1} SSH Publc Key does NOT exists, creating new one!${RESET_TEXT}"
    ssh-keygen -b 4096 -t rsa -f ${SSH_KEY_FILE} -N ""
  fi
  #cat ${SSH_KEY_FILE} >> ~/.ssh/authorized_keys
  SSH_KEY=`cat ${SSH_KEY_FILE}.pub`
  eval "$(ssh-agent -s)"
  ssh-add ${SSH_KEY_FILE}
  echo ""

}
prepareHost()
{
  printHeaderMessage "Prepare host (LOG -> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/${OS_INSTALL}.log )"
  mkdir -p ${LOG_DIR}/${PRODUCT_SHORT_NAME}
  if [[ ":$PATH:" == *"/usr/local/bin:"* ]]; then
      echo "${BLUE_TEXT}PASSED ${RESET_TEXT} Your path has /usr/local/bin"
  else
      echo "${RED_TEXT}FATAL ${RESET_TEXT} Your path is missing /usr/local/bin"
      echo "${RED_TEXT}Exiting Script!!!!!!!!!!!!!!!!!!!${RESET_TEXT}"
      echo ""
      echo ""
      echo ""
      exit 99
  fi
  echo "${RESET_TEXT}running update  - ${OS_INSTALL} -y update"
  $OS_INSTALL -y update > ${LOG_DIR}/${PRODUCT_SHORT_NAME}/${OS_INSTALL}.log 2>&1
  echo "${RESET_TEXT}running upgrade - ${OS_INSTALL} -y upgrade"
  $OS_INSTALL -y upgrade  >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/${OS_INSTALL}.log 2>&1
  if [ ${IS_UBUNTU} == 1 ]; then
    echo "${RESET_TEXT}running install - nmon net-tools curl nano vim tree wget unzip jq expect apache2-utils dnsutils openssh-client"
    $OS_INSTALL install -y vim unzip nmon net-tools curl nano tree wget jq expect apache2-utils dnsutils openssh-client git >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/${OS_INSTALL}.log
  elif [ ${IS_RH} ==  1 ]; then
     updateBashProfile
     echo "${RESET_TEXT}running install - nmon net-tools bind-utils curl nano vim tree wget unzip jq expect httpd-tools"
     $OS_INSTALL install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/${OS_INSTALL}.log 2>&1
     $OS_INSTALL install -y nmon net-tools bind-utils curl nano vim tree wget unzip jq expect httpd-tools git >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/${OS_INSTALL}.log 2>&1
  fi
  if [ "${OCP_INSTALL_TYPE}"  ==  "kvm-upi" ] && [ "${PRODUCT_SHORT_NAME}"  ==  "ocp" ] && [ ${IS_UBUNTU} == "1" ] ;then
      echo "${RESET_TEXT}(KVM Virutal Tools) running install - lvm2 bridge-utils qemu-kvm virtinst libvirt-daemon virt-manager cifs-utils libosinfo-bin bridge-utils uvtool"
      apt-get install -y lvm2 bridge-utils qemu-kvm virtinst libvirt-daemon virt-manager cifs-utils libosinfo-bin bridge-utils uvtool  >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/apt-get.log
      echo "${RESET_TEXT}Start libvirtd - systemctl enable libvirtd; systemctl start libvirtd${RED_TEXT}"
      systemctl enable libvirtd; systemctl start libvirtd
      echo ${RESET_TEXT}"cofig libirtd  -  uvt-simplestreams-libvirt --verbose sync release=bionic arch=amd64"
      uvt-simplestreams-libvirt --verbose sync release=bionic arch=amd64
  fi
  local OS_FAILED_UPDATE=`cat ${LOG_DIR}/${PRODUCT_SHORT_NAME}/${OS_INSTALL}.log | grep -c "E:\|Error\|Fatal\|not registered\|You no longer have access to the repositories"`
  if [ ${OS_FAILED_UPDATE} -ge 1 ]; then
    echo "${RED_TEXT}FAILED ${RESET_TEXT} Error detected during  $OS_INSTALL update/upgrade/install."
    echo "Please check log for details and correct or try again."
    echo "LOG --> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/${OS_INSTALL}.log"
    SHOULD_EXIT=1
  fi
  if [ "${OCP_INSTALL_TYPE}"  ==  "kvm-upi" ] && [ "${PRODUCT_SHORT_NAME}"  ==  "ocp" ] && [ ${IS_RH} == "1" ] ;then
      echo "${RED_TEXT}FAILED Unsupported bastion OS for ${OCP_INSTALL_TYPE}. Only Ubuntu is supported"
      SHOULD_EXIT=1
  fi
  echo "${RESET_TEXT}"
}
createNetwork()
{
  printHeaderMessage "Create Network"
  echo "virsh net-define ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/virsh/net_ocp.xml"
  virsh net-define ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/virsh/net_ocp.xml
  echo "virsh net-autostart ocp"
  virsh net-autostart ocp
  echo "virsh net-start ocp"
  virsh net-start ocp
  echo ""
}
createDNSDHCPPXE()
{
  printHeaderMessage "Create DNS (LOG ->  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/dns-install.log )"
  if [ "${DNSMASQ_BUILD}" == "true" ];then
        echo "Enable dnsmasq"
        echo "Running install -  dnsmasq  "
        ${OS_INSTALL} install -y  dnsmasq   > ${LOG_DIR}/${PRODUCT_SHORT_NAME}/dns-install.log
        systemctl enable dnsmasq; systemctl start dnsmasq
        echo "cp ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/dnsmasq/dnsmasq.conf   /etc/dnsmasq.conf"
        cp ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/dnsmasq/dnsmasq.conf   /etc/dnsmasq.conf
        cp ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/dnsmasq/daffy.dnsmasq.sh  /etc/init.d/ > /dev/null 2>&1
        chmod 755 /etc/init.d/daffy.dnsmasq.sh
        ln -s  /etc/init.d/daffy.dnsmasq.sh /etc/rc5.d/S02daffy.dnsmasq > /dev/null 2>&1
        ln -s  /etc/init.d/daffy.dnsmasq.sh /etc/rc6.d/S02daffy.dnsmasq > /dev/null 2>&1
        echo "cp ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/dnsmasq/${VM_TSHIRT_SIZE}/cluster.conf  /etc/dnsmasq.d/cluster.conf"
        cp ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/dnsmasq/${VM_TSHIRT_SIZE}/cluster.conf  /etc/dnsmasq.d/cluster.conf

        case ${OCP_INSTALL_TYPE} in
         kvm-upi)
             printHeaderMessage "Enable ipxe and DCP (LOG ->  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ipx-install.log )"
             echo "Enable ipxe"
             echo "Running install -  ipxe "
             apt-get install -y ipxe  > ${LOG_DIR}/${PRODUCT_SHORT_NAME}/dns-ipx-install.log
             mkdir -p /var/lib/tftp
             cp /usr/lib/ipxe/{undionly.kpxe,ipxe.efi} /var/lib/tftp
             chown dnsmasq:nogroup /var/lib/tftp/*
             ;;
         vsphere-upi)
              echo "Remove DHCP Features from dnsmasq"
              sed -i'' "s/dhcp-.*//g" /etc/dnsmasq.conf
              sed -i'' "s/enable-tftp.*//g" /etc/dnsmasq.conf
              sed -i'' "s/tftp-.*//g" /etc/dnsmasq.conf
              sed -i'' "s/dhcp-.*//g" /etc/dnsmasq.d/cluster.conf
              echo "For DNS, listen to all interfaces"
              sed -i'' "s/interface=.*//g" /etc/dnsmasq.conf
              #Remove blank lines
              sed -i '/^$/d' /etc/dnsmasq.conf
              sed -i '/^[[:space:]]*$/d' /etc/dnsmasq.conf
              sed -i '/^$/d' /etc/dnsmasq.d/cluster.conf
              sed -i '/^[[:space:]]*$/d' /etc/dnsmasq.d/cluster.conf
              ;;
       esac

        echo "Restarting dnsmasq"
        systemctl restart dnsmasq

        NETPLAN_UPDATE_BOND0=`netplan get | grep -c bond0:`
        if [ "${NETPLAN_UPDATE_BOND0}" = "1" ] ;then
          echo 'netplan Update ethernets.bond0.nameservers.addresses=["127.0.0.1"]'
          netplan set bonds.bond0.nameservers.addresses=["127.0.0.1"]
        fi
        NETPLAN_UPDATE_BOND1=`netplan get | grep -c bond1:`
        if [ "${NETPLAN_UPDATE_BOND1}" = "1" ] ;then
          echo 'netplan Update ethernets.bond1.nameservers.addresses=["127.0.0.1"]'
          netplan set bonds.bond1.nameservers.addresses=["127.0.0.1"]
        fi
        netplan apply
        #/etc/systemd/resolved.conf. Set the value of DNS in the Resolve section to 127.0.0.1.
        sed -i'' -e 's/#DNS=.*/DNS=127.0.0.1/g' /etc/systemd/resolved.conf
        sed -i'' -e 's/DNS=.*/DNS=127.0.0.1/g' /etc/systemd/resolved.conf
        systemctl restart systemd-resolved
  else
        echo "Will not build dnsmasq, flag not set to true, DNSMASQ_BUILD=${DNSMASQ_BUILD}"
        echo "Since we will not build dns, you must have setup dns for entire cluster prior to install."
        echo "Here is what you should have built:"
        displayOCPDNSRequirements
  fi
  echo ""
}
matchBox()
{
  printHeaderMessage "Install and setup Matchbox"
  cd ${TEMP_DIR}/${PRODUCT_SHORT_NAME}
  local MATCHBOX_VERSION_RESULT=`matchbox --version 2> /dev/null`
  if [ "${MATCHBOX_VERSION_RESULT}" !=  "${MATCHBOX_VERSION}" ]; then
      echo "Downloading matchbox - https://github.com/poseidon/matchbox/releases/download/${MATCHBOX_VERSION}/matchbox-${MATCHBOX_VERSION}-linux-amd64.tar.gz${RESET_TEXT}"
      wget https://github.com/poseidon/matchbox/releases/download/${MATCHBOX_VERSION}/matchbox-${MATCHBOX_VERSION}-linux-amd64.tar.gz 2> /dev/null
      if [ ! -f matchbox-${MATCHBOX_VERSION}-linux-amd64.tar.gz ]; then
        echo "${RED_TEXT}Failed to download matchbox, unable to continue:"
        echo "https://github.com/poseidon/matchbox/releases/download/${MATCHBOX_VERSION}/matchbox-${MATCHBOX_VERSION}-linux-amd64.tar.gz${RESET_TEXT}"
        echo "${RED_TEXT}Exiting Script!!!!!!!${RESET_TEXT}"
        exit 99
      fi
      tar zxvf matchbox-${MATCHBOX_VERSION}-linux-amd64.tar.gz > /dev/null
      cd matchbox-${MATCHBOX_VERSION}-linux-amd64
      cp matchbox /usr/local/bin/
      cp contrib/systemd/matchbox-local.service /etc/systemd/system/matchbox.service
  else
    echo "Matchbox version ${MATCHBOX_VERSION} already exist, will not download"
  fi
  echo "Create matchbox user - matchbox"
  useradd -U matchbox
  mkdir -p /var/lib/matchbox/{assets,groups,ignition,profiles}
  echo "Start matchbox service"
  systemctl enable matchbox; systemctl start matchbox
  mkdir -p /var/lib/matchbox/assets/ocp${OCP_BASE_VERSION}
  cd /var/lib/matchbox/assets/ocp${OCP_BASE_VERSION}
  RHCOS_SOURCE_URL="${OPENSHIFT_SITE_DOWNLOAD}/pub/openshift-v4/dependencies/rhcos/${OCP_BASE_VERSION}/latest/"
  MATCHBOX_RHOS_FILE1=rhcos-live-initramfs.x86_64.img
  MATCHBOX_RHOS_FILE2=rhcos-live-kernel-x86_64
  MATCHBOX_RHOS_FILE3=rhcos-live-rootfs.x86_64.img
  if [ ! -f ${MATCHBOX_RHOS_FILE1} ] || [ ! -f  ${MATCHBOX_RHOS_FILE2} ] ||  [ ! -f ${MATCHBOX_RHOS_FILE3} ] ;then
      echo "Downloading Redhat coreOS images from  ${RHCOS_SOURCE_URL} to /var/lib/matchbox/assets/${OCP_BASE_VERSION} "
      wget ${OPENSHIFT_SITE_DOWNLOAD}/pub/openshift-v4/dependencies/rhcos/${OCP_BASE_VERSION}/latest/${MATCHBOX_RHOS_FILE1}  2> /dev/null
      wget ${OPENSHIFT_SITE_DOWNLOAD}/pub/openshift-v4/dependencies/rhcos/${OCP_BASE_VERSION}/latest/${MATCHBOX_RHOS_FILE2}  2> /dev/null
      wget ${OPENSHIFT_SITE_DOWNLOAD}/pub/openshift-v4/dependencies/rhcos/${OCP_BASE_VERSION}/latest/${MATCHBOX_RHOS_FILE3}  2> /dev/null
      if [ ! -f ${MATCHBOX_RHOS_FILE1} ] || [ ! -f  ${MATCHBOX_RHOS_FILE2} ] ||  [ ! -f ${MATCHBOX_RHOS_FILE3} ] ;then
        echo "${RED_TEXT}FATAL ERROR : ############# Missing Matchbox Asset files unable to download  ################################################${RESET_TEXT}"
        echo "${RED_TEXT}Source       :  ${RHCOS_SOURCE_URL}${RESET_TEXT} "
        echo "${RED_TEXT}Missing file 1:  /var/lib/matchbox/assets/ocp/${OCP_BASE_VERSION}/${MATCHBOX_RHOS_FILE1}${RESET_TEXT}"
        echo "${RED_TEXT}Missing file 2:  /var/lib/matchbox/assets/ocp${OCP_BASE_VERSION}/${MATCHBOX_RHOS_FILE2}${RESET_TEXT}"
        echo "${RED_TEXT}Missing file 3:  /var/lib/matchbox/assets/ocp${OCP_BASE_VERSION}/${MATCHBOX_RHOS_FILE3}${RESET_TEXT}"
        echo "${RED_TEXT}FATAL ERROR : #############  Missing Matchbox Asset files unable to download ################################################${RESET_TEXT}"
        echo "${RED_TEXT}Exiting Script!!!!!!!${RESET_TEXT}"
        exit 99
      fi
  else
     echo "Redhat coreOS images already exist in /var/lib/matchbox/assets/ocp${OCP_BASE_VERSION}, will not download."
  fi
  echo "Copying coreOS images from /var/lib/matchbox/assets/ocp${OCP_BASE_VERSION} /var/lib/matchbox/assets/"
  cp -fR ${MATCHBOX_RHOS_FILE1} ${MATCHBOX_RHOS_FILE2} ${MATCHBOX_RHOS_FILE3}  /var/lib/matchbox/assets
  echo "Coping matchbox profiles and groups from  ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/matchbox to /var/lib/matchbox"
  cp -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/matchbox/profiles/*.json /var/lib/matchbox/profiles/
  cp -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/matchbox/groups/*.json /var/lib/matchbox/groups/
  if [ "${VM_TSHIRT_SIZE}" == "Min" ] ;then
      rm -fr /var/lib/matchbox/groups/worker4.json
      rm -fr /var/lib/matchbox/groups/worker5.json
      rm -fr /var/lib/matchbox/groups/worker6.json
      rm -fr /var/lib/matchbox/groups/worker7.json
      rm -fr /var/lib/matchbox/groups/worker8.json
      rm -fr /var/lib/matchbox/groups/worker9.json
  fi
  chown -R matchbox:matchbox /var/lib/matchbox
  rm -fR matchbox-${MATCHBOX_VERSION}-linux-amd64* > /dev/null 2>&1
  echo ""
}
createIgnitionFilesMatchBox()
{
  printHeaderMessage "Create Ignition Files for Matchbox"
  OPENSHFIT_INSTALL_DIR=${TEMP_DIR}/${PRODUCT_SHORT_NAME}/ocp-install
  mkdir -p ${OPENSHFIT_INSTALL_DIR}
  cd ${OPENSHFIT_INSTALL_DIR}
  cp ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/install-config.yaml ${OPENSHFIT_INSTALL_DIR}
  createManifestFiles
  openshift-install create ignition-configs
  cp -f *.ign /var/lib/matchbox/ignition/
  chmod +r /var/lib/matchbox/ignition/*
  systemctl restart matchbox
  cd ${TEMP_DIR}/${PRODUCT_SHORT_NAME}
  echo ""
}

installHAProxy()
{
  echo "Installing - ${OS_INSTALL} -y install haproxy"
  ${OS_INSTALL} -y install haproxy  1> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/haproxy-install.log
}
installLoadBalancer()
{
  case ${OCP_INSTALL_TYPE} in
    *-upi)
          printHeaderMessage "Create Load Balancer (LOG -> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/haproxy-install.log )"
          if [ "${HAPROXY_BUILD}" == "true" ];then
              installHAProxy
              echo "Copy config - cat ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/haproxy/${VM_TSHIRT_SIZE}/haproxy.cfg  >> /etc/haproxy/haproxy.cfg"
              cat ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/haproxy/${VM_TSHIRT_SIZE}/haproxy.cfg  >> /etc/haproxy/haproxy.cfg
              echo "Starting haproxy service"  >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/haproxy-install.log
              systemctl restart haproxy >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/haproxy-install.log
              echo "You can view haproxy stats here:  ${BLUE_TEXT}http://${BASTION_HOST}:9000/stats${RESET_TEXT}"
          else
             echo "Will not build haproxy because flag was not true. HAPROXY_BUILD=${HAPROXY_BUILD}"
             echo "Since we will not build load balancer, you must have set this up for entire cluster prior to install."
             echo "Here is what you should have built:"
             echo "Sample HAProxy - ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/haproxy/${VM_TSHIRT_SIZE}/haproxy.cfg "
          fi
    ;;
  esac
  echo ""

}

createNFSServerLocal()
{
    if [ "${IS_UBUNTU}" == 1 ] || [ "${IS_RH}" == 1 ] ; then
      if [ "${IS_UBUNTU}" == 1 ]; then
        echo "${OS_INSTALL} install -y nfs-kernel-server nfs-common" | tee ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/nfs-server-setup.log
        ${OS_INSTALL} install -y nfs-kernel-server nfs-common >>  ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/nfs-server-setup.log 2>&1
      fi
      if [ "${IS_RH}" == 1 ]; then
        echo "${OS_INSTALL} install -y nfs-utils" | tee ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/nfs-server-setup.log
        ${OS_INSTALL} install -y nfs-utils >>  ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/nfs-server-setup.log 2>&1
      fi
      mkdir ${NFS_FILE_SYSTEM} -p >> ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/nfs-server-setup.log  2>&1
      chown nobody:nogroup ${NFS_FILE_SYSTEM} >> ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/nfs-server-setup.log  2>&1
      exportfs -r | tee >> ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/nfs-server-setup.log
      echo "Create export - ${NFS_FILE_SYSTEM}"  | tee -a  ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/nfs-server-setup.log
      echo "${NFS_FILE_SYSTEM}    *(rw,sync,no_subtree_check,no_wdelay,no_root_squash)"  | sed 's/\\//g' >>  ${NFS_EXPORTS}
      if [ "${IS_UBUNTU}" == 1 ]; then
        echo "Restart nfs-kernel-server" | tee -a ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/nfs-server-setup.log
        systemctl restart nfs-kernel-server >>  ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/nfs-server-setup.log
      fi
      if [ "${IS_RH}" == 1 ]; then
        echo "Enable nfs-server rpcbind" | tee -a ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/nfs-server-setup.log
        systemctl enable --now nfs-server rpcbind >>  ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/nfs-server-setup.log
      fi
    else
      echo "${RED_TEXT}FAILED ${RESET_TEXT} Unsuported OS for NFS. Only supports Ubuntu or RHEL"
    fi
}
createNFSServerLocalVM()
{
  echo "  uvt-kvm create nfs-server release=bionic --ssh-public-key-file ${SSH_KEY_FILE}.pub --memory 4096 --cpu 2 --disk 150 --bridge br-ocp"
  uvt-kvm create nfs-server release=bionic --ssh-public-key-file ${SSH_KEY_FILE}.pub --memory 4096 --cpu 2 --disk 150 --bridge br-ocp
  echo ""
  blinkWaitMessage "Waiting for NFS VM to boot up - 60 seconds" 60
  NFS_VM_IP_ADDRESS=`cat /var/lib/misc/dnsmasq.leases | grep ubuntu | awk '{print $3}'`
  echo "Configure KVM to host NFS Server"
  ssh -oStrictHostKeyChecking=no -i ${SSH_KEY_FILE} ubuntu@${NFS_VM_IP_ADDRESS} sudo "apt-get update"  >> ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/nfs-server-setup.log  2>&1
  ssh -oStrictHostKeyChecking=no -i ${SSH_KEY_FILE} ubuntu@${NFS_VM_IP_ADDRESS} sudo "apt-get install -y nfs-kernel-server" >> ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/nfs-server-setup.log  2>&1
  ssh -oStrictHostKeyChecking=no -i ${SSH_KEY_FILE} ubuntu@${NFS_VM_IP_ADDRESS} sudo "mkdir ${NFS_FILE_SYSTEM} -p" >> ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/nfs-server-setup.log  2>&1
  ssh -oStrictHostKeyChecking=no -i ${SSH_KEY_FILE} ubuntu@${NFS_VM_IP_ADDRESS} sudo "chown nobody:nogroup ${NFS_FILE_SYSTEM}" >> ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/nfs-server-setup.log  2>&1
  ssh -oStrictHostKeyChecking=no -i ${SSH_KEY_FILE} ubuntu@${NFS_VM_IP_ADDRESS} sudo "cat ${NFS_EXPORTS}" > ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/exports >> ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/nfs-server-setup.log  2>&1
  echo "${NFS_FILE_SYSTEM}    *(rw,sync,no_subtree_check,no_wdelay,no_root_squash)"  | sed 's/\\//g' >>  ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/exports
  scp -oStrictHostKeyChecking=no -i ${SSH_KEY_FILE} ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/exports ubuntu@${NFS_VM_IP_ADDRESS}:/tmp >> ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/nfs-server-setup.log  2>&1
  ssh -oStrictHostKeyChecking=no -i ${SSH_KEY_FILE} ubuntu@${NFS_VM_IP_ADDRESS} sudo "cp -fR /tmp/exports ${NFS_EXPORTS}" >> ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/nfs-server-setup.log  2>&1
  ssh -oStrictHostKeyChecking=no -i ${SSH_KEY_FILE} ubuntu@${NFS_VM_IP_ADDRESS} sudo "systemctl restart nfs-kernel-server" >> ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/nfs-server-setup.log  2>&1

}
createNFSServer()
{
  printHeaderMessage "Create NFS Server (LOG -> ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/nfs-server-setup.log )"
  case ${OCP_INSTALL_TYPE} in
    vsphere-upi|*-ipi|*-msp)
          createNFSServerLocal
          sed -i'' "s/@NFS_IP_ADDRESS@/$BASTION_HOST/g" ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/nfs/deployment.yaml
          exportfs -a
          ;;
    kvm-upi)
          createNFSServerLocalVM
          sed -i'' "s/@NFS_IP_ADDRESS@/$NFS_VM_IP_ADDRESS/g" ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/nfs/deployment.yaml
          ;;
  esac

  validateOCPAccess
  cd ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/nfs
  oc new-project nfs-fs >> ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/nfs-server-setup.log  2>&1
  oc create -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/nfs/rbac.yaml
  oc adm policy add-scc-to-user hostmount-anyuid system:serviceaccount:nfs-fs:nfs-client-provisioner
  oc create -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/nfs/deployment.yaml
  oc create -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/nfs/class.yaml
  if [[ "${OCP_INSTALL_TYPE}" != *"-msp" ]]; then
    oc patch configs.imageregistry.operator.openshift.io/cluster --type merge -p '{"spec":{"managementState": "Managed"}}'
    oc patch configs.imageregistry.operator.openshift.io/cluster --type merge -p '{"spec":{"storage": {"pvc": {"claim": "image-registry-pvc"}}}}'
    echo  ""
    LOOP_COUNT=0
    IMAGE_REGISTRY_READY=`oc get clusteroperators | grep image-registry| awk '{print $3}'`
    while [ "${IMAGE_REGISTRY_READY}" =  "False" ]
    do
      echo -en "\033[1A"
      sleep 1
      blinkWaitMessage "Waiting for image-registry" 10
      IMAGE_REGISTRY_READY=`oc get clusteroperators | grep image-registry| awk '{print $3}'`
      let  LOOP_COUNT=LOOP_COUNT+1
      if [ $LOOP_COUNT -ge 30 ] ;then
        echo ""
        echo "${RED_TEXT}image-registry is not ready"
        echo "######################################################${RESET_TEXT}"
        echo "After configuring storage for image-registry, it is not in healty state."
        echo "Will continue with install, but you should reslove after cluster is up."
        echo ""
        break
      fi
    done
  fi
  echo ""
}

resetPublicDNSAddress()
{
    if [[ -n ${ORIGINAL_DNS_SERVERS} ]]; then
      printHeaderMessage "Reset Local DNS Server lookup" ${RED_TEXT}
      NETPLAN_UPDATE_BOND0=`netplan get | grep -c bond0:`
      if [ "${NETPLAN_UPDATE_BOND0}" = "1" ] ;then
        echo "netplan Update ethernets.bond0.nameservers.addresses=["${ORIGINAL_DNS_SERVERS}"]"
        netplan set bonds.bond0.nameservers.addresses=["${ORIGINAL_DNS_SERVERS}"]
      fi
      NETPLAN_UPDATE_BOND1=`netplan get | grep -c bond1:`
      if [ "${NETPLAN_UPDATE_BOND1}" = "1" ] ;then
        echo "netplan Update ethernets.bond1.nameservers.addresses=["${ORIGINAL_DNS_SERVERS}"]"
        netplan set bonds.bond1.nameservers.addresses=["${ORIGINAL_DNS_SERVERS}"]
      fi
      NETPLAN_UPDATE_ETH0=`netplan get | grep -c eth0:`
      if [ "${NETPLAN_UPDATE_ETH0}" = "1" ] ;then
        echo "netplan Update ethernets.eth0.nameservers.addresses=["${ORIGINAL_DNS_SERVERS}"]"
        netplan set ethernets.eth0.nameservers.addresses=["${ORIGINAL_DNS_SERVERS}"]
      fi
      NETPLAN_UPDATE_ETH1=`netplan get | grep -c eth1:`
      if [ "${NETPLAN_UPDATE_ETH1}" = "1" ] ;then
        echo "netplan Update ethernets.eth1.nameservers.addresses=["${ORIGINAL_DNS_SERVERS}"]"
        netplan set ethernets.eth1.nameservers.addresses=["${ORIGINAL_DNS_SERVERS}"]
      fi
      NETPLAN_UPDATE_ETH160=`netplan get | grep -c eth160:`
      if [ "${NETPLAN_UPDATE_ETH160}" = "1" ] ;then
        echo "netplan Update ethernets.eth160.nameservers.addresses=["${ORIGINAL_DNS_SERVERS}"]"
        netplan set ethernets.eth160.nameservers.addresses=["${ORIGINAL_DNS_SERVERS}"]
      fi
      netplan apply
      rm -fR /tmp/netplan_* 2> /dev/null
      echo ""
    fi
}


deleteBootstrapVMs()
{

  printHeaderMessage "Removing bootstrap resources" ${RED_TEXT}
  if [ ${OCP_KEEP_BOOTSTRAP} = "false" ] ;then
    if [ "${OCP_INSTALL_TYPE}"  ==  "vsphere-upi" ] ;then
        destroyVCenterVMClusterMember ${CLUSTER_NAME}-bootstrap

    fi
    if [ "${OCP_INSTALL_TYPE}"  ==  "kvm-upi" ] ;then
        virsh destroy bootstrap  2> /dev/null
        virsh undefine bootstrap 2> /dev/null
    fi
    if [ "${HAPROXY_BUILD}" == "true" ];then
        #Remove Masters from ingress-workers as VSphere is not using masters as workers
        find /etc/haproxy/haproxy.cfg -type f | xargs sed -i'' "s/.*bootstrap.*//g"
        sed -i '/^$/d' /etc/haproxy/haproxy.cfg
        sed -i '/^[[:space:]]*$/d' /etc/haproxy/haproxy.cfg
        echo "Restarting haproxy afater removal of bootstrap"
        systemctl restart haproxy
    fi
  else
      echo "Not removing bootstrap node per flag being set - OCP_KEEP_BOOTSTRAP=${OCP_KEEP_BOOTSTRAP}"
  fi
  echo ""

}


waitForNodesToFinishUpdate()
{
  startWaitForNode=$SECONDS
  printHeaderMessage "Wait for nodes to finish updates"
  echo ""
  blinkWaitMessage "Waiting 10 minutes before we start to check (Go get a Coffee!)" 600
  MASTERS_UPDATING=`oc get mcp 2> /dev/null | grep "master" | awk '{print $4}'`
  WORKERS_UPDATING=`oc get mcp 2> /dev/null | grep "worker" | awk '{print $4}'`
  while [[ "${MASTERS_UPDATING}" == "True"  || "${WORKERS_UPDATING}" == "True" ]]
  do
    blinkWaitMessage "Still waiting  - almost there, will keep checking every 60 seconds" 60
    MASTERS_UPDATING=`oc get mcp 2> /dev/null | grep "master" | awk '{print $4}'`
    WORKERS_UPDATING=`oc get mcp 2> /dev/null | grep "worker" | awk '{print $4}'`
  done
  now=$SECONDS
  let "diff=now-startWaitForNode"
  startWaitForNode=${diff}
  if (( $startWaitForNode > 3600 )) ; then
      let "hours=startWaitForNode/3600"
      let "minutes=(startWaitForNode%3600)/60"
      let "seconds=(startWaitForNode%3600)%60"
      echo "${BLUE_TEXT}COMPLETE ${RESET_TEXT}Master and Worker Nodes updated in $hours hour(s), $minutes minute(s) and $seconds second(s)"
  elif (( $startWaitForNode > 60 )) ; then
      let "minutes=(startWaitForNode%3600)/60"
      let "seconds=(startWaitForNode%3600)%60"
      echo "${BLUE_TEXT}COMPLETE ${RESET_TEXT}Master and Worker Nodes updated  $minutes minute(s) and $seconds second(s)"
  else
      echo "${BLUE_TEXT}COMPLETE ${RESET_TEXT}Master and Worker Nodes updated  $startWaitForNode seconds"
  fi
  echo ""
}
getMonthPoint()
{
  df -P  ${1} | awk '{c++} c==2 {print $NF}'
}

getPullSecret()
{
  if [[ -z  ${PULL_SECRET} ]]; then
    echo "To get your OpenShift Pull secret, you can go here:   https://console.redhat.com/openshift/downloads#tool-pull-secret"
    echo ""
    echo "Missing PULL_SECRET, Please enter here so we can save to your ~/.profile"
    echo -n "PULL_SECRET=${BLUE_TEXT}"
    read  PULL_SECRET
    echo ${RESET_TEXT}
    echo "export PULL_SECRET='"${PULL_SECRET}"'" >> ~/.profile
    source ~/.profile
  fi

}
getPullSecretviaAPI()
{
  if [ -n  "${REDHAT_API_TOKEN}" ] && [ -z  ${PULL_SECRET} ] ;then
    BEARER=$(curl \
    --silent \
    --data-urlencode "grant_type=refresh_token" \
    --data-urlencode "client_id=cloud-services" \
    --data-urlencode "refresh_token=${REDHAT_API_TOKEN}" \
    https://sso.redhat.com/auth/realms/redhat-external/protocol/openid-connect/token | \
    jq -r .access_token)
    export PULL_SECRET=`curl -X POST https://api.openshift.com/api/accounts_mgmt/v1/access_token --header "Content-Type:application/json" --header "Authorization: Bearer $BEARER" 2>/dev/null`
    echo "export PULL_SECRET='"${PULL_SECRET}"'" >> ~/.profile
    echo "Got OpenShift Pull Secrret via API from  sso.redhat.com"
  fi
}
getVSpherePassword()
{
  if [[ -z  ${VSPHERE_PASSWORD} ]]; then
    echo "Missing VSPHERE_PASSWORD, Please enter here so we can save to your ~/.profile${BLUE_TEXT}"
    echo -n "VSPHERE_PASSWORD="
    #read -s VSPHERE_PASSWORD
    while IFS= read -r -s -n1 pass; do
      if [[ -z $pass ]]; then
         echo
         break
      else
         echo -n '*'
         VSPHERE_PASSWORD+=$pass
      fi
    done
    echo ${RESET_TEXT}
    echo "export VSPHERE_PASSWORD='"${VSPHERE_PASSWORD}"'" >> ~/.profile
    source ~/.profile
  fi
}
getBastionPassword()
{
  if [[ -z  ${BASTION_PASSWORD} ]]; then
    echo "Missing BASTION_PASSWORD, Please enter here so we can save to your ~/.profile${BLUE_TEXT}"
    echo -n "BASTION_PASSWORD="
    #read -s BASTION_PASSWORD
    while IFS= read -r -s -n1 pass; do
      if [[ -z $pass ]]; then
         echo
         break
      else
         echo -n '*'
         BASTION_PASSWORD+=$pass
      fi
    done
    echo ${RESET_TEXT}
    echo "export BASTION_PASSWORD='"${BASTION_PASSWORD}"'" >> ~/.profile
    source ~/.profile
  fi

}
getLocalRegistryAuth()
{
  if [[ -z  ${LOCAL_REGISTRY_AUTH_INFO} ]]; then
    echo "Missing LOCAL_REGISTRY_AUTH_INFO, Please enter here so we can save to your ~/.profile${BLUE_TEXT}"
    echo 'Example :  {"<URL>:5000": {"auth": "<PASSWORD>","email": "<EMAIL>"}}"'
    echo -n "LOCAL_REGISTRY_AUTH_INFO="
    read  LOCAL_REGISTRY_AUTH_INFO
    echo ${RESET_TEXT}
    echo "export LOCAL_REGISTRY_AUTH_INFO='"${LOCAL_REGISTRY_AUTH_INFO}"'" >> ~/.profile
    source ~/.profile
  fi
}
localPortInuse()
{
    LOCAL_PORT_IN_USE=`lsof -i -P -n 2>/dev/null | grep LISTEN | grep -c ":${1} "`
    if [ ${LOCAL_PORT_IN_USE} -ge 1 ]; then
         echo "${RED_TEXT}Port $1 is in use on local machine. Can not continue with build."
         lsof -i -P -n 2>/dev/null | grep LISTEN | grep ":${1} "
         echo "${RESET_TEXT}"
         SHOULD_EXIT=1
    fi
}
generateRandomString()
{
  RANDOM_STRING=`tr -dc A-Za-z0-9 </dev/urandom | head -c 13 ; echo ''`
}

apachePortsReassignment()
{
    sed -i 's/Listen 80$/Listen 81/g' /etc/apache2/ports.conf > ${LOG_DIR}/${PRODUCT_SHORT_NAME}/apachePortsReassignment.log 2>&1
    sed -i 's/Listen 8080$/Listen 8088/g' /etc/apache2/ports.conf >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/apachePortsReassignment.log 2>&1
    sed -i 's/Listen 443$/Listen 4443/g' /etc/apache2/ports.conf >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/apachePortsReassignment.log 2>&1
    /etc/init.d/apache2 restart >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/apachePortsReassignment.log 2>&1
}

updateIBMEntitlementInPullSecret()
{
  printHeaderMessage "Updating PullSecret to add IBM Entitlement Key"
  echo "Checking to see if IBM Entitlement Key exists in cluster"
  cd ${TEMP_DIR}/${PRODUCT_SHORT_NAME}
  oc extract secret/pull-secret --confirm -n openshift-config 1>/dev/null
  CHECK_IBM_ENTITLEMENT=`cat ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/.dockerconfigjson | grep -c $CP_REGISTRY`
  if [ ${CHECK_IBM_ENTITLEMENT} == "1" ] ;then
     echo "IBM Entitlement Key is already applied to cluster"
  else
      if [ "${1}" == "apply" ];then
          echo "Adding Your IBM Token to the existing Pull Secret"
          IBM_ENTITLEMENT_KEY_NEW=`echo -n "cp:${IBM_ENTITLEMENT_KEY}" | base64 -w0`
          cat  ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/.dockerconfigjson | jq '.auths += {"CP_REGISTRY": {"auth": "IBM_ENTITLEMENT_KEY","email": "CP_REGISTRY_EMAIL"}}' | sed "s/CP_REGISTRY_EMAIL/$CP_REGISTRY_EMAIL/g;s/CP_REGISTRY/$CP_REGISTRY/g;s/IBM_ENTITLEMENT_KEY/$IBM_ENTITLEMENT_KEY_NEW/g" >  ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/.dockerconfigjson.new
      fi
      if [ "${1}" == "delete" ];then
          echo "Removing your IBM Token from the existing Pull Secret"
          cat  ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/.dockerconfigjson | jq 'del(.auths["'$CP_REGISTRY'"])' > .dockerconfigjson.new
      fi
      rm -fR ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/.dockerconfigjson 2>/dev/null
      mv  ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/.dockerconfigjson.new  ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/.dockerconfigjson
      oc set data secret/pull-secret -n openshift-config --from-file=.dockerconfigjson | tee ${LOG_DIR}/${PRODUCT_SHORT_NAME}/pull-secret.log
      rm -fR  ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/.dockerconfigjson 2>/dev/null
      case ${OCP_INSTALL_TYPE} in
        roks-msp)
            if [ "${CHECK_IBM_ENTITLEMENT}" == "1" ] ;then
               echo "IBM Entitlement Key exists. Skipping reload of ROKS"
            else
               restartRoksNodes
            fi
            ;;
      esac
  fi
  echo ""
}
validClusterName()
{
  printHeaderMessage "Validate Cluster Name"
  local RESULT=`echo ${CLUSTER_NAME} | grep -P "^(([a-z0-9]|[a-z0-9][a-z0-9\-]*[a-z0-9])\.)*([a-z0-9]|[a-z0-9][a-z0-9\-]*[a-z0-9])$"`
  if [[ -z "${RESULT}"  ]]; then
    SHOULD_EXIT=1
    echo "${RED_TEXT}FAILED ${RESET_TEXT} ${CLUSTER_NAME} is not a valid cluster name(lowercase/alphanumberic/ and - )"
  else
    echo "${BLUE_TEXT}PASSED ${RESET_TEXT} ${CLUSTER_NAME} is a valid cluster name"
  fi
  echo ""
}

validBaseDomainClusterDNSName()
{
  case ${OCP_INSTALL_TYPE} in
    roks-msp)
         touch ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/ignore
         ;;
    *)
         validClusterName
         printHeaderMessage "Validate Base Domain (valid FQDN syntax)"
         local RESULT=`echo ${BASE_DOMAIN} | grep -P "^(([a-z0-9]|[a-z0-9][a-z0-9\-]*[a-z0-9])\.)*([a-z0-9]|[a-z0-9][a-z0-9\-]*[a-z0-9])$"`
         if [[ -z "${RESULT}"  ]]; then
           SHOULD_EXIT=1
           echo "${RED_TEXT}FAILED: .${BASE_DOMAIN} is not a valid FQDN (invalid characters used.)${RESET_TEXT}"
         else
           echo "${BLUE_TEXT}PASSED ${RESET_TEXT} ${BASE_DOMAIN} is a valid FQDN String"
         fi
         echo ""
         ;;
  esac

}
getIBMEntitlementKey()
{
    if [[ -z  ${IBM_ENTITLEMENT_KEY} ]]; then
      echo "Missing IBM Entitlement Key, to get your key, go here with your browser:"
      echo "${BLUE_TEXT}https://myibm.ibm.com/products-services/containerlibrary${RESET_TEXT}"
      echo "Please enter here so we can save to your ~/.profile${IBM_ENTITLEMENT_KEY}"
      echo -n "IBM_ENTITLEMENT_KEY=${BLUE_TEXT}"
      read  IBM_ENTITLEMENT_KEY
      echo ${RESET_TEXT}
      echo "export IBM_ENTITLEMENT_KEY='"${IBM_ENTITLEMENT_KEY}"'" >> ~/.profile
      source ~/.profile
    else
      if [ "${1}"  != "suppress" ]; then
          echo "${BLUE_TEXT}PASSED ${RESET_TEXT} Entitlement Key found!"
      fi
    fi
}

validateStorage()
{
  printHeaderMessage "Validate Storage Class to be used with Cloud Pak "
  local FOUND_STORAGE_CLASS=`oc get storageclass ${1} 2>/dev/null | grep -c ${1}`
  if [ ${FOUND_STORAGE_CLASS} -eq 0 ]; then
    SHOULD_EXIT=1
    echo "${RED_TEXT}FAILED ${RESET_TEXT} Storage class NOT found : ${1} ${RESET_TEXT}"
  else
    echo "${BLUE_TEXT}PASSED ${RESET_TEXT} Storage class -> ${1} exist. ${RESET_TEXT}"
  fi

  if [  "${1}" == "ocs-storagecluster-cephfs" ]; then
      printHeaderMessage "Validate OpenShift Storage Cluster to be used with Cloud Pak"
      local let LOOP_COUNT=1
      OCS_STATUS="NOT_READY"
      echo ""
      while [ "${OCS_STATUS}" != "Ready"  ]; do
            blinkWaitMessage "Waiting for Storage Cluster - ocs-storagecluster to be ready (Up to 15 min)" 10
            local OCS_STATUS=`oc get StorageCluster  ocs-storagecluster -n openshift-storage -o jsonpath='{.status.phase}' 2>/dev/null | sed 's/ *$//g'`
            if  [ "${OCS_STATUS}" == "Ready" ]; then
                 echo "${BLUE_TEXT}PASSED ${RESET_TEXT} Storage Cluster -> ocs-storagecluster is ready."
                 echo ""
            fi
            if  [ "${LOOP_COUNT}" -ge 90 ]; then
                 SHOULD_EXIT=1
                 echo "${RED_TEXT}FAILED ${RESET_TEXT} Storage Cluster(ocs-storagecluster) to be ready.${RESET_TEXT}"
                 break
            fi
            let LOOP_COUNT=LOOP_COUNT+1
      done
  fi
 echo ""

}

baseValidation()
{
  printHeaderMessage "Validation of Base Values"
  if [ -z ${DAFFY_DEPLOYMENT_TYPE} ]; then
    SHOULD_EXIT=1
    echo "${RED_TEXT}FAILED ${RESET_TEXT} Missing DAFFY_DEPLOYMENT_TYPE value in your environment file. Supported values (POC|Enablement|Demo)"
    echo "Please add this variable to your environment file:"
    echo "DAFFY_DEPLOYMENT_TYPE=<POC|Enablement|Demo|HCCX|TechZone>"
    echo ""
  fi
  if [ ! -z ${DAFFY_DEPLOYMENT_TYPE} ]; then
    case ${DAFFY_DEPLOYMENT_TYPE} in
        POC|Demo)
            echo "${BLUE_TEXT}PASSED ${RESET_TEXT} Valid DAFFY_DEPLOYMENT_TYPE of ${DAFFY_DEPLOYMENT_TYPE}"
            variablePresent ${DAFFY_ISC_NUMBER} DAFFY_ISC_NUMBER
            if [ ! -z "${DAFFY_ISC_NUMBER}" ]; then
               DAFFY_ISC_NUMBER_LENGTH=`expr length ${DAFFY_ISC_NUMBER}`
               if [ ${DAFFY_ISC_NUMBER_LENGTH} -ne 18 ]; then
                 SHOULD_EXIT=1
                 echo "${RED_TEXT}FAILED ${RESET_TEXT} Invalid DAFFY_ISC_NUMBER of ${DAFFY_ISC_NUMBER}. Supported values 18 alphanumberic characters"
               else
                 local RESULT=`echo ${DAFFY_ISC_NUMBER} | grep -P "^[a-zA-Z0-9][-a-zA-Z0-9]{0,61}[a-zA-Z0-9]$"`
                 if [[ -z "${RESULT}"  ]]; then
                   SHOULD_EXIT=1
                   echo "${RED_TEXT}FAILED ${RESET_TEXT} Invalid DAFFY_ISC_NUMBER of ${DAFFY_ISC_NUMBER}. Supported values 18 alphanumberic characters"
                 else
                   echo "${BLUE_TEXT}PASSED ${RESET_TEXT} Valid DAFFY_ISC_NUMBER of ${DAFFY_ISC_NUMBER}"
                   DAFFY_ISC_NUMBER=`rawurlencode "${DAFFY_ISC_NUMBER}"`
                 fi
               fi
            fi
            variablePresent ${DAFFY_CUSTOMER_NAME} DAFFY_CUSTOMER_NAME
            if [ ! -z "${DAFFY_CUSTOMER_NAME}" ]; then
              echo "${BLUE_TEXT}PASSED ${RESET_TEXT} Valid DAFFY_CUSTOMER_NAME of ${DAFFY_CUSTOMER_NAME}"
            fi
            DAFFY_CUSTOMER_NAME=`rawurlencode "${DAFFY_CUSTOMER_NAME}"`
            #local RESULT=`echo ${DAFFY_CUSTOMER_NAME} | grep -P "^(([a-z,A-Z,0-9]|[a-z,A-Z,0-9][a-z,A-Z,0-9,\-,\_]*[a-z,A-Z,0-9])\.)*([a-z,A-Z,0-9]|[a-z,A-Z,0-9][a-z,A-Z,0-9,\-,\_]*[a-z,A-Z,0-9])$"`
            #if [[ -z "${RESULT}"  ]]; then
            #  SHOULD_EXIT=1
            #  echo "${RED_TEXT}FAILED ${RESET_TEXT} ${DAFFY_CUSTOMER_NAME} is not a valid customer name(lowercase/alphanumberic/ or - _ ) no spaces"
            #else
            #  echo "${BLUE_TEXT}PASSED ${RESET_TEXT} ${DAFFY_CUSTOMER_NAME} is a valid customer name"
            #fi
            ;;
        Enablement|HCCX|TechZone)
            echo "${BLUE_TEXT}PASSED ${RESET_TEXT} Valid DAFFY_DEPLOYMENT_TYPE of ${DAFFY_DEPLOYMENT_TYPE}"
            ;;
        *)
            SHOULD_EXIT=1
            echo "${RED_TEXT}FAILED ${RESET_TEXT} Invalid DAFFY_DEPLOYMENT_TYPE of ${DAFFY_DEPLOYMENT_TYPE}. Supported values (POC|Enablement|Demo)"
            ;;
    esac
  fi
  variablePresent ${OCP_INSTALL_TYPE} OCP_INSTALL_TYPE
  variablePresent ${OCP_RELEASE} OCP_RELEASE
  variablePresent ${CLUSTER_NAME} CLUSTER_NAME
  validOCPInstallTYPE
  getBastionIP
  case ${OCP_INSTALL_TYPE} in
        roks-msp )
            if [  "${PRODUCT_SHORT_NAME}" != "ocp" ]; then
                testIBMCloudLogin
                if [[ "${CURRENT_SCRIPT_NAME}" != *cleanup.sh ]];then
                    validateOCPAccess
                    ACTIVE_CLUSTER_NAME=`oc -n kube-system get configmap cluster-info -o yaml 2> /dev/null | grep '"name":'  | grep -v cluster-info | sed 's/"//g' | sed 's/,//g' | sed "s/name: //g" | sed "s/ //g"`
                    if [  "${ACTIVE_CLUSTER_NAME}" != "${CLUSTER_NAME}"  ]; then
                        SHOULD_EXIT=1
                        echo "${RED_TEXT}FAILED ${RESET_TEXT}  (${ACTIVE_CLUSTER_NAME}) does not match your ENVIRONMENT_FILE value  (${CLUSTER_NAME})"
                    else
                        echo "${BLUE_TEXT}PASSED ${RESET_TEXT} Active Cluster Name (${ACTIVE_CLUSTER_NAME}) matches your ENVIRONMENT_FILE value (${CLUSTER_NAME})"
                    fi
                fi
            fi
            ;;
        rosa-msp)
            ROSALogin
            ;;
       *)
          variablePresent ${BASE_DOMAIN} BASE_DOMAIN
          validBaseDomainClusterDNSName
          ;;
  esac
}

restartCrashLoopBackOffPods()
{
    local NAME_SPACE=$1
    echo "Restart all CrashLoopBackOff Pods"
    local PODS=`oc get pods -n ${NAME_SPACE} | grep -v NAMESPACE | grep CrashLoopBackOff |  awk '{print $1 }' | grep -v NAME`
		for POD in $PODS
    do
			oc delete pod -n ${NAME_SPACE} $POD > /dev/null 2>&1 &
      sleep 5
	  done
}
restartImagePullBackOffPods()
{
    local NAME_SPACE=$1
    echo "Restart all CrashLoopBackOff Pods"
    local PODS=`oc get pods -n ${NAME_SPACE} | grep -v NAMESPACE | grep ImagePullBackOff |  awk '{print $1 }' | grep -v NAME`
		for POD in $PODS
    do
			oc delete pod -n ${NAME_SPACE} $POD > /dev/null 2>&1 &
      sleep 5
	  done
}
getClusterInfo()
{
  if [ -f ${OCP_KUBECONFIG_DIR}/${CLUSTER_NAME}/${OCP_LOCAL_ADMIN}-password ]; then
      OCP_LOCAL_ADMIN_PASSWORD=`cat ${OCP_KUBECONFIG_DIR}/${CLUSTER_NAME}/${OCP_LOCAL_ADMIN}-password`
      OCP_PASSWORD=`cat ${OCP_KUBECONFIG_DIR}/${CLUSTER_NAME}/kubeadmin-password`
      export KUBECONFIG=${OCP_KUBECONFIG_DIR}/${CLUSTER_NAME}/kubeconfig
      oc login https://api.${OCP_HOST_NAME}:6443 -u ${OCP_LOCAL_ADMIN} -p ${OCP_LOCAL_ADMIN_PASSWORD} --insecure-skip-tls-verify > /dev/null 2>&1
      #OCP_CONSOLE_URL="https://console-openshift-console.apps.${CLUSTER_NAME}.${BASE_DOMAIN}"
  fi
  OCP_CONSOLE_URL=`oc whoami --show-console 2> /dev/null`
  OC_CLUSTER_VERSION=`oc get clusterversion 2> /dev/null | grep version | awk '{print  $2 }'`
  OCP_CLUSTER_ID=`oc get clusterversion -o jsonpath='{.items[].spec.clusterID}{"\n"}' 2> /dev/null`
}

ocpDeleteAllFailedPods()
{
    printHeaderMessage "Delete all Pods in Failed Status" ${RED_TEXT}
    echo "Delete all Failed pods"
    oc delete pods --field-selector status.phase=Failed -A
    echo ""
    echo "Delete all ImagePullBackOff|ErrImagePull|Evicted pods"
    oc get pods --all-namespaces | grep -E 'ImagePullBackOff|ErrImagePull|Evicted' | awk '{print $2 " --namespace=" $1}' | xargs oc delete pod
    echo ""
    echo "Delete Pods done"
    echo ""
}


applyNameSpaceLabels()
{

  local NAMESPACE_NAME=${1}
  local NAMESPACE_DESCRIPTION="${2}"
  DAFFY_UNIQUE_ID_TEMP=`echo ${DAFFY_UNIQUE_ID} | sed "s/@/__at__/g"`
  oc annotate namespace ${NAMESPACE_NAME} openshift.io/display-name="${NAMESPACE_DESCRIPTION}" --overwrite > /dev/null 2>&1
  oc annotate namespace ${NAMESPACE_NAME} openshift.io/requester="${PROJECT_NAME}" --overwrite > /dev/null 2>&1
  oc annotate namespace ${NAMESPACE_NAME} openshift.io/description="This project was built with ${PROJECT_NAME} ${DAFFY_VERSION}" --overwrite > /dev/null 2>&1
  oc label namespace ${NAMESPACE_NAME} openshift.ibm/builtBy=${PROJECT_NAME} --overwrite > /dev/null 2>&1
  oc label namespace ${NAMESPACE_NAME} ${PROJECT_NAME}.ibm/buildDate=${CURRENT_DATE_TIME} --overwrite > /dev/null 2>&1
  oc label namespace ${NAMESPACE_NAME} ${PROJECT_NAME}.ibm/buildUser=${DAFFY_UNIQUE_ID_TEMP} --overwrite > /dev/null 2>&1
  oc label namespace ${NAMESPACE_NAME} ${PROJECT_NAME}.ibm/buildVersion=${DAFFY_VERSION} --overwrite > /dev/null 2>&1
}

getBastionIP()
{
  if [ -z ${BASTION_HOST} ]; then
        BASTION_HOST=`timeout 5 host myip.opendns.com resolver1.opendns.com 2> /dev/null | grep myip.opendns.com | awk '{ print $4 }'`
        if [[ -z ${BASTION_HOST} ]]; then
          BASTION_HOST=`ifconfig -a | grep inet | grep -v "192\|127\.0\.0.1\|inet6\|172.17.0" | awk '{ print $2 }'`
        fi
        OCP_HOST_IP=${BASTION_HOST}
  fi
}


validLocalHostname()
{
  local HOSTNAME=`hostname`
  local LOCAL_VALID_HOST_NAME=`cat /etc/hosts | grep -c $HOSTNAME`
  if [ ${LOCAL_VALID_HOST_NAME} -eq 0 ]; then
    echo "${RED_TEXT}FAILED: Hostname - ${HOSTNAME} not listing in /etc/hosts file.${RED_TEXT}"
    SHOULD_EXIT=1
  fi
}
logIntoCluster()
{
  if [ -f ${OCP_KUBECONFIG_DIR}/${CLUSTER_NAME}/${OCP_LOCAL_ADMIN}-password ]; then
    OCP_LOCAL_ADMIN_PASSWORD=`cat ${OCP_KUBECONFIG_DIR}/${CLUSTER_NAME}/${OCP_LOCAL_ADMIN}-password`
    echo "${BLUE_TEXT}###############################################################################${RESET_TEXT}"
    echo "Login to oc as admin user - ${OCP_LOCAL_ADMIN}"
    echo "${BLUE_TEXT}###############################################################################${RESET_TEXT}"
    export KUBECONFIG=${OCP_KUBECONFIG_DIR}/${CLUSTER_NAME}/kubeconfig
    oc login https://api.${OCP_HOST_NAME}:6443 -u ${OCP_LOCAL_ADMIN} -p ${OCP_LOCAL_ADMIN_PASSWORD} --insecure-skip-tls-verify > /dev/null 2>&1
  fi
  case ${OCP_INSTALL_TYPE} in
    roks-msp )
      OCP_LOCAL_ADMIN=`oc whoami > /dev/null 2>&1`
      ;;
  esac
  validateOCPAccess
  echo ""

}
installPodman()
{
      printHeaderMessage "Podman Check (LOG -> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/podman-install.log )"
      FOUND_PODMAN_COMMAND=`podman version 2> /dev/null | grep -c "Version:  "`
      if [ ${FOUND_PODMAN_COMMAND} -eq 0 ]  ;then
            if [ ${IS_UBUNTU} == 1 ]; then
                echo "Installing podman"
                source /etc/os-release
                echo "deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_${VERSION_ID}"
                sh -c "echo 'deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_${VERSION_ID}/ /' > /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list" > ${LOG_DIR}/${PRODUCT_SHORT_NAME}/podman-install.log 2>&1
                wget -nv https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/xUbuntu_${VERSION_ID}/Release.key -O- | apt-key add - >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/podman-install.log 2>&1
                echo "apt-get update -qq -y"
                apt-get update -qq -y >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/podman-install.log 2>&1
                echo "apt-get -qq --yes install podman"
                apt-get -qq --yes install podman >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/podman-install.log 2>&1
            elif [ ${IS_RH} ==  1 ]; then
                echo "Installing podman"
                echo "yum module enable -y container-tools:rhel8"
                yum module enable -y container-tools:rhel8 > ${LOG_DIR}/${PRODUCT_SHORT_NAME}/podman-install.log 2>&1
                echo "yum module install -y container-tools:rhel8"
                yum module install -y container-tools:rhel8 >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/podman-install.log 2>&1
            fi
            FOUND_PODMAN_COMMAND=`podman version 2> /dev/null | grep -c "Version:  "`
            if [ ${FOUND_PODMAN_COMMAND} -eq 0 ]  ;then
                echo "${RED_TEXT}FAILED Podman(Version:  ${PODMAN_VERSION}) failed to install!!!!!${RESET_TEXT}"
                SHOULD_EXIT=1
            else
              local CURRENT_PODMAN_VERSION=`podman version | grep Version |  head -n 1 | awk  '{print $2}'`
               echo "${BLUE_TEXT}PASSED${RESET_TEXT} Podman ${CURRENT_PODMAN_VERSION} has been installed."
            fi
      else
            local CURRENT_PODMAN_VERSION=`podman version | grep Version |  head -n 1 | awk  '{print $2}'`
            echo "${BLUE_TEXT}PASSED${RESET_TEXT} Podman ${CURRENT_PODMAN_VERSION} installed already."
      fi
      echo ""
}
consoleFooter()
{
  echo ""
  echo ""
  echo "##########################################################################################################"
  SCRIPT_END_TIME=`date`
  echo "End Time: ${SCRIPT_END_TIME}"
  if (( $SECONDS > 3600 )) ; then
      let "hours=SECONDS/3600"
      let "minutes=(SECONDS%3600)/60"
      let "seconds=(SECONDS%3600)%60"
      echo "${1} Completed in $hours hour(s), $minutes minute(s) and $seconds second(s)"
  elif (( $SECONDS > 60 )) ; then
      let "minutes=(SECONDS%3600)/60"
      let "seconds=(SECONDS%3600)%60"
      echo "${1} Completed in $minutes minute(s) and $seconds second(s)"
  else
      echo "${1} Completed in $SECONDS seconds"
  fi
  echo "##########################################################################################################"
  echo ""
  echo ""
}

getOpenShiftTools()
{

  if [ "${ALREADY_FOUND_OPENSHIFT_TOOLS}" != "true" ]; then
      FOUND_OC_COMMAND=`oc version 2> /dev/null | grep -c "Client Version: ${OCP_RELEASE}"`
      if [ "${FOUND_OC_COMMAND}" == "0"  ] ;then
          printHeaderMessage "Get OpenShift Tools"
          echo "Missing correct version of oc command line tools - downloading now "
          echo "wget ${OPENSHIFT_SITE_DOWNLOAD}/pub/openshift-v4/clients/ocp/${OCP_RELEASE}/openshift-client-linux-${OCP_RELEASE}.tar.gz"
          wget ${OPENSHIFT_SITE_DOWNLOAD}/pub/openshift-v4/clients/ocp/${OCP_RELEASE}/openshift-client-linux-${OCP_RELEASE}.tar.gz 2> /dev/null
          if [ ! -f openshift-client-linux-${OCP_RELEASE}.tar.gz ]; then
            echo "${RED_TEXT}Failed to download openshift-client, unable to continue:"
            echo "${OPENSHIFT_SITE_DOWNLOAD}/pub/openshift-v4/clients/ocp/${OCP_RELEASE}/openshift-client-linux-${OCP_RELEASE}.tar.gz${RESET_TEXT}"
            exit 99
          fi
          tar xvf openshift-client-linux-${OCP_RELEASE}.tar.gz 2>&1 > /dev/null
          mv oc /usr/local/bin/
          mv kubectl /usr/local/bin
          rm -rf openshift-client-linux-${OCP_RELEASE}.tar.gz README.md
          echo "${BLUE_TEXT}PASSED ${RESET_TEXT} Installed correct version of oc tools - ${OCP_RELEASE}"
       else
          printHeaderMessage "Get OpenShift Tools"
          echo "${BLUE_TEXT}PASSED ${RESET_TEXT} Correct version of oc tools found, will not download - ${OCP_RELEASE}"
          ALREADY_FOUND_OPENSHIFT_TOOLS=true
       fi
  fi
 }
validOCPInstallTYPE()
{
    case ${PRODUCT_SHORT_NAME} in
      ocp)
          case ${OCP_INSTALL_TYPE} in
            vsphere-upi|vsphere-ipi|aws-ipi|gcp-ipi|azure-ipi|kvm-upi|roks-msp)
                echo "${BLUE_TEXT}PASSED ${RESET_TEXT} Valid OCP_INSTALL_TYPE of ${OCP_INSTALL_TYPE} for ${PRODUCT_SHORT_NAME}"
                ;;
            *)
                echo "${RED_TEXT}Unsupported OCP_INSTALL_TYPE of ${OCP_INSTALL_TYPE} for ${PRODUCT_SHORT_NAME} ${RESET_TEXT}"
                SHOULD_EXIT=1
                ;;
          esac
          ;;
      cp4d|cp4i|cp4waiops|cp4ba|wsa|cp4security)
          case ${OCP_INSTALL_TYPE} in
            vsphere-upi|vsphere-ipi|aws-ipi|gcp-ipi|azure-ipi|kvm-upi|roks-msp)
                echo "${BLUE_TEXT}PASSED ${RESET_TEXT} Valid OCP_INSTALL_TYPE of ${OCP_INSTALL_TYPE} for ${PRODUCT_SHORT_NAME}"
                ;;
            rosa-msp|arho-msp|fyre-ibm)
                echo "${RED_TEXT}Not Supported yet:  OCP_INSTALL_TYPE of ${OCP_INSTALL_TYPE} for ${PRODUCT_SHORT_NAME} ${RESET_TEXT}"
                SHOULD_EXIT=1
                ;;
            *)
                if [ "${IGNORE_OCP_INSTALL_TYPE_CHECK}" == "true"  ]; then
                  echo "${RED_TEXT}Unsupported OCP_INSTALL_TYPE of ${OCP_INSTALL_TYPE} for ${PRODUCT_SHORT_NAME}"
                  echo "${IGNORE_OCP_INSTALL_TYPE_CHECK} flag set to true, will ignore contiute anyways."
                  echo "${RED_TEXT}Untested: Installer, your on your own!!!!!!!${RESET_TEXT}"
                else
                  echo "${RED_TEXT}Unsupported OCP_INSTALL_TYPE of ${OCP_INSTALL_TYPE} for ${PRODUCT_SHORT_NAME} ${RESET_TEXT}"
                  SHOULD_EXIT=1
                fi
                ;;
          esac
          ;;
      db2|ldap)
          echo "${BLUE_TEXT}PASSED ${RESET_TEXT} Valid PRODUCT_SHORT_NAME of ${PRODUCT_SHORT_NAME}"
          ;;
      *)
          echo "${RED_TEXT}Unsupported PRODUCT_SHORT_NAME - ${PRODUCT_SHORT_NAME}. ${RESET_TEXT}"
          SHOULD_EXIT=1
          ;;
    esac

}
validateOCPAccess()
{
  if [ "${CURRENT_SCRIPT_NAME}" != "*cleanup.sh" ] ;then
      printHeaderMessage "Validate OCP Access"
      #getOpenShiftTools
      OC_CLUSTER_ACCESS=`timeout 30 oc get nodes 2> /dev/null  | grep -c Ready`
      if [ "${OC_CLUSTER_ACCESS}" == 0 ] ;then
          case ${OCP_INSTALL_TYPE} in
            roks-msp)
                  if [ "${ROKS_PROVIDER}" != "techzone" ]; then
                      testIBMCloudLogin
                  fi
                  local IBMCLOUD_ROKS_LOGIN_FAILED=`ibmcloud oc cluster config -c ${CLUSTER_NAME} --admin &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ibmcloud-login.log ; cat ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ibmcloud-login.log | grep -c FAILED`
                  if [ ${IBMCLOUD_ROKS_LOGIN_FAILED} -ge 1  ]; then
                      echo "Please login to your cluster web console and copy/paste the oc admin login command below:"
                      read -p "" OC_ADMIN_TOKEN_COMMAND
                      if [[ ${OC_ADMIN_TOKEN_COMMAND} == oc* ]]; then
                          ${OC_ADMIN_TOKEN_COMMAND}
                      fi
                  fi
                  validateOCPAccess
                  ;;
            rosa-msp)
                  ROSALoginCluster
                  ;;
              *)
                  SHOULD_EXIT=1
                  echo "${RED_TEXT}FAILED ${RESET_TEXT} No access to cluster via oc command${RESET_TEXT}"
                  ;;
          esac

      else
          echo "${BLUE_TEXT}PASSED ${RESET_TEXT} Access to cluster via oc command${RESET_TEXT}"
      fi
  fi

}
restartOCPNodes()
{
    case ${OCP_INSTALL_TYPE} in
      roks-msp)
          restartRoksNodes
          ;;
    esac
}
setDefaultStorgeClass()
{

  oc patch storageclass $1 -p '{"metadata": {"annotations": {"storageclass.kubernetes.io/is-default-class": "true"}}}'

}
validateCloudPakSize()
{
  VM_TSHIRT_SIZE=Large
  if [ "${VM_TSHIRT_SIZE}" == "Large"  ]; then
    echo "${BLUE_TEXT}PASSED ${RESET_TEXT} VM_TSHIRT_SIZE of ${VM_TSHIRT_SIZE} for Cloud Paks"
  else
    echo "${RED_TEXT}FAILED ${RESET_TEXT} Unsupported VM_TSHIRT_SIZE of ${VM_TSHIRT_SIZE} for Cloud Paks, must Be Large"
    SHOULD_EXIT=1
  fi
}
getDB2Password()
{
  if [[ -z  ${DB_PASSWORD} ]]; then
    echo ""
    echo ""
    echo "Missing DB_PASSWORD, Please enter here so we can save to your ~/.profile"
    echo -n "DB_PASSWORD=${BLUE_TEXT}"
    unset DB_PASSWORD;
    while IFS= read -r -s -n1 pass; do
      if [[ -z $pass ]]; then
         echo
         break
      else
         echo -n '*'
         DB_PASSWORD+=$pass
      fi
    done
    export DB_PASSWORD=${DB_PASSWORD}
    echo ${RESET_TEXT}
    echo "export DB_PASSWORD='"${DB_PASSWORD}"'" >> ~/.profile
    source ~/.profile
  fi

}
validateLDAPPassword()
{
  if [ -z "${LDAP_PASSWORD}" ]; then
      echo "Missing LDAP_PASSWORD, please enter here so we can save to ~/.profile"
      unset LDAP_PASSWORD;
      echo -n "LDAP_PASSWORD=${BLUE_TEXT}"
      while IFS= read -r -s -n1 pass; do
        if [[ -z $pass ]]; then
           echo
           break
        else
           echo -n '*'
           LDAP_PASSWORD+=$pass
        fi
      done
      echo ${RESET_TEXT}
      if [ -z "${LDAP_PASSWORD}"  ]; then
        SHOULD_EXIT=1
        echo "${RED_TEXT}FAILED ${RESET_TEXT} Password blank"
      else
        export LDAP_PASSWORD=${LDAP_PASSWORD}
        echo "export LDAP_PASSWORD='${LDAP_PASSWORD}'" >> ~/.profile
      fi
  fi
}
validateDBPassword()
{
  if [ -z "${DB_PASSWORD}" ]; then
      echo "Missing DB_PASSWORD, please enter here so we can save to ~/.profile"
      unset DB_PASSWORD;
      echo -n "DB_PASSWORD=${BLUE_TEXT}"
      while IFS= read -r -s -n1 pass; do
        if [[ -z $pass ]]; then
           echo
           break
        else
           echo -n '*'
           DB_PASSWORD+=$pass
        fi
      done
      echo ${RESET_TEXT}
      if [ -z "${DB_PASSWORD}"  ]; then
        SHOULD_EXIT=1
        echo "${RED_TEXT}FAILED ${RESET_TEXT} Password blank"
      else
        export DB_PASSWORD=${DB_PASSWORD}
        echo "export DB_PASSWORD='${DB_PASSWORD}'" >> ~/.profile
      fi
  fi
}
updateBashProfile()
{
  local PROFILE_GOOD=`cat ~/.bash_profile | grep -c "source ~/.profile"`
  if [ ${PROFILE_GOOD} -eq 0 ]; then
    echo "${BLUE_TEXT}UPDATE ${RESET_TEXT} .bash_profile to source .profile "
    echo "#Added next line for Daffy" >> ~/.bash_profile
    echo "############################" >> ~/.bash_profile
    echo "source ~/.profile" >> ~/.bash_profile
  fi
}
rawurlencode() {
  local string="${1}"
  local strlen=${#string}
  local encoded=""
  local pos c o

  for (( pos=0 ; pos<strlen ; pos++ )); do
     c=${string:$pos:1}
     case "$c" in
        [-_.~a-zA-Z0-9] )
           o="${c}"
           ;;
        * )
           printf -v o '%%%02x' "'$c"
     esac
     encoded+="${o}"
  done
  echo "${encoded}"
}
updateDaffyStats()
{
  URL_FIELD_DAFFY_ISC_NUMBER=`rawurlencode "${DAFFY_ISC_NUMBER}"`
  URL_FIELD_DAFFY_CUSTOMER_NAME=`rawurlencode "${DAFFY_CUSTOMER_NAME}"`
  #echo "${DAFFY_URL}/${DAFFY_API}?type=${OCP_INSTALL_TYPE}&productName=${PRODUCT_SHORT_NAME}&ocpRelease=${OCP_RELEASE}&function=${PRODUCT_FUNCTION}&uniqueID=${DAFFY_UNIQUE_ID}&version=${DAFFY_VERSION}&deploymentType=${DAFFY_DEPLOYMENT_TYPE}&iscNumber=${URL_FIELD_DAFFY_ISC_NUMBER}&customerName=${URL_FIELD_DAFFY_CUSTOMER_NAME}"
  wget -T5 "${DAFFY_URL}/${DAFFY_API}?type=${OCP_INSTALL_TYPE}&productName=${PRODUCT_SHORT_NAME}&ocpRelease=${OCP_RELEASE}&function=${PRODUCT_FUNCTION}&uniqueID=${DAFFY_UNIQUE_ID}&version=${DAFFY_VERSION}&deploymentType=${DAFFY_DEPLOYMENT_TYPE}&iscNumber=${URL_FIELD_DAFFY_ISC_NUMBER}&customerName=${URL_FIELD_DAFFY_CUSTOMER_NAME}" > /dev/null 2>&1 ; rm addstats* 2> /dev/null

}
shouldExit()
{
  if [ ${SHOULD_EXIT} == 1 ] ;then
    echo ""
    echo ""
    echo "${RED_TEXT}Missing above required resources/permissions. Exiting Script!!!!!!!${RESET_TEXT}"
    echo ""
    echo ""
    if [  "${SHOULD_EXIT_IGNORE}" == "true"   ]; then
        echo "You are on your own now, we will contine install, you set SHOULD_EXIT_IGNORE=${SHOULD_EXIT_IGNORE}"
        echo ""
        echo ""
    else
        exit 99
    fi
  fi
}
#If OCP HTTP(s) Proxy Set and not http(s) _proxy , lets set for all calls
##############################################printHeaderMessage "Validate OCP Access"
if [ -z ${http_proxy} ]; then
  if [ ! -z ${OCP_PROXY_HTTP_PROXY} ]; then
    printHeaderMessage "Setting HTTP Proxy for ${PROJECT_NAME}"
    echo "export http_proxy=${OCP_PROXY_HTTPS_PROXY}"
    export http_proxy=${OCP_PROXY_HTTP_PROXY}
    echo "export NO_PROXY=${OCP_PROXY_NO_PROXY}"
    export NO_PROXY=${OCP_PROXY_NO_PROXY}
  fi
fi
if [ -z ${https_proxy} ]; then
  if [ ! -z ${OCP_PROXY_HTTPS_PROXY} ]; then
      printHeaderMessage "Setting HTTPS Proxy for ${PROJECT_NAME}"
      echo "export https_proxy=${OCP_PROXY_HTTPS_PROXY}"
      export https_proxy=${OCP_PROXY_HTTPS_PROXY}
      echo "export NO_PROXY=${OCP_PROXY_NO_PROXY}"
      export NO_PROXY=${OCP_PROXY_NO_PROXY}
  fi
fi

#Start of Main logic
####################################################################
if [ -z ${1} ] ;
then
  echo "Please run again with one of the following arguments:"
  ls  ${DATA_DIR}/${PROJECT_NAME}/env/*env* |  sed 's/-env.sh//g'  | grep -v "samples" | sed 's/.*\///g'
  echo "${RED_TEXT}Exiting Script!!!!!!!${RESET_TEXT}"
  exit 99
  #read -p "${BLUE_TEXT}Which env file do you want to run with    :  ${RESET_TEXT}" ENVIRONMENT_FILE
else
   ENVIRONMENT_FILE=${1}
fi

if [ ${ENVIRONMENT_FILE} != "skip" ]; then
    if [ ! -f ${DATA_DIR}/${PROJECT_NAME}/env/${ENVIRONMENT_FILE}-env.sh  ] ;then
      echo "${RED_TEXT}${ENVIRONMENT_FILE} does NOT exists in ${DATA_DIR}/${PROJECT_NAME}/env/ !${RESET_TEXT}"
      echo "Please run again with one of the following arguments:"
      ls  ${DATA_DIR}/${PROJECT_NAME}/env/*env* |  sed 's/-env.sh//g' | grep -v "samples" | sed 's/.*\///g'
      echo "${RED_TEXT}Exiting Script!!!!!!!${RESET_TEXT}"
      exit 99
    fi
fi


#Run Core steps now
#############################
if [ ${ENVIRONMENT_FILE} != "skip" ]; then
    source ${DATA_DIR}/${PROJECT_NAME}/env/${ENVIRONMENT_FILE}-env.sh
    mkdir -p ${LOG_DIR}
    mkdir -p ${TEMP_DIR}
    preChecks
fi
