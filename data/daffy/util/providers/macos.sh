#!/bin/bash
############################################################
#Author           : Jeff Imholz
#Author email     : jimholz@us.ibm.com
#Original Date    : 2022-05-01
#Initial Version  : v2022-05-01
############################################################
macCheckOCP()
{
  printHeaderMessage "Checking for valid OCP type"
  case ${PRODUCT_SHORT_NAME} in
    ocp)
        case ${OCP_INSTALL_TYPE} in
          aws-ipi|gcp-ipi|azure-ipi|roks-msp)
              echo "${BLUE_TEXT}PASSED ${RESET_TEXT} Valid OCP_INSTALL_TYPE of ${OCP_INSTALL_TYPE} for ${PRODUCT_SHORT_NAME}"
              ;;
          *)
              echo "${RED_TEXT}Unsupported OCP_INSTALL_TYPE of ${OCP_INSTALL_TYPE} for ${PRODUCT_SHORT_NAME} ${RESET_TEXT}"
              echo "${RED_TEXT} Exiting Script!!!!!"
              exit 99
              ;;
        esac
    ;;
  esac
}

macPrepareHost()
{
  printHeaderMessage "Prepare HOST (LOG -> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/brew.log)"
  mkdir -p ${LOG_DIR}/${PRODUCT_SHORT_NAME}
  mkdir -p ${TEMP_DIR}/${PRODUCT_SHORT_NAME}
  if [ ${IS_MAC} == 1 ] ;then
      BREW_INSTALLED=`brew config | grep -c HOMEBREW_VERSION`
      if [ ${BREW_INSTALLED} == 1 ] ;then
          echo "Brew installed continuing on"
          SHELL=`env | grep SHELL > ${LOG_DIR}/${PRODUCT_SHORT_NAME}/bash.log`
          SHELL=`cat ${LOG_DIR}/${PRODUCT_SHORT_NAME}/bash.log | grep -c "bin/bash"`
          if [ ${SHELL} == 1 ] ;then
              echo "Bash Profile found, continuing on"
          else
              echo "${RED_TEXT}FAILED Bash Profile not found, exiting script"
              echo "${RED_TEXT}FAILED Please run: chsh -s /bin/bash, exit your terminal and open a new one"
              echo "${RED_TEXT}FAILED Once opened, run: touch ~/.bash_profile"
              echo "${RED_TEXT}Exiting Script!!!!!!!${RESET_TEXT}"
              exit 99
          fi
      else
          echo "${RESET_TEXT}Brew not installed, installing it now, this could take 10 minutes"
          /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)" >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/brew.log
          echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.bash_profile
          eval "$(/opt/homebrew/bin/brew shellenv)"
      fi
      XCODE_INSTALLED=`xcode-select --version | grep -c version`
      if [ ${XCODE_INSTALLED} == 1 ] ;then
          echo "${RESET_TEXT}Apple developer tools installed, continuing on"
      else
          echo "${RED_TEXT}FAILED Apple developer tools not installed, exiting script"
          echo "${RED_TEXT}FAILED Please run xcode-select --install from command line"
          echo "Install will take up to 30 minutes"
          echo "${RED_TEXT}Exiting Script!!!!!!!${RESET_TEXT}"
          exit 99
      fi
      #echo "${RESET_TEXT} running brew install tree wget jq gnu-sed expect"
      #brew install tree wget jq gnu-sed expect >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/brew.log
      PODMAN_INSTALLED=`podman -v  2> /dev/null | grep -c version`
      if [ "${PODMAN_INSTALLED}" == 1 ]; then
          echo "Podman installed, continuing on"
          PODMAN_INIT=`podman machine list 2> /dev/null | grep -c podman-machine`
          podman info 2&> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/podman.log
          PODMAN_START=`cat ${LOG_DIR}/${PRODUCT_SHORT_NAME}/podman.log | grep -c Error`
          if [ "${PODMAN_INIT}" == 1 ] && [ "${PODMAN_START}" == 1 ]; then
              echo "Podman is ready, continuing on"
              echo ""
          elif [ "${PODMAN_INIT}" == 0 ] && [ "${PODMAN_START}" == 1 ]; then
              echo "Podman is not initialized or running. Starting podman"
              podman machine init &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/podman-status.log
              podman machine start &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/podman-up.log
          elif [ "${PODMAN_INIT}" == 1 ] && [ "${PODMAN_START}" == 0 ]; then
              echo "Podman not running, starting it now"
              podman machine start &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/podman-up.log
          fi
      else
          echo "${RESET_TEXT}Podman not installed, installing it now, this could take 10-15 minutes"
          brew install podman -q >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/podman.log
          echo "Initializing and starting podman"
          podman machine init &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/podman-status.log
          podman machine start &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/podman-up.log
      fi
  else
      echo "invalid OS"
  fi
  echo "${RESET_TEXT}"
}

