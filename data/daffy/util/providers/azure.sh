#!/bin/bash
############################################################
#Author           : Kyle Dawson
#Author email     : Kyle.Dawson@us.ibm.com
#Original Date    : 2021-09-25
#Initial Version  : v2021-12-01
############################################################
#https://support.lacework.com/hc/en-us/articles/360029107274-Gather-the-Required-Azure-Client-ID-Tenant-ID-and-Client-Secret
saveAzureCredentials()
{
  printHeaderMessage "Azure Credentials"
  if [ ! -f  ~/.azure/osServicePrincipal.json ]; then
      mkdir -p ~/.azure
      if [ -z "${AZURE_CLIENT_SECRET}" ]; then
          echo "Missing AZURE_CLIENT_SECRET, please enter here so we can save to ~/.azure/osServicePrincipal.json"
          unset AZURE_CLIENT_SECRET;
          echo -n "AZURE_CLIENT_SECRET=${BLUE_TEXT}"
          while IFS= read -r -s -n1 pass; do
            if [[ -z $pass ]]; then
               echo
               break
            else
               echo -n '*'
               AZURE_CLIENT_SECRET+=$pass
            fi
          done
          echo ${RESET_TEXT}
          export AZURE_CLIENT_SECRET=${AZURE_CLIENT_SECRET}
          echo "export AZURE_CLIENT_SECRET=${AZURE_CLIENT_SECRET}" >> ~/.profile
      fi
      cp -fR ${DATA_DIR}/${PROJECT_NAME}/${PRODUCT_SHORT_NAME}/templates/providers/azure/osServicePrincipal.json ${TEMP_DIR}/${PRODUCT_SHORT_NAME}
      find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@AZURE_CLIENT_SECRET@/$AZURE_CLIENT_SECRET/g"
      find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@AZURE_SUBSCRIPTION_ID@/$AZURE_SUBSCRIPTION_ID/g"
      find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@AZURE_CLIENT_ID@/$AZURE_CLIENT_ID/g"
      find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@AZURE_TENANT_ID@/$AZURE_TENANT_ID/g"
      mv -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/osServicePrincipal.json ~/.azure/osServicePrincipal.json
      echo  "${BLUE_TEXT}PASSED ${RESET_TEXT} Built new Key -  ~/.azure/osServicePrincipal.json"
  else
      echo  "${BLUE_TEXT}PASSED ${RESET_TEXT} Using existing Key -  ~/.azure/osServicePrincipal.json"
  fi
  echo ""

}
azLogincli()
{
     AZ_LOGIN_FAILED=`az login --service-principal -u ${AZURE_CLIENT_ID} -p ${AZURE_CLIENT_SECRET} --tenant ${AZURE_TENANT_ID} | grep -c error`
     if [  ${AZ_LOGIN_FAILED} -ge 1 ]; then
       echo "${RED_TEXT}FAILED: Unable to login via azure-cli ${RESET_TEXT}"
       echo "${RED_TEXT}Unable to continue, exit process now!!!!!!!!${RESET_TEXT}"
       echo ""
       echo "Exiting Script!!!!!!!"
       exit 9
     fi
}
updateAzureInstallConfig()
{
  NEW_VM_WORKER_DISK1=`echo ${VM_WORKER_DISK1} |  sed  "s/\([a-zA-Z]\)$//"`
  sed -i'' "s/diskSizeGB: ${VM_WORKER_DISK1}/diskSizeGB: ${NEW_VM_WORKER_DISK1}/" ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/providers/azure/install-config.yaml
  NEW_VM_MASTER_DISK1=`echo ${VM_MASTER_DISK1} |  sed  "s/\([a-zA-Z]\)$//"`
  sed -i'' "s/diskSizeGB: ${VM_MASTER_DISK1}/diskSizeGB: ${NEW_VM_MASTER_DISK1}/" ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/providers/azure/install-config.yaml
}

