############################################################
#Author           : Kyle Dawson
#Author email     : Kyle.Dawson@us.ibm.com
#Original Date    : 2021-09-25
#Initial Version  : v2021-12-01
############################################################
AWS_SERVICE_QUOTA_EC2_VCPU_ALL_STANDARD="L-34B43A08"

AWS_SERVICE_QUOTA_EC2_EIP="L-0263D0A3"
AWS_SERVICE_QUOTA_EC2_EIP_REQUIRED=2

AWS_SERVICE_QUOTA_VPC="L-F678F1CE"
AWS_SERVICE_QUOTA_VPC_REQUIRED=1

AWS_SERVICE_QUOTA_ELB="L-53DA6B97"
AWS_SERVICE_QUOTA_ELB_REQUIRED=3

AWS_SERVICE_QUOTA_VPC_NAT_GATEWAY="L-FE5A380F"
AWS_SERVICE_QUOTA_VPC_NAT_GATEWAY_REQUIRED=1

AWS_SERVICE_QUOTA_VPC_ENI="L-DF5E4CA3"
AWS_SERVICE_QUOTA_VPC_ENI_REQUIRED=27

AWS_SERVICE_QUOTA_VPC_GATEWAY="L-1B52E74A"
AWS_SERVICE_QUOTA_VPC_GATEWAY_REQUIRED=1

AWS_SERVICE_QUOTA_S3_BUCKETS="L-DC2B2D3D"
AWS_SERVICE_QUOTA_S3_BUCKETS_REQUIRED=100

AWS_SERVICE_QUOTA_VPC_SECURITY_GROUPS="L-E79EC296"
AWS_SERVICE_QUOTA_VPC_SECURITY_GROUPS_REQUIRED=10