macSetupContainer()
{
  printHeaderMessage "Setting up Podman for Ubuntu container"
  echo "Checking for container, if not there pulling it"
  CONTAINER_EXISTS=`podman images | grep "docker.io/library/ubuntu" | grep -c 20.04`
  if [ ${CONTAINER_EXISTS} == 1 ]; then
      echo "Ubuntu 20.04 container exists, checking to see if its been used"
      CONTAINER_USE=`podman run -d --env DEBIAN_FRONTEND=noninteractive --env DEBCONF_NONINTERACTIVE_SEEN=true --env TERM=linux --env OS_FLAVOR=macOS --name=daffy -it ubuntu:20.04 &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/container.log`
      CONTAINER_USE=`cat ${LOG_DIR}/${PRODUCT_SHORT_NAME}/container.log | grep -c Error`
      CONTAINER_START=`cat ${LOG_DIR}/${PRODUCT_SHORT_NAME}/container.log | grep -c "connection refused"`
      if [ ${CONTAINER_USE} == 1 ] && [ ${CONTAINER_START} == 1 ]; then
          echo "Container has previously been named and in use"
      elif [ ${CONTAINER_USE} == 1 ] && [ ${CONTAINER_START} == 0 ]; then
          echo "Running: podman run -d --name=daffy -it ubuntu:20.04"
          podman start daffy
          podman run -d --env DEBIAN_FRONTEND=noninteractive --env DEBCONF_NONINTERACTIVE_SEEN=true --env TERM=linux --env OS_FLAVOR=macOS --name=daffy -it ubuntu:20.04 &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/container.log
          podman cp ${DATA_DIR}/${PROJECT_NAME}/ocp/templates/mac/preseed.txt daffy:/root
          podman exec -it daffy /bin/bash -c "debconf-set-selections /root/preseed.txt"
      fi
  else
      echo "Ubuntu container does not exist, pulling it now"
      echo "Running: podman pull ubuntu:20.04"
      podman pull ubuntu:20.04 &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ubuntu-pull.log
      macSetupContainer
  fi
}

