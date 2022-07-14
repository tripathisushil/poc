############################################################
#Author           : Daffy
#Modified Date    : 2022-02-24
#Environment      : AWS
############################################################
#This is for AWS
############################################################
#Daffy Information Required
#####################################
#No spaces and only AlphaNumeric and  @ or . or -
DAFFY_UNIQUE_ID="YourEmail.com"
#This is required - Values POC/Demo/Enablement/HCCX/TechZone
#DAFFY_DEPLOYMENT_TYPE=
#If POC/Demo, these are required. No Spaces or "&" or "?" or "="
#DAFFY_ISC_NUMBER="0045h00000w1nvKAAG"
#DAFFY_CUSTOMER_NAME="AcmeCustomer"

#OpenShift Cluster info
#####################################
BASE_DOMAIN="yourdomain.com"
CLUSTER_NAME="yourcluster"
OCP_INSTALL_TYPE="aws-ipi"

# Tested  OCP_RELEASE  values:  4.6.44, 4.6.46, 4.7.36, 4.8.17, etc
#    Values must match a valid download file value (https://mirror.openshift.com/pub/openshift-v4/clients/ocp/)
OCP_RELEASE="4.8.40"

# Supported VM_TSHIRT_SIZE values: Large, Min
#    Large - 6 Worker Nodes
#    Min   - 3 Worker Nodes
VM_TSHIRT_SIZE="Large"

#AWS info
#############################
AWS_REGION="YOUR-AWS-REGION"
AWS_ACCESS_KEY_ID="YOUR-AWS-ACCESS-KEY-ID"
#AWS_USER_TAG1="NAME: VALUE"
AWS_USER_TAG1="ocpCluster: ${CLUSTER_NAME}.${BASE_DOMAIN}"


#Enable Features
#############################
#OCP_CREATE_OPENSHIFT_CONTAINER_STORAGE="true"

#Overrides
#####################################
#DEBUG="true"
#AWS_NETWORKING_CLUSTER_NETWORK_CIDR=10.128.0.0/14
#AWS_NETWORKING_CLUSTER_NETWORK_HOST_PREFIX=23
#AWS_NETWORKING_MACHINE_NETWORK_CIDR=10.0.0.0/16
#AWS_NETWORKING_NETWORK=OpenShiftSDN
#AWS_NETWORKING_SERVICE_NETWORK=172.30.0.0/16
