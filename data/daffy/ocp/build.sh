#!/bin/bash
############################################################
#Author           : Kyle Dawson
#Author email     : Kyle.Dawson@us.ibm.com
#Original Date    : 2020-04-28
#Initial Version  : v2021-12-01
############################################################
#Setup Variables
############################################################
DIR="$( cd "$( dirname "$0" )" && pwd )"
PRODUCT_SHORT_NAME=ocp
PRODUCT_FUNCTION=build
ENVIRONMENT_FILE=${1}
source ${DIR}/../env/${1}-env.sh &> /dev/null
source ${DIR}/../env.sh
source ${DIR}/env.sh
source ${DIR}/functions.sh
source ${DIR}/../functions.sh
source ${DIR}/../fixpaks/env.sh

start=$SECONDS

#Source other functions
#############################################
source ${DATA_DIR}/${PROJECT_NAME}/${PRODUCT_SHORT_NAME}/openshift.sh
source ${DATA_DIR}/${PROJECT_NAME}/${PRODUCT_SHORT_NAME}/util/displayPreWork.sh
source ${DATA_DIR}/${PROJECT_NAME}/util/providers/vmware.sh
source ${DATA_DIR}/${PROJECT_NAME}/util/providers/aws.sh
source ${DATA_DIR}/${PROJECT_NAME}/util/providers/azure.sh
source ${DATA_DIR}/${PROJECT_NAME}/util/providers/gcp.sh
source ${DATA_DIR}/${PROJECT_NAME}/util/ibmcloud.sh
source ${DATA_DIR}/${PROJECT_NAME}/util/tshirt.sh
source ${DATA_DIR}/${PROJECT_NAME}/util/kvm.sh
source ${DATA_DIR}/${PROJECT_NAME}/util/providers/macos.sh
#source ${DATA_DIR}/${PROJECT_NAME}/util/providers/rosa.sh

#Prep Steps
#####################################
OS
if [ "${MAC}" == "true" ]; then
   macCheckOCP
   macPrepareHost
   macSetupContainer
   macGetDaffy
   macCopyEnvFile
   case ${2} in
     --MACinstallOCPTools)
        macInstallOCPTools
        exit 99
        ;;
     --*)
        echo "Running container with podman exec -it daffy /bin/bash -c "/data/daffy/ocp/build.sh ${ENVIRONMENT_FILE} ${2}""
        echo "${RESET_TEXT}"
        echo ""
        podman exec -it daffy /bin/bash -c "/data/daffy/ocp/build.sh ${ENVIRONMENT_FILE} ${2}"
        exit 99 # Exiting script due to work being done in container
        ;;
   esac
fi