macGetDaffy()
{
  printHeaderMessage "Obtaining Daffy for Ubuntu container if it doesn't exist"
  echo "Checking to see if Daffy previously installed"
  DAFFY_INSTALLED=`podman exec -it daffy /bin/bash -c "ls -d /data/daffy 2> /dev/null | grep -c daffy"`
  DAFFY_INSTALLED=`echo ${DAFFY_INSTALLED} | grep -c 1`
  DAFFY_VERSION=`${DATA_DIR}/${PROJECT_NAME}/version.sh &> ${LOG_DIR}/daffy_version.log`
  DAFFY_LOCAL=`cat ${LOG_DIR}/daffy_version.log | grep Daffy | awk '{print $5}'`
  DAFFY_BETA=`cat ${LOG_DIR}/daffy_version.log | grep -c "BETA\|beta"`
  echo "Your local version of Daffy is ${DAFFY_LOCAL}"
  if [ ${DAFFY_INSTALLED} == 0 ]; then
    echo "Daffy is not installed, installing now. At prompt please accept Agreement to continue"
    if [ ${DAFFY_BETA} == 1 ]; then
      echo "You have beta installed locally, doing the same in container"
      echo "Running: podman exec -it daffy /bin/bash -c apt-get -y update; apt-get install -y curl wget"
      podman exec -it daffy /bin/bash -c "apt-get -y update" &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/daffy_install.log
      podman exec -it daffy /bin/bash -c "apt-get install -y curl wget apt-utils" >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/daffy_install.log
      echo "Running: podman exec -it daffy /bin/bash -c wget http://get.daffy-installer.com:1887/download-scripts/daffy-beta-init.sh; chmod 777 daffy-beta-init.sh;./daffy-beta-init.sh"
      podman exec -it daffy /bin/bash -c "wget http://get.daffy-installer.com:1887/download-scripts/daffy-beta-init.sh -P /root"
      podman exec -it daffy /bin/bash -c "chmod 777 /root/daffy-beta-init.sh"
      podman exec -it daffy /bin/bash -c "/root/daffy-beta-init.sh"
    else
      echo "You have production installed locally, doing the same in container"
      echo "Running: podman exec -it daffy /bin/bash -c apt-get -u update; apt-get install -y curl wget"
      podman exec -it daffy /bin/bash -c "apt-get -y update" &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/daffy_install.log
      podman exec -it daffy /bin/bash -c "apt-get install -y curl wget apt-utils" >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/daffy_install.log
      echo "Running: podman exec -it daffy /bin/bash -c wget http://get.daffy-installer.com:1887/download-scripts/daffy-init.sh; chmod 777 daffy-init.sh;./daffy-init.sh"
      podman exec -it daffy /bin/bash -c "wget http://get.daffy-installer.com:1887/download-scripts/daffy-init.sh -P /root"
      podman exec -it daffy /bin/bash -c "chmod 777 /root/daffy-init.sh"
      podman exec -it daffy /bin/bash -c "/root/daffy-init.sh"
    fi
  else
    echo "Daffy is installed. continuing on"
    DAFFY_CONTAINER=`podman exec -it daffy /bin/bash -c "/data/daffy/version.sh" &> ${LOG_DIR}/daffy_container.log`
    DAFFY_CONTAINER=`cat ${LOG_DIR}/daffy_container.log | grep Daffy | awk '{print $5}'`
    echo "Your container version of Daffy is ${DAFFY_CONTAINER}"
  fi

  echo ""
  #echo "Checking to see if what Daffy version you are using"
  #DAFFY_LOCAL=`${DATA_DIR}/${PROJECT_NAME}/version.sh > ${LOG_DIR}/local_daffy.log`
  #DAFFY_LOCAL=`cat ${LOG_DIR}/local_daffy.log | grep Daffy | awk '{print $5}'`
  #echo "Your local version of Daffy is ${DAFFY_LOCAL}"
  #DAFFY_CONTAINER=`podman exec -it daffy /bin/bash -c "/data/daffy/version.sh" &> ${LOG_DIR}/daffy_container.log`
  #DAFFY_CONTAINER=`cat ${LOG_DIR}/daffy_container.log | grep Daffy | awk '{print $5}'`
  #echo "Your container version of Daffy is ${DAFFY_CONTAINER}"
  #if [ ${DAFFY_LOCAL} == ${DAFFY_CONTAINER} ]; then
  #    echo "Daffy versions match, continuing on"
  #elif [ ${DAFFY_LOCAL} < ${DAFFY_CONTAINER} ]; then
  #    echo "${RED_TEXT}FATAL ${RESET_TEXT}Daffy versions don't match. The local version ${DAFFY_LOCAL}. The container version is ${DAFFY_CONTAINER}"
  #    echo "Please update your local version"
  #    echo "Run: wget http://get.daffy-installer.com:1887/download-scripts/daffy-init.sh; chmod 777 daffy-init.sh;./daffy-init.sh "
  #    echo "${RED_TEXT}Exiting Script!!!!!!!${RESET_TEXT}"
  #    exit 99
  #fi
}

macCopyEnvFile()
{
  printHeaderMessage "Copying local env file to container"
  echo "Copying ${ENVIRONMENT_FILE}-env.sh to container"
  echo "Running: podman cp ${DATA_DIR}/${PROJECT_NAME}/env/${ENVIRONMENT_FILE}-env.sh daffy:/data/daffy/env/"
  podman cp ${DATA_DIR}/${PROJECT_NAME}/env/${ENVIRONMENT_FILE}-env.sh daffy:/data/daffy/env/
  ENV_FILE_EXISTS=`podman exec -it daffy /bin/bash -c "ls -f /data/daffy/env/${ENVIRONMENT_FILE}-env.sh | grep -c ${ENVIRONMENT_FILE}"`
  if [ "${ENV_FILE_EXISTS}" == 0 ]; then
      echo "Environment file does not exist, trying to copy again"
      podman cp ${DATA_DIR}/${PROJECT_NAME}/env/${ENVIRONMENT_FILE}-env.sh daffy:/data/daffy/env/
  else
      echo "Environment file ${ENVIRONMENT_FILE} successfully copied to container"
  fi
}