azInstallCommandline()
{
  printHeaderMessage "Install Azure command line tool (LOG  ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/azure-cli-install.log )"
  FOUND_AZ_COMMAND=`az --version 2> /dev/null | grep -c "azure-cli"`
  if [ ${FOUND_AZ_COMMAND} == 0 ] && [ ${IS_UBUNTU} == 1 ];then
    echo "Missing azure-cli, installing now."
    curl -sL https://aka.ms/InstallAzureCLIDeb | bash &> ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/azure-cli-install.log
    #curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash &> ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/azure-cli-install.log
    #curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
    #apt-add-repository "deb [arch=$(dpkg --print-architecture)] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
    #apt install terraform
  elif [ ${FOUND_AZ_COMMAND} == 0 ] && [ ${IS_RH} == 1 ]; then
    echo "Missing azure-cli, installing now."
    rpm --import https://packages.microsoft.com/keys/microsoft.asc > ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/azure-cli-install.log
    cp ${DATA_DIR}/${PROJECT_NAME}/${PRODUCT_SHORT_NAME}/templates/providers/azure/azure-cli.repo /etc/yum.repos.d/
    $OS_INSTALL install azure-cli -y >> ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/azure-cli-install.log
    FOUND_AZ_COMMAND=`az --version 2> /dev/null | grep -c "azure-cli"`
    if [ ${FOUND_AZ_COMMAND} == 0 ] ;then
          echo "${RED_TEXT}FAILED: Unable to install azure-cli tool.${RESET_TEXT}"
          echo "${RED_TEXT}Unable to continue, exit process now!!!!!!!!${RESET_TEXT}"
          echo ""
          echo "Exiting Script!!!!!!!"
          exit 9
    fi
  else
    echo "${BLUE_TEXT}PASSED ${RESET_TEXT} azure-cli already installed."
  fi
  echo ""
}

azValidateAccessLevel()
{
  printHeaderMessage "Validate Azure Access Level"
  AZURE_USER_ACCESS_ADMINISTRATOR=`az role assignment list --all --assignee ${AZURE_CLIENT_ID} --output json --query '[].{principalName:principalName, roleDefinitionName:roleDefinitionName, scope:scope}' | grep -c "User Access Administrator"`
  if [[ ${AZURE_USER_ACCESS_ADMINISTRATOR} -ge 1 ]]; then
     echo "${BLUE_TEXT}PASSED ${RESET_TEXT} Client ID(${AZURE_CLIENT_ID}) has role of User Access Administrator for Subsription(${AZURE_SUBSCRIPTION_ID})"
  else
     echo "${RED_TEXT}FAILED: Client ID(${AZURE_CLIENT_ID}) does NOT have role of User Access Administrator for Subsription(${AZURE_SUBSCRIPTION_ID})"
     echo "${RESET_TEXT}"
     SHOULD_EXIT=1
  fi
  AZURE_CONTRIBUTOR=`az role assignment list --all --assignee ${AZURE_CLIENT_ID} --output json --query '[].{principalName:principalName, roleDefinitionName:roleDefinitionName, scope:scope}' | grep -c "Contributor"`
  if [[ ${AZURE_CONTRIBUTOR} -ge 1 ]]; then
     echo "${BLUE_TEXT}PASSED ${RESET_TEXT} Client ID(${AZURE_CLIENT_ID}) has role of Contributor for Subsription(${AZURE_SUBSCRIPTION_ID})"
  else
     echo "${RED_TEXT}FAILED: Client ID(${AZURE_CLIENT_ID}) does NOT have role of Contributor for Subsription(${AZURE_SUBSCRIPTION_ID})"
     echo "${RESET_TEXT}"
     SHOULD_EXIT=1
  fi
  echo ""
}

azValidateDNSZone()
{
  printHeaderMessage "Validate Azure DNS Zone"
  if [[ "${CURRENT_SCRIPT_NAME}" == *build.sh ]];then
      if [ "${AZURE_INSTALL_PUBLISH}" == "External" ]; then
          AZ_VALID_ZONE=`az network dns record-set list -g ${AZURE_BASE_DOMAIN_RESOURCE_GROUP_NAME} -z ${BASE_DOMAIN} | grep -c "\"fqdn\": \"${BASE_DOMAIN}.\""`
          if [[ ${AZ_VALID_ZONE} -ge 1 ]]; then
             echo "${BLUE_TEXT}PASSED ${RESET_TEXT} ${BASE_DOMAIN} is existing DNS Zone in Project(${AZURE_BASE_DOMAIN_RESOURCE_GROUP_NAME})"
          else
             echo "${RED_TEXT}FAILED: ${BASE_DOMAIN} NO existing DNS Zone in Project(${AZURE_BASE_DOMAIN_RESOURCE_GROUP_NAME}) and uable to create new one."
             echo "${RESET_TEXT}"
             SHOULD_EXIT=1
          fi
          AZURE_NS_NAME_LIST=`az network dns record-set list -g  ${AZURE_BASE_DOMAIN_RESOURCE_GROUP_NAME} -z ${BASE_DOMAIN} | grep nsdname |  awk '{print $2}' | sed 's/\"//g'`
          AZURE_NS_COUT=0
          for AZURE_NS_NAME in $AZURE_NS_NAME_LIST
          do
              FOUND_AZURE_NS=`dig ${BASE_DOMAIN} NS | grep NS | grep -c ${AZURE_NS_NAME}`
              if [ "${FOUND_AZURE_NS}"  == "1" ]; then
                let "AZURE_NS_COUT=${AZURE_NS_COUT}+1"
              fi
          done
          if [ ${AZURE_NS_COUT} -ne 4 ]; then
            echo "${RED_TEXT}FAILED: ${BASE_DOMAIN} is NOT pointing to the correct Azure NS Servers."
            echo "DNS Zone required NS should be :"
            echo "${AZURE_NS_NAME_LIST}"
            echo "Actual DNS NS :"
            dig ${BASE_DOMAIN} NS | grep NS |  grep -v ";" | awk '{print $5}'
            echo "${RESET_TEXT}"
          else
             echo "${BLUE_TEXT}PASSED ${RESET_TEXT} ${BASE_DOMAIN} is pointing to the correct Azure NS Servers."
          fi
      else
          echo "${BLUE_TEXT}INFO ${RESET_TEXT} AZURE_INSTALL_PUBLISH is Internal, skip DNS Zone check."
      fi
      echo ""
  fi
}