mkdir -p ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/
mkdir -p ${LOG_DIR}/${PRODUCT_SHORT_NAME}/
chmod -fR 777 ${DATA_DIR}/${PROJECT_NAME}/
OCP_FUNCTION_NAME="OpenShift Build Process"
case ${2} in
  --precheck|--Precheck)
        printHeaderMessage "Running Precheck only"
        prepareOCPInputFiles
        preChecksOCP
        exit 0
        ;;
   --updateIngress)
        logIntoCluster
        updateIngressCert
        exit 0
        ;;
   --tshirtSize)
         defineVMTShirtSize
         exit 0
         ;;
   --approveCSR)
        defineVMTShirtSize &> /dev/null
        logIntoCluster
        approveADMCerts "NoWait"
        exit 0
        ;;
   --createNFSServer)
      logIntoCluster
       createNFSServer
       exit 0
       ;;
   --console|--Console)
      logIntoCluster
      getClusterInfo
      displayAdminConsoleInfo
      exit 0
      ;;
   --status|--Status|--AllStatus)
       logIntoCluster
       displayClusterInfo
       exit 0
       ;;
   --createIBMCloudDNSEntries)
      createIBMCloudDNSEntries
      exit 0
      ;;
   --removeIBMCloudDNSEntries)
      removeIBMCloudDNSEntries
      exit 0
      ;;
   --displayOCPDNSRequirements)
      displayOCPDNSRequirements
      exit 0
      ;;
   --displayOCPLoadBalanceRules)
      displayOCPLoadBalanceRules
      exit 0
      ;;
   --runOpenShiftInstaller)
      RUN_CSR_APPROVE_PROCESS=false
      runOpenShiftInstaller
      exit 0
      ;;
   --runOpenShiftInstallWaitBoot)
      RUN_CSR_APPROVE_PROCESS=false
      runOpenShiftInstallerBootstrapComplete
      exit 0
      ;;
   --runOpenShiftInstallWaitInstall)
      RUN_CSR_APPROVE_PROCESS=false
      runOpenShiftInstallerInstallComplete
      exit 0
      ;;
   --createOpenShiftContainerStorage)
      logIntoCluster
      validOCPVersion
      defineVMTShirtSize &> /dev/null
      shouldExit
      prepareOCPInputFiles
      configureOpenShiftContainerStorage
      exit 0
      ;;
  --configureLocalStorge)
      logIntoCluster
      validOCPVersion
      shouldExit
      configureOpenShiftContainerStorage
      configureLocalStorge
      exit 0
      ;;
   --approveVCenterCert)
      approveVCenterCert
      exit 0
      ;;
   --displayVSpherePermissionsNeeded)
       displayVSpherePermissionsNeeded
       exit 0
       ;;
   --createVMDashboard)
       createVMDashboard
       exit 0
       ;;
   --createImageRegistry)
       logIntoCluster
       createImageRegistryPostInstall
       exit 0
       ;;
   --applyFix)
       logIntoCluster
       applyFix $3
       exit 0
       ;;
   --deleteAllFailedPods)
       logIntoCluster
       ocpDeleteAllFailedPods
       exit 0
       ;;
   --installOpenShiftTools)
       getOpenShift
       exit 0
       ;;
   --validateReserverLookupDNS)
       validateReserverLookupDN
       exit 0
       ;;
   --MACinstallOCPTools)
       macInstallOCPTools
       exit 0
       ;;
   --help|--?|?|-?|help|-help|--Help|-Help)
        printHeaderMessage "Help Menu for build flags"
        echo "--precheck                            This will just do a quick precheck to see if the environment is ready for a build"
        echo "--tshirtSize                          This will display what the current TShirt size would be with this environment"
        echo "--createIBMCloudDNSEntries            This will create your Public DNS enries in IBM Cloud"
        echo "--approveVCenterCert                  This will download VCenter certs and add to host trust store."
        echo "--removeIBMCloudDNSEntries            This will remove your Public DNS enries in IBM Cloud"
        echo "--displayOCPDNSRequirements           This will display what DNS records that need to be created"
        echo "--displayOCPLoadBalanceRules          This will display the Load Balnacer rules you will need"
        echo "--runOpenShiftInstallWaitBoot         This will run openshift-install (wait-for boot)"
        echo "--approveCSR                          This will approve all pending CSR request"
        echo "--runOpenShiftInstallWaitInstall      This will run openshift-install (wait-for install)"
        echo "--updateIngress                       This will get new IBM Cert and update the main ingress certs/secret"
        echo "--createOpenShiftContainerStorage     This will create OpenShift Container Storage"
        echo "--createNFSServer                     This will create local NFS Server"
        echo "--configureLocalStorge                This will create local stroage"
        echo "--createVMDashboard                   This will create the VM Dashboard Web UI"
        echo "--createImageRegistry                 This will create the OpenShift Image Registry"
        echo "--console                             This will display Admin Console Info"
        echo "--status                              This will display cluster info"
        echo "--installOpenShiftTools               This will install oc, kubectl and openshift-install tools"
        echo "--displayVSpherePermissionsNeeded     This will display all permissions needed for VSphere Install"
        echo "--validateReserverLookupDNS           This will validate PTR records for UPI installs"
        echo "--applyFix                            This will apply a given fix to your Daffy env, pass the fix number to command"
        echo "--deleteAllFailedPods                 This will delete all pods in Failed state."
        echo "--MACinstallOCPTools                  This will install oc and kubectl tools locally on your Mac"
        echo "--help|--?|?|-?|help|-help            This help menu"
        echo ""
        exit 0
        ;;
    --*|-*)
        echo "${RED_TEXT}Unsupported flag in command line - ${2}. ${RESET_TEXT}"
        echo ""
        exit 9
        ;;
esac
#Get Ready to run
#############################################
if [ "${MAC}" == "true" ]; then
   macOCPBuild
   exit 99 #Exiting script due to work being done in container
fi
preChecksOCP
updateDaffyStats
prepareOCPInputFiles
getOpenShift