macOCPBuild()
{
  printHeaderMessage "Beginning Install of ${CLUSTER_NAME} using container"
  case ${PRODUCT_SHORT_NAME} in
    ocp)
        case ${OCP_INSTALL_TYPE} in
          gcp-ipi)
              echo "Checking for Google credentials"
              if [ -f ~/.gcp/osServiceAccount.json ]; then
                echo "Google credentials exist locally, copying to container"
                podman cp ~/.gcp daffy:/root/
              else
                echo "${RED_TEXT}Missing GCP ~/.gcp/osServiceAccount.json${RESET_TEXT}"
                echo "Please copy your GCP Service account JSON Identity file here :"
                echo "~/.gcp/osServiceAccount.json"
                echo "Once you add the new file, please try again."
                echo ""
                echo ""
                echo "Exiting Script!!!!!!!"
                exit 99
              fi
              podman cp ${DATA_DIR}/${PROJECT_NAME}/certs/ daffy:/data/daffy/
              ;;
          *)
              podman cp ${DATA_DIR}/${PROJECT_NAME}/certs/ daffy:/data/daffy/
              ;;
        esac
  esac
  echo "Running: podman exec -it daffy /bin/bash -c /data/daffy/ocp/build.sh ${ENVIRONMENT_FILE}"
  podman exec -it daffy /bin/bash -c "/data/daffy/ocp/build.sh ${ENVIRONMENT_FILE}"
  podman cp daffy:/data/daffy/tmp ${TEMP_DIR}
  podman cp daffy:/data/daffy/log ${LOG_DIR}
  case ${PRODUCT_SHORT_NAME} in
    ocp)
        case ${OCP_INSTALL_TYPE} in
          aws-ipi)
              podman cp daffy:/root/.aws ~/
              ;;
          azure-ipi)
              podman cp daffy:/root/.azure ~/
              ;;
        esac
  esac
  echo "${RESET_TEXT}"
}

macOCPCleanup()
{
  printHeaderMessage "Beginning Cleanup of ${CLUSTER_NAME} using container"
  echo "Running: podman exec -it daffy /bin/bash -c "/data/daffy/ocp/cleanup.sh ${ENVIRONMENT_FILE}""
  podman exec -it daffy /bin/bash -c "/data/daffy/ocp/cleanup.sh ${ENVIRONMENT_FILE}"
  echo "${RESET_TEXT}"
}

macInstallOCPTools()
{
  printHeaderMessage "Installting tools locally on your mac"
  if [ "${MAC}" != "true" ]; then
      echo "You are not runnig on a mac. Exiting function as only supported on macOS"
      exit 99
  fi
  unset KUBECONFIG
  FOUND_OC_COMMAND=`oc version 2> /dev/null | grep -c "Client Version: ${OCP_RELEASE}"`
  if [ "${FOUND_OC_COMMAND}" == "0"  ] ;then
      echo "Missing correct version of oc command line tools - downloading now "
      echo "wget ${OPENSHIFT_SITE_DOWNLOAD}/pub/openshift-v4/clients/ocp/${OCP_RELEASE}/openshift-client-mac-${OCP_RELEASE}.tar.gz"
      wget ${OPENSHIFT_SITE_DOWNLOAD}/pub/openshift-v4/clients/ocp/${OCP_RELEASE}/openshift-client-mac-${OCP_RELEASE}.tar.gz 2> /dev/null
      if [ ! -f openshift-client-mac-${OCP_RELEASE}.tar.gz ]; then
        echo "${RED_TEXT}Failed to download openshift-client, unable to continue:"
        echo "${OPENSHIFT_SITE_DOWNLOAD}/pub/openshift-v4/clients/ocp/${OCP_RELEASE}/openshift-client-mac-${OCP_RELEASE}.tar.gz${RESET_TEXT}"
        exit 99
      fi
      tar xvf openshift-client-mac-${OCP_RELEASE}.tar.gz &> /dev/null
      echo "Copying OpenShift command line tools to local workstation"
      echo "If prompted for a password, please enter your local workstation passwords"
      sudo mv oc /usr/local/bin/
      sudo mv kubectl /usr/local/bin
      rm -rf openshift-client-mac-${OCP_RELEASE}.tar.gz README.md
   else
      echo "Correct version of oc tools found, will not download."
   fi
   oc version 2> /dev/null
}