azLookupValidateQuota()
{
  local AZ_QUOTA_NAME=$1
  local AZ_REGION=$2
  local AZ_REQUIRED_QUOTA=$3
  AZURE_CURRENT_COUNT=`az vm list-usage --location ${AZ_REGION} -o table | grep "${AZ_QUOTA_NAME}" | awk '{print $(NF-1)}'`
  AZURE_MAX_COUNT=`az vm list-usage --location ${AZ_REGION} -o table | grep "${AZ_QUOTA_NAME}" | awk '{print $NF}'`
  let "AZURE_AVAILIBLE_COUNT = ${AZURE_MAX_COUNT} - ${AZURE_CURRENT_COUNT}"
  let "AZURE_NET_USE = ${AZURE_AVAILIBLE_COUNT} - ${AZ_REQUIRED_QUOTA}"
  if [[ ${AZURE_AVAILIBLE_COUNT} -le ${AZ_REQUIRED_QUOTA} ]]; then
     SHOULD_EXIT=1
     echo "${RED_TEXT}FAILED: Quota requirements for ${AZ_QUOTA_NAME} in ${AZ_REGION} - Shortage: ${AZURE_NET_USE}${RESET_TEXT}"
  else
      echo "${BLUE_TEXT}PASSED ${RESET_TEXT} Quota requirements for ${AZ_QUOTA_NAME} (Need ${AZ_REQUIRED_QUOTA}) in ${AZ_REGION} - Post Deployment Available: ${AZURE_NET_USE}"
  fi

}

azValidateQuota()
{
  if [[ "${CURRENT_SCRIPT_NAME}" == *build.sh ]]; then
      printHeaderMessage "Validate Azure Quota's"
      azLookupValidateQuota "${AZURE_VCPU_QUOTA_NAME}" ${AZURE_REGION} ${AZURE_MACHINE_TYPE_CPU_TOTAL}
      azLookupValidateQuota "Total Regional vCPUs" ${AZURE_REGION} ${AZURE_MACHINE_TYPE_CPU_TOTAL}
      echo ""
  fi

}