case ${OCP_INSTALL_TYPE} in
    vsphere-upi)
        createVMWareFoldersFullPath
        addLocalRegistryAuthInfo
        printf "\npullSecret: '${PULL_SECRET}'\n" >> ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/install-config.yaml
        getSSHPublicKey
        printf "\nsshKey: '${SSH_KEY}'\n" >> ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/install-config.yaml
        enableLocalRegistryPull ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/install-config.yaml
        #Start Core Commands
        ##################################################
        #prepareHost
        installLoadBalancer
        createDNSDHCPPXE
        createManifestFiles
        createIgnitionFiles
        createAllVSphereImages
        updateAllVSphereImageIPSettings
        deployAllIgnitionFiles
        rebootAllVMImages
        runOpenShiftInstallerBootstrapComplete
        runOpenShiftInstallerInstallComplete
        ;;
    kvm-upi)
        enableLocalRegistryPull ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/install-config.yaml
        addLocalRegistryAuthInfo
        printf "\npullSecret: '${PULL_SECRET}'\n" >> ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/install-config.yaml
        getSSHPublicKey
        printf "\nsshKey: '${SSH_KEY}'\n" >> ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/install-config.yaml
        enableLocalRegistryPull ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/install-config.yaml
        #Start Core Commands
        ##################################################
        #prepareHost
        createVMDashboard
        createNetwork
        installLoadBalancer
        createDNSDHCPPXE
        matchBox
        createIgnitionFilesMatchBox
        createBootstrapVM
        createOtherVMs
        bootstrapSystem
        runOpenShiftInstallerBootstrapComplete
        runOpenShiftInstallerInstallComplete
        ;;
    vsphere-ipi)
        createVMWareFoldersFullPath
        cp ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/providers/vsphere/install-config.yaml ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/install-config.yaml
        addLocalRegistryAuthInfo
        printf "\npullSecret: '${PULL_SECRET}'\n" >> ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/install-config.yaml
        getSSHPublicKey
        printf "\nsshKey: '${SSH_KEY}'\n" >> ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/install-config.yaml
        enableLocalRegistryPull ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/install-config.yaml
        #Start Core Commands
        ##################################################
        #prepareHost
        runOpenShiftInstallerCreateCluster
        ;;
    aws-ipi)
        cp ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/providers/aws/install-config.yaml ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/install-config.yaml
        enableLocalRegistryPull ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/install-config.yaml
        addLocalRegistryAuthInfo
        printf "\npullSecret: '${PULL_SECRET}'\n" >> ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/install-config.yaml
        getSSHPublicKey
        printf "\nsshKey: '${SSH_KEY}'\n" >> ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/install-config.yaml
        enableLocalRegistryPull ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/install-config.yaml
        #Start Core Commands
        ##################################################
        runOpenShiftInstallerCreateCluster
        ;;
    azure-ipi)
        cp ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/providers/azure/install-config.yaml ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/install-config.yaml
        enableLocalRegistryPull ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/install-config.yaml
        printf "\npullSecret: '${PULL_SECRET}'\n" >> ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/install-config.yaml
        getSSHPublicKey
        printf "\nsshKey: '${SSH_KEY}'\n" >> ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/install-config.yaml
        #Start Core Commands
        ##################################################
        runOpenShiftInstallerCreateCluster
        ;;
    gcp-ipi)
        cp ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/providers/gcp/install-config.yaml ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/install-config.yaml
        enableLocalRegistryPull ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/install-config.yaml
        printf "\npullSecret: '${PULL_SECRET}'\n" >> ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/install-config.yaml
        getSSHPublicKey
        printf "\nsshKey: '${SSH_KEY}'\n" >> ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/install-config.yaml
        #Start Core Commands
        ##################################################
        runOpenShiftInstallerCreateCluster
        ;;
    roks-msp)
        createROKSCluster
        waitForROKSClusterReady
        ;;
    #rosa-msp)
        #Start Core Commands
        ##################################################
        #createROSACluster
        #createROSAAdmin
        #;;
     *)
        echo "${RED_TEXT}Unsupported OCP_INSTALL_TYPE. Supported values would be vsphere-upi, vsphere-ipi, gcp-ipi, azure-ipi, aws-ipi or kvm-upi.${RESET_TEXT}"
        echo "${RED_TEXT}You set OCP_INSTALL_TYPE=${OCP_INSTALL_TYPE}${RESET_TEXT}"
        exit 99
        ;;
esac

#Final Cluster setup
###########################
case ${OCP_INSTALL_TYPE} in
    *upi)
        deleteBootstrapVMs
        ;;&
    *-upi|*-ipi|*-msp)
        if [ ${OCP_CREATE_NFS_STORAGE} = "true" ] ;then
            validOCPVersion
            createNFSServer
        fi
        ;;&
    *-upi|*-ipi)
        if [ ${OCP_CREATE_OPENSHIFT_CONTAINER_STORAGE} = "true" ] ;then
            configureOpenShiftContainerStorage
        fi
        cp -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/ocp-install/.openshift_install.log  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/openshift_install.log
        createImageRegistry
        updateIngressCert
        savekubeconfig
        ocpCreateAdminAccount
        displayClusterInfo
        ;;
    #rosa-msp)
        #if [ ${OCP_CREATE_OPENSHIFT_CONTAINER_STORAGE} = "true" ] ;then
            #ROSALoginCluster
            #ROSACreateStorageNodes
            #configureOpenShiftContainerStorage
        #fi
        #;;
esac
displayAdminConsoleInfo
consoleFooter "${OCP_FUNCTION_NAME}"