AWS_USER_TAG_MAIN2="DaffyInstaller: ${DAFFY_UNIQUE_ID}"
AWS_ACCESS_POLICY_REQUIRED="arn:aws:iam::aws:policy/AdministratorAccess"
export AWS_DEFAULT_REGION=${AWS_REGION}
saveAWSCredentials()
{
  if [ ! -f  ~/.aws/credentials ]; then
      cp -fR ${DIR}/templates/* ${TEMP_DIR}/${PRODUCT_SHORT_NAME}
      find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@AWS_ACCESS_KEY_ID@/$AWS_ACCESS_KEY_ID/g"
      echo "Missing AWS_SECRET_ACCESS_KEY, please enter here so we can save to ~/.aws/credentials"
      echo -n "AWS_SECRET_ACCESS_KEY=${BLUE_TEXT}"
      unset AWS_SECRET_ACCESS_KEY;
      while IFS= read -r -s -n1 pass; do
        if [[ -z $pass ]]; then
           echo
           break
        else
           echo -n '*'
           AWS_SECRET_ACCESS_KEY+=$pass
        fi
      done
      export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
      echo "export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}" >> ~/.profile
      echo ${RESET_TEXT}
      mkdir -p ~/.aws
      cp -fR ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/providers/aws/credentials ~/.aws/credentials
      echo  "aws_secret_access_key =  ${AWS_SECRET_ACCESS_KEY} " >> ~/.aws/credentials
  fi

}
updateAWSInstallConfig()
{
  NEW_VM_WORKER_DISK1=`echo ${VM_WORKER_DISK1} |  sed  "s/\([a-zA-Z]\)$//"`
  sed -i'' "s/size: ${VM_WORKER_DISK1}/size: ${NEW_VM_WORKER_DISK1}/" ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/providers/aws/install-config.yaml
}
awsInstallCommandline()
{
  printHeaderMessage "Install AWS command line tool (LOG -> ${LOG_DIR}/aws-cli-install.log )"
  FOUND_AWS_COMMAND=`aws --version 2> /dev/null | grep -c "aws-cli"`
  if [ ${FOUND_AWS_COMMAND} == 0 ] ;then
    echo "Missing aws-cli, installing now."
    cd ${TEMP_DIR}/${PRODUCT_SHORT_NAME}
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" &> ${LOG_DIR}/aws-cli-install.log
    unzip awscliv2.zip >> ${LOG_DIR}/aws-cli-install.log
    ./aws/install -i /usr/local/aws-cli -b /usr/local/bin >> ${LOG_DIR}/aws-cli-install.log
    rm -fR  ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/awscliv2.zip 2> /dev/null
    rm -fR  ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/aws 2> /dev/null
    FOUND_AWS_COMMAND=`aws --version 2> /dev/null | grep -c "aws-cli"`
    if [ ${FOUND_AWS_COMMAND} == 0 ] ;then
          echo "${RED_TEXT}FAILED ${RESET_TEXT} Unable to install aws-cli tool."
          echo "${RED_TEXT}Unable to continue, exit process now!!!!!!!!${RESET_TEXT}"
          echo ""
          echo "Exiting Script!!!!!!!"
          exit 9
    fi
  else
    echo "${BLUE_TEXT}PASSED ${RESET_TEXT} aws-cli already installed."
  fi
  echo "AWS Default Region = ${AWS_DEFAULT_REGION}"
  echo ""
}

awsValidDNSHostedZone()
{
  printHeaderMessage "Validate AWS Route53 Public Hosted Zone (LOG -> ${LOG_DIR}/aws-route53.out )"
  if [[ "${CURRENT_SCRIPT_NAME}" == *build.sh ]];then
      if [ "${AWS_INSTALL_PUBLISH}" == "External" ]; then
          aws route53 list-hosted-zones-by-name > ${LOG_DIR}/aws-route53.out
          local AWS_VALID_DNS_HOSTED_ZONE=`cat ${LOG_DIR}/aws-route53.out | grep -c "\"Name\": \"${BASE_DOMAIN}.\""`
          if [ $AWS_VALID_DNS_HOSTED_ZONE -eq  0 ]; then
            echo "${RED_TEXT}FAILED: Missing Route53 Hosted Public Zone (${BASE_DOMAIN})"
            SHOULD_EXIT=1
          else
            echo "${BLUE_TEXT}PASSED ${RESET_TEXT} Found Route53 Hosted Public Zone (${BASE_DOMAIN})"
            AWS_ROUTE53_BASE_DOMAIN_ID=`aws route53 list-hosted-zones-by-name | jq --arg bd "${BASE_DOMAIN}." '.HostedZones[] | select(.Name == $bd) | .' | jq .'Id' |  sed "s/\"//g" | sed "s/\/hostedzone\///g"`
            AWS_ROUTE53_BASE_DOMAIN_NAME_SERVERS=`aws route53 get-hosted-zone --id ${AWS_ROUTE53_BASE_DOMAIN_ID} | jq '.DelegationSet.NameServers[] | .' |  sed "s/\"//g"`
            AWS_NS_COUT=0
            for AWS_NAME_SERVERS in $AWS_ROUTE53_BASE_DOMAIN_NAME_SERVERS
            do
              FOUND_AWS_NS=`dig ${BASE_DOMAIN} NS | grep NS | grep -c ${AWS_NAME_SERVERS}`
              if [ "${FOUND_AWS_NS}"  == "1" ]; then
                let "AWS_NS_COUT=${AWS_NS_COUT}+1"
              fi
            done
            if [ ${AWS_NS_COUT} -ne 4 ]; then
              echo "${RED_TEXT}FAILED ${RESET_TEXT} ${BASE_DOMAIN} is NOT pointing to the correct AWS NS Servers."
              echo "DNS Zone required NS should be :"
              echo "${AWS_ROUTE53_BASE_DOMAIN_NAME_SERVERS}"
              echo "Actual DNS NS :"
              dig ${BASE_DOMAIN} NS | grep NS |  grep -v ";" | awk '{print $5}'
              echo "${RESET_TEXT}"
            else
              echo "${BLUE_TEXT}PASSED ${RESET_TEXT} ${BASE_DOMAIN} is pointing to the correct AWS NS Servers."
            fi
          fi
      else
          echo "${BLUE_TEXT}INFO ${RESET_TEXT} AWS is Internal, skip DNS Zone check."
      fi
  fi
  echo ""

}

awsLookupValidateQuota()
{
  local SERVICE_CODE=$1
  local QUOTA_CODE=$2
  local REGION=$3
  local QUOTA_NEEDED=$4
  local CURRENT_QUOTA_VALUE=`aws service-quotas get-service-quota  --service-code ${SERVICE_CODE} --quota-code  ${QUOTA_CODE} --region ${REGION} 2>/dev/null | grep Value | awk '{print $2}' | sed "s/\,//g" | sed "s/\.0//g"`
  local CURRENT_QUOTA_NAME=`aws service-quotas get-service-quota  --service-code ${SERVICE_CODE} --quota-code  ${QUOTA_CODE} --region ${REGION}  2>/dev/null | grep QuotaName |awk '{for (i=2; i<NF; i++) printf $i " "; print $NF}' |  sed "s/\"//g" | sed 's/.$//'`
  #echo "Current Qutoa Value for Service Code ${SERVICE_CODE} and Quota Code ${QUOTA_CODE} - ${CURRENT_QUOTA_VALUE} (${REGION})"
  if [ -z ${CURRENT_QUOTA_VALUE} ]; then
    echo "${RED_TEXT}FAILED ${RESET_TEXT} Missing service-quotas permission, unable to check quota (--service-code ${SERVICE_CODE} --quota-code  ${QUOTA_CODE} --region ${REGION}).${RESET_TEXT}"
    echo "Required AWS policy - servicequotas:GetServiceQuota"
    SHOULD_EXIT=1
  else
    let QUTOA_DIFF=CURRENT_QUOTA_VALUE-QUOTA_NEEDED
    if [ ${CURRENT_QUOTA_VALUE} -lt ${QUOTA_NEEDED} ]; then
      echo "${RED_TEXT}FAILED ${RESET_TEXT} Missing quota requirement (${QUOTA_CODE} - ${CURRENT_QUOTA_NAME} )  - Short ${QUTOA_DIFF}${RESET_TEXT}"
      SHOULD_EXIT=1
    else
      echo "${BLUE_TEXT}PASSED ${RESET_TEXT} Quota requirement (${QUOTA_CODE} - ${CURRENT_QUOTA_NAME} )  - Extra ${QUTOA_DIFF}"
    fi
  fi
}

awsValidateQuota()
{
  printHeaderMessage "Validate AWS Quota's(Max Allowed but not Currently Utilized)"
  if [[ -z "${AWS_REGION}" ]]; then
      echo "${RED_TEXT}Unable to get quota without AWS_REGION variable. ${RESET_TEXT}"
  else
      awsLookupValidateQuota  ec2 ${AWS_SERVICE_QUOTA_EC2_VCPU_ALL_STANDARD} ${AWS_REGION} ${AWS_MACHINE_TYPE_CPU_TOTAL}
      awsLookupValidateQuota  ec2 ${AWS_SERVICE_QUOTA_EC2_EIP} ${AWS_REGION} ${AWS_SERVICE_QUOTA_EC2_EIP_REQUIRED}
      awsLookupValidateQuota  vpc ${AWS_SERVICE_QUOTA_VPC} ${AWS_REGION} ${AWS_SERVICE_QUOTA_VPC_REQUIRED}
      awsLookupValidateQuota  elasticloadbalancing ${AWS_SERVICE_QUOTA_ELB} ${AWS_REGION} ${AWS_SERVICE_QUOTA_ELB_REQUIRED}
      awsLookupValidateQuota  vpc ${AWS_SERVICE_QUOTA_VPC_NAT_GATEWAY} ${AWS_REGION} ${AWS_SERVICE_QUOTA_VPC_NAT_GATEWAY_REQUIRED}
      awsLookupValidateQuota  vpc ${AWS_SERVICE_QUOTA_VPC_ENI} ${AWS_REGION} ${AWS_SERVICE_QUOTA_VPC_ENI_REQUIRED}
      awsLookupValidateQuota  vpc ${AWS_SERVICE_QUOTA_VPC_GATEWAY} ${AWS_REGION} ${AWS_SERVICE_QUOTA_VPC_GATEWAY_REQUIRED}
      #awsLookupValidateQuota  s3 ${AWS_SERVICE_QUOTA_S3_BUCKETS} ${AWS_REGION} ${AWS_SERVICE_QUOTA_S3_BUCKETS_REQUIRED}
      awsLookupValidateQuota  vpc ${AWS_SERVICE_QUOTA_VPC_SECURITY_GROUPS} ${AWS_REGION} ${AWS_SERVICE_QUOTA_VPC_SECURITY_GROUPS_REQUIRED}
  fi
  echo ""
}
awsAddOpenShiftContainerStorageDisk()
{
  printHeaderMessage "Create new Disk for OpenShift Container Storage on AWS"
  NODE_LIST=`oc get nodes | grep worker | awk '{print $1}'`
  local workerLoop=1
  for AWS_WORKER_NODE_NAME in $NODE_LIST
  do
       local NODE_IP_ADDRESS=`echo ${AWS_WORKER_NODE_NAME} | sed "s/ip-//g" | sed "s/\.compute.internal//g" | sed "s/\.${AWS_REGION}//g" | sed "s/-/\./g"`
       local AWS_VM_INSTANCE_ID=`aws ec2 describe-instances --filter Name=private-ip-address,Values=${NODE_IP_ADDRESS} --query 'Reservations[].Instances[].InstanceId' --output text --region ${AWS_REGION}`
       local AWS_VM_INSTANCE_NAME=`aws ec2 describe-instances --filter Name=private-ip-address,Values=${NODE_IP_ADDRESS} --query 'Reservations[].Instances[].Tags' --output text --region ${AWS_REGION} | grep Name | awk '{print $2 }'`
       local AWS_VM_INSTANCE_AVAILIBILTY_ZONE=`aws ec2 describe-instances --filter Name=private-ip-address,Values=${NODE_IP_ADDRESS} --query 'Reservations[].Instances[].Placement[].AvailabilityZone' --output text --region ${AWS_REGION}`
       local AWS_WORKER_DISK2=`echo ${VM_WORKER_DISK2} | sed "s/G//g"`
       local AWS_WORKER_DISK3=`echo ${VM_WORKER_DISK3} | sed "s/G//g"`

       echo "Creating new volume : ${AWS_VM_INSTANCE_NAME}-${IBM_OPENSHIFT_LOCAL_STORAGE_DEVICE_DISK2_NAME} --volume-type ${AWS_DISK_VOLUME_TYPE} --iops ${AWS_DISK_VOLUME_IOPS} --size ${AWS_WORKER_DISK2} --region ${AWS_REGION}"
       aws ec2 create-volume --volume-type ${AWS_DISK_VOLUME_TYPE} --iops ${AWS_DISK_VOLUME_IOPS} --size ${AWS_WORKER_DISK2} --region ${AWS_REGION} \
           --tag-specifications 'ResourceType=volume,Tags=[{Key=Name,Value='${AWS_VM_INSTANCE_NAME}'-'${IBM_OPENSHIFT_LOCAL_STORAGE_DEVICE_DISK2_NAME}'}]' \
           --availability-zone ${AWS_VM_INSTANCE_AVAILIBILTY_ZONE} > ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/aws-${IBM_OPENSHIFT_LOCAL_STORAGE_DEVICE_DISK2_NAME}-${AWS_VM_INSTANCE_NAME}.log
       local AWS_VOLUME_INSTANCE_ID=`cat ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/aws-${IBM_OPENSHIFT_LOCAL_STORAGE_DEVICE_DISK2_NAME}-${AWS_VM_INSTANCE_NAME}.log | grep "VolumeId" |  awk '{print $2 }' |sed "s/,//g" |sed 's/\"//g'  `
       sleep 10
       echo "Attaching new volume :  --volume-id ${AWS_VOLUME_INSTANCE_ID} --instance-id ${AWS_VM_INSTANCE_ID} --device ${IBM_OPENSHIFT_LOCAL_STORAGE_DEVICE_PATH_AWS} --region ${AWS_REGION}"
       aws ec2 attach-volume --volume-id ${AWS_VOLUME_INSTANCE_ID} --instance-id ${AWS_VM_INSTANCE_ID} --device ${IBM_OPENSHIFT_LOCAL_STORAGE_DEVICE_PATH_AWS} --region ${AWS_REGION} >> ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/aws-${IBM_OPENSHIFT_LOCAL_STORAGE_DEVICE_DISK2_NAME}-${AWS_VM_INSTANCE_NAME}.log
       #Update Volume to delete when instgance is deleted
       aws ec2 modify-instance-attribute --instance-id ${AWS_VM_INSTANCE_ID} --block-device-mappings file://${TEMP_DIR}/${PRODUCT_SHORT_NAME}/providers/aws/aws-worker-disk2.yaml --region ${AWS_REGION}

       echo "Creating new volume : ${AWS_VM_INSTANCE_NAME}-${IBM_OPENSHIFT_LOCAL_STORAGE_DEVICE_DISK3_NAME} --volume-type ${AWS_DISK_VOLUME_TYPE} --iops ${AWS_DISK_VOLUME_IOPS} --size ${AWS_WORKER_DISK3} --region ${AWS_REGION}"
       aws ec2 create-volume --volume-type ${AWS_DISK_VOLUME_TYPE} --iops ${AWS_DISK_VOLUME_IOPS} --size ${AWS_WORKER_DISK3} --region ${AWS_REGION} \
           --tag-specifications 'ResourceType=volume,Tags=[{Key=Name,Value='${AWS_VM_INSTANCE_NAME}'-'${IBM_OPENSHIFT_LOCAL_STORAGE_DEVICE_DISK3_NAME}'}]' \
           --availability-zone ${AWS_VM_INSTANCE_AVAILIBILTY_ZONE} > ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/aws-${IBM_OPENSHIFT_LOCAL_STORAGE_DEVICE_DISK3_NAME}-${AWS_VM_INSTANCE_NAME}.log
       local AWS_VOLUME_INSTANCE_ID=`cat ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/aws-${IBM_OPENSHIFT_LOCAL_STORAGE_DEVICE_DISK3_NAME}-${AWS_VM_INSTANCE_NAME}.log | grep "VolumeId" |  awk '{print $2 }' |sed "s/,//g" |sed 's/\"//g'  `
       sleep 10
       echo "Attaching new volume : --volume-id ${AWS_VOLUME_INSTANCE_ID} --instance-id ${AWS_VM_INSTANCE_ID} --device ${IBM_OPENSHIFT_LOCAL_BULK_STORAGE_DEVICE_PATH_AWS} --region ${AWS_REGION}"
       aws ec2 attach-volume --volume-id ${AWS_VOLUME_INSTANCE_ID} --instance-id ${AWS_VM_INSTANCE_ID} --device ${IBM_OPENSHIFT_LOCAL_BULK_STORAGE_DEVICE_PATH_AWS} --region ${AWS_REGION} >> ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/aws-${IBM_OPENSHIFT_LOCAL_STORAGE_DEVICE_DISK3_NAME}-${AWS_VM_INSTANCE_NAME}.log
       #Update Volume to delete when instgance is deleted
       aws ec2 modify-instance-attribute --instance-id ${AWS_VM_INSTANCE_ID} --block-device-mappings file://${TEMP_DIR}/${PRODUCT_SHORT_NAME}/providers/aws/aws-worker-disk3.yaml --region ${AWS_REGION}

       case ${workerLoop} in
           1)
              OPEN_SHIFT_CONTAINTER_STORAGE_WORKER_NODE1=${AWS_WORKER_NODE_NAME}
              ;;
           2)
              OPEN_SHIFT_CONTAINTER_STORAGE_WORKER_NODE2=${AWS_WORKER_NODE_NAME}
              ;;
           3)
              OPEN_SHIFT_CONTAINTER_STORAGE_WORKER_NODE3=${AWS_WORKER_NODE_NAME}
              ;;
       esac
       let workerLoop=workerLoop+1
       if [ $workerLoop -gt 3 ]; then
         #only add disk to first three nodes.
         break
       fi
       echo ""
  done

}


awsAccountPermissions()
{
  printHeaderMessage "Validate AWS Account Permissions"
  AWS_ARN_ID=`aws sts get-caller-identity | jq '.Arn' | sed "s/\"//g" |  sed "s/.*\///g"`
  aws iam get-account-authorization-details 2>/dev/null | jq -c '.UserDetailList[] | select(.UserName == "'"${AWS_ARN_ID}"'") | .' > ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/aws-user-details.json
  AWS_USER_HAS_ADMIN_ACCESS=`cat ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/aws-user-details.json | grep -c ${AWS_ACCESS_POLICY_REQUIRED}`
  if [ $AWS_USER_HAS_ADMIN_ACCESS -eq  0 ]; then
    if [ "${AWS_ADMINISTRATOR_ACCESS_PRECHECK_SKIP}" == "true" ]; then
      echo "${YELLOW_TEXT}WARNING ${RESET_TEXT} Missing Account Permissions AdministratorAccess (${AWS_ACCESS_POLICY_REQUIRED})"
      echo "${YELLOW_TEXT}This means you must setup the correct access policy listed from the OpenShift site for this install to work, we are not prechecking access policy.${RESET_TEXT}"
      echo "${BLUE_TEXT}https://docs.openshift.com/container-platform/${OCP_BASE_VERSION}/installing/installing_aws/installing-aws-account.html${BLUE_TEXT}"
      echo "${YELLOW_TEXT}INFO ${RESET_TEXT} You can use our sample policy files to help get you started:"
      echo "${YELLOW_TEXT}${DATA_DIR}/$PROJECT_NAME/ocp/templates/providers/aws/policies${RESET_TEXT}"
      echo ""
    else
      echo "${RED_TEXT}FAILED ${RESET_TEXT} Missing Account Permissions AdministratorAccess (${AWS_ACCESS_POLICY_REQUIRED})"
      SHOULD_EXIT=1
    fi

  else
    echo "${BLUE_TEXT}PASSED ${RESET_TEXT} AdministratorAccess has been verified (${AWS_ACCESS_POLICY_REQUIRED})"
  fi
  echo ""
}
awsApplySubnetValues()
{
    if [ -n "${AWS_SUBNET1}" ] ; then
        AWS_SUBNET1="- ${AWS_SUBNET1}"
    fi
    if [ -n "${AWS_SUBNET2}" ] ; then
        AWS_SUBNET2="- ${AWS_SUBNET2}"
    fi
    if [ -n "${AWS_SUBNET3}" ] ; then
        AWS_SUBNET3="- ${AWS_SUBNET3}"
    fi
    if [ -n "${AWS_SUBNET4}" ] ; then
        AWS_SUBNET4="- ${AWS_SUBNET4}"
    fi
    if [ -n "${AWS_SUBNET5}" ] ; then
        AWS_SUBNET5="- ${AWS_SUBNET5}"
    fi
    if [ -n "${AWS_SUBNET6}" ] ; then
        AWS_SUBNET6="- ${AWS_SUBNET6}"
    fi

}
awsApplyMasterAvailZonesValues()
{
    if [ -n "${AWS_MACHINE_TYPE_MASTER_AVAIL_ZONE1}" ] ; then
        AWS_MACHINE_TYPE_MASTER_AVAIL_ZONE1="- ${AWS_MACHINE_TYPE_MASTER_AVAIL_ZONE1}"
    fi
    if [ -n "${AWS_MACHINE_TYPE_MASTER_AVAIL_ZONE2}" ] ; then
        AWS_MACHINE_TYPE_MASTER_AVAIL_ZONE2="- ${AWS_MACHINE_TYPE_MASTER_AVAIL_ZONE2}"
    fi
    if [ -n "${AWS_MACHINE_TYPE_MASTER_AVAIL_ZONE3}" ] ; then
        AWS_MACHINE_TYPE_MASTER_AVAIL_ZONE3="- ${AWS_MACHINE_TYPE_MASTER_AVAIL_ZONE3}"
    fi
}
awsApplyWorkerAvailZonesValues()
{
    if [ -n "${AWS_MACHINE_TYPE_WORKER_AVAIL_ZONE1}" ] ; then
        AWS_MACHINE_TYPE_WORKER_AVAIL_ZONE1="- ${AWS_MACHINE_TYPE_WORKER_AVAIL_ZONE1}"
    fi
    if [ -n "${AWS_MACHINE_TYPE_WORKER_AVAIL_ZONE2}" ] ; then
        AWS_MACHINE_TYPE_WORKER_AVAIL_ZONE2="- ${AWS_MACHINE_TYPE_WORKER_AVAIL_ZONE2}"
    fi
    if [ -n "${AWS_MACHINE_TYPE_WORKER_AVAIL_ZONE3}" ] ; then
        AWS_MACHINE_TYPE_WORKER_AVAIL_ZONE3="- ${AWS_MACHINE_TYPE_WORKER_AVAIL_ZONE3}"
    fi
}
awsGetKMSKey()
{
  if [  "${AWS_ENABLE_KMS_KEY}" == "true" ] && [ ! -n "${AWS_WORKER_ROOTVOLUME_KMSKEYARN}"  ]; then
    printHeaderMessage "Capture and Save AWS KMS worker storage disk key."
    echo "Requesting to use AWS KMS key, please enter here so we can save to ~/.profile"
    echo -n "AWS_WORKER_ROOTVOLUME_KMSKEYARN=${BLUE_TEXT}"
    unset AWS_WORKER_ROOTVOLUME_KMSKEYARN;
    while IFS= read -r -s -n1 pass; do
      if [[ -z $pass ]]; then
         echo
         break
      else
         echo -n '*'
         AWS_WORKER_ROOTVOLUME_KMSKEYARN+=$pass
      fi
    done
    export AWS_WORKER_ROOTVOLUME_KMSKEYARN=${AWS_WORKER_ROOTVOLUME_KMSKEYARN}
    echo "export AWS_WORKER_ROOTVOLUME_KMSKEYARN='${AWS_WORKER_ROOTVOLUME_KMSKEYARN}'" >> ~/.profile

  fi
}
awsCheckSubnets()
{
  printHeaderMessage "Checking AWS Subnets"
  AWS_SUBNET1_INTERNAL=`echo "${AWS_SUBNET1}" | sed  -e 's/- //g' `
  AWS_SUBNET2_INTERNAL=`echo "${AWS_SUBNET2}" | sed  -e 's/- //g' `
  AWS_SUBNET3_INTERNAL=`echo "${AWS_SUBNET3}" | sed  -e 's/- //g' `
  AWS_SUBNET4_INTERNAL=`echo "${AWS_SUBNET4}" | sed  -e 's/- //g' `
  AWS_SUBNET5_INTERNAL=`echo "${AWS_SUBNET5}" | sed  -e 's/- //g' `
  AWS_SUBNET6_INTERNAL=`echo "${AWS_SUBNET6}" | sed  -e 's/- //g' `
  #1) If  @AWS_SUBNET1@ not blank, see if is valid in AWS
  for AWS_SUBNET in ${AWS_SUBNET1_INTERNAL} ${AWS_SUBNET2_INTERNAL} ${AWS_SUBNET3_INTERNAL} ${AWS_SUBNET4_INTERNAL} ${AWS_SUBNET5_INTERNAL} ${AWS_SUBNET6_INTERNAL}
  do
    EXISTING_SUBNET=`aws ec2 describe-subnets| jq -c '.Subnets[] | select( .SubnetId | contains("'${AWS_SUBNET}'"))' | jq .VpcId | sed 's/\"//g'`
    if [ ! -n "${EXISTING_SUBNET}" ]; then
      SHOULD_EXIT=1
      echo "${RED_TEXT}FAILED ${RESET_TEXT} Subnet does not exist ${AWS_SUBNET}"
    else
      echo "${BLUE_TEXT}PASSED ${RESET_TEXT} Subnet exist ${AWS_SUBNET}"
    fi
  done
  #2) Do all subnets belong to same vpc
  AWS_SUBNET_COUNTER=1
  for AWS_SUBNET in ${AWS_SUBNET1_INTERNAL} ${AWS_SUBNET2_INTERNAL} ${AWS_SUBNET3_INTERNAL} ${AWS_SUBNET4_INTERNAL} ${AWS_SUBNET5_INTERNAL} ${AWS_SUBNET6_INTERNAL}
  do
    AWS_SUBNET_CURRENT_VPC_ID=`aws ec2 describe-subnets| jq -c '.Subnets[] | select( .SubnetId | contains("'${AWS_SUBNET}'"))' | jq .VpcId | sed 's/\"//g'`
    if [ ${AWS_SUBNET_COUNTER} -ne 1 ]; then
        if [ "${AWS_SUBNET_CURRENT_VPC_ID}" !=  "${AWS_SUBNET_PREVIOUS_VPC_ID}" ]; then
          SHOULD_EXIT=1
          let AWS_SUBNET_PREV_COUNTER=AWS_SUBNET_COUNTER-1
          echo "${RED_TEXT}FAILED ${RESET_TEXT} Subnets do not belong to same VPC"
          echo "${RED_TEXT}FAILED ${RESET_TEXT} ${AWS_SUBNET_PREVIOUS_ID} - ${AWS_SUBNET_PREVIOUS_VPC_ID}"
          echo "${RED_TEXT}FAILED ${RESET_TEXT} ${AWS_SUBNET} - ${AWS_SUBNET_CURRENT_VPC_ID}"
        else
           echo "${BLUE_TEXT}PASSED ${RESET_TEXT} ${AWS_SUBNET} belongs to VPC ${AWS_SUBNET_CURRENT_VPC_ID}"
        fi
    fi
    AWS_SUBNET_PREVIOUS_VPC_ID=${AWS_SUBNET_CURRENT_VPC_ID}
    AWS_SUBNET_PREVIOUS_ID=${AWS_SUBNET}
    let AWS_SUBNET_COUNTER=AWS_SUBNET_COUNTER+1
  done
  #3) Does any subnet belong to same Availability Zone, if so fail


  #4) Does VPC CIDR match @AWS_NETWORKING_MACHINE_NETWORK_CIDR@
  if [ ! -z "${AWS_SUBNET_CURRENT_VPC_ID}" ]; then
      AWS_VPC_CIDR=`aws ec2 describe-vpcs --filters  Name=vpc-id,Values=${AWS_SUBNET_CURRENT_VPC_ID} | jq .Vpcs[0].CidrBlock | sed 's/\"//g'`
      if [ "${AWS_VPC_CIDR}" != "${AWS_NETWORKING_MACHINE_NETWORK_CIDR}" ]; then
        SHOULD_EXIT=1
        echo "${RED_TEXT}FAILED ${RESET_TEXT} VPC CIDR(${AWS_VPC_CIDR}) does not match AWS_NETWORKING_MACHINE_NETWORK_CIDR(${AWS_NETWORKING_MACHINE_NETWORK_CIDR})"
      else
        echo "${BLUE_TEXT}PASSED ${RESET_TEXT} VPC CIDR(${AWS_VPC_CIDR}) matches AWS_NETWORKING_MACHINE_NETWORK_CIDR(${AWS_NETWORKING_MACHINE_NETWORK_CIDR})"
      fi
  fi
}