azAddOpenShiftContainerStorageDisk()
{
  printHeaderMessage "Create OpenShift Container Storage Disk on Azure"
  local VM_WORKER_DISK2=`echo ${VM_WORKER_DISK2}| sed "s/G$//g"`
  local VM_WORKER_DISK3=`echo ${VM_WORKER_DISK3}| sed "s/G$//g"`
  NODE_LIST=`oc get nodes | grep worker | awk '{print $1}'`
  local workerLoop=1
  for AZ_WORKER_NODE_NAME in $NODE_LIST
  do
       AZ_VM_RESOURCE_GROUP=`echo ${AZ_WORKER_NODE_NAME} | sed 's/-worker.*//g' `
       AZ_VM_RESOURCE_GROUP="${AZ_VM_RESOURCE_GROUP}-rg"
       echo "Creating and Attaching new disk - ${AZ_WORKER_NODE_NAME}-${IBM_OPENSHIFT_LOCAL_STORAGE_DEVICE_DISK2_NAME} --size ${VM_WORKER_DISK2} --type=${AZURE_WORKER_DISK2_TYPE}"
       az vm disk attach -g ${AZ_VM_RESOURCE_GROUP} --vm-name ${AZ_WORKER_NODE_NAME} --name ${AZ_WORKER_NODE_NAME}-${IBM_OPENSHIFT_LOCAL_STORAGE_DEVICE_DISK2_NAME}2 --new --sku ${AZURE_WORKER_DISK2_TYPE}  --size-gb ${VM_WORKER_DISK2}

       echo "Creating and Attaching new disk - ${AZ_WORKER_NODE_NAME}-${IBM_OPENSHIFT_LOCAL_STORAGE_DEVICE_DISK3_NAME} --size ${VM_WORKER_DISK3} --type=${AZURE_WORKER_DISK3_TYPE}"
       az vm disk attach -g ${AZ_VM_RESOURCE_GROUP} --vm-name ${AZ_WORKER_NODE_NAME} --name ${AZ_WORKER_NODE_NAME}-${IBM_OPENSHIFT_LOCAL_STORAGE_DEVICE_DISK3_NAME} --new --sku ${AZURE_WORKER_DISK3_TYPE}  --size-gb ${VM_WORKER_DISK3}

       case ${workerLoop} in
           1)
              OPEN_SHIFT_CONTAINTER_STORAGE_WORKER_NODE1=${AZ_WORKER_NODE_NAME}
              ;;
           2)
              OPEN_SHIFT_CONTAINTER_STORAGE_WORKER_NODE2=${AZ_WORKER_NODE_NAME}
              ;;
           3)
              OPEN_SHIFT_CONTAINTER_STORAGE_WORKER_NODE3=${AZ_WORKER_NODE_NAME}
              ;;
       esac
       let workerLoop=workerLoop+1
       if [ $workerLoop -gt 3 ]; then
         #only add disk to first three nodes.
         break
       fi
  done
  echo ""

}
azValidateResourceGroup()
{
    printHeaderMessage "Validate Azure Resource Group (LOG -> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/az-resourceGroup.log )"
    if [[ ${AZURE_RESOURCE_GROUP_NAME} ]]; then
      local AZ_RG_FOUND=`az group show --name ${AZURE_RESOURCE_GROUP_NAME} 2> /dev/null | grep -c "Microsoft.Resources/resourceGroups"`
      if [ ${AZ_RG_FOUND} -le 0 ]; then
        if [ "${AZURE_RESOURCE_GROUP_NAME_CREATE_MISSING}" == "true" ]; then
           echo "Creating new Resource Group" &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/az-resourceGroup.log
            az group create --name ${AZURE_RESOURCE_GROUP_NAME} --location ${AZURE_REGION} >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/az-resourceGroup.log 2>&1
            local AZ_RG_FOUND=`az group show --name ${AZURE_RESOURCE_GROUP_NAME} 2> /dev/null | grep -c "Microsoft.Resources/resourceGroups"`
            if [ ${AZ_RG_FOUND} -le 0 ]; then
              SHOULD_EXIT=1
              echo "${RED_TEXT}FAILED: Unable to create Resource Group - ${AZURE_RESOURCE_GROUP_NAME} --location ${AZURE_REGION} ${RESET_TEXT}"
            else
              if [ -n "${AZURE_GROUP_ID}"  ]; then
                echo "Assigning new role assignment -  ${AZURE_GROUP_ID} " >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/az-resourceGroup.log 2>&1
                az role assignment create --role "Contributor" --assignee-principal-type Group --assignee-object-id ${AZURE_GROUP_ID} -g ${AZURE_RESOURCE_GROUP_NAME} >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/az-resourceGroup.log 2>&1
              fi
              echo "${BLUE_TEXT}PASSED ${RESET_TEXT} Resource Group Created - ${AZURE_RESOURCE_GROUP_NAME} --location ${AZURE_REGION}"
            fi
        else
           SHOULD_EXIT=1
           echo "${RED_TEXT}FAILED: Missing Resource Group - ${AZURE_RESOURCE_GROUP_NAME} ${RESET_TEXT}"
        fi
      else
        if [ -n "${AZURE_GROUP_ID}"  ]; then
          echo "Assigning new role assignment -  ${AZURE_GROUP_ID} " >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/az-resourceGroup.log 2>&1
          az role assignment create --role "Contributor" --assignee-principal-type Group --assignee-object-id ${AZURE_GROUP_ID} -g ${AZURE_RESOURCE_GROUP_NAME} >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/az-resourceGroup.log 2>&1
        fi
        echo "${BLUE_TEXT}PASSED ${RESET_TEXT} Resource Group found - ${AZURE_RESOURCE_GROUP_NAME}"
      fi
    else
        echo "${BLUE_TEXT}PASSED ${RESET_TEXT} Resource Group not supplied, will create new dyamic Resource Group"
        echo "Resource Group not supplied, will create new dyamic Resource Group" &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/az-resourceGroup.log
    fi
    echo ""
}
