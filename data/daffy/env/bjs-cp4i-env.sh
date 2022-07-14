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
DAFFY_UNIQUE_ID="ssavaliya@bjs.com"
#This is required - Values POC/Demo/Enablement
DAFFY_DEPLOYMENT_TYPE="POC"
#If POC/Demo, these are required. No Spaces or "&" or "?" or "="
DAFFY_ISC_NUMBER="0063h00000IPfK5AAL"
DAFFY_CUSTOMER_NAME="BJ's Wholesale Club"

#OpenShift Cluster info
#####################################
BASE_DOMAIN="ocp.bjswholesale.info"
CLUSTER_NAME="bjs-cp4i"
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
AWS_REGION="us-east-1"
AWS_ACCESS_KEY_ID="AKIAQOKDZTWTAE52NPVD"
AWS_USER_TAG1="ocpCluster: ${CLUSTER_NAME}.${BASE_DOMAIN}"
AWS_USER_TAG2="Project: Digital"
AWS_USER_TAG3="AppName: APIC"
AWS_MACHINE_TYPE_MASTER_LARGE=m5.xlarge
AWS_MACHINE_TYPE_MASTER_CPU_LARGE=4
AWS_MACHINE_TYPE_WORKER_LARGE=m5.4xlarge
AWS_MACHINE_TYPE_WORKER_CPU_LARGE=16

#Enable Features
#############################
OCP_CREATE_OPENSHIFT_CONTAINER_STORAGE="true"

#Overrides
#####################################
AWS_CREDENTIALS_MODE="Mint"
DEBUG="false"
AWS_NETWORKING_CLUSTER_NETWORK_CIDR=172.128.0.0/14
AWS_NETWORKING_CLUSTER_NETWORK_HOST_PREFIX=23
AWS_NETWORKING_MACHINE_NETWORK_CIDR=172.30.0.0/16
AWS_NETWORKING_NETWORK_TYPE=OpenShiftSDN
AWS_NETWORKING_SERVICE_NETWORK=192.168.0.0/16
AWS_INSTALL_PUBLISH=Internal
AWS_SUBNET1=subnet-0a5f39fd082f14b0b
AWS_SUBNET2=subnet-0492bd472e0b60d3d
AWS_SUBNET3=subnet-05bdb5b484f579c32
AWS_SUBNET4=subnet-04290fcfdc25af0ad
AWS_SUBNET5=subnet-0c17abbe0ad66da67
AWS_SUBNET6=subnet-0e400f5a409e8cc32
#AWS_ADMINISTRATOR_ACCESS_PRECHECK_SKIP=true

############################################################
# This is for Cloud Pak for Integration
############################################################
#Supported versions 2021.4.1, 2021.3.1 and 2021.2.1
CP4I_VERSION="2021.4.1"

#CP4I Services
#####################################
#CP4I_ENABLE_SERVICE_ACEDESIGN=true
#CP4I_ENABLE_SERVICE_ACEDASH=true
#CP4I_ENABLE_SERVICE_ASSETREPO=true
CP4I_ENABLE_SERVICE_TRACING=true
#CP4I_ENABLE_SERVICE_MQSINGLE=true
CP4I_ENABLE_SERVICE_APIC=true
#CP4I_ENABLE_SERVICE_MQHA=true
#CP4I_ENABLE_SERVICE_EVENTSTREAMS=true
