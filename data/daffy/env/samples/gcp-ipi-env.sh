############################################################
#Author           : Daffy
#Modified Date    : 2022-02-24
#Environemnt      : GCP
############################################################
#This is for Google Cloud platform
############################################################
#https://docs.openshift.com/container-platform/4.9/installing/installing_gcp/installing-gcp-account.html

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
CLUSTER_NAME="yourClusterName"
OCP_INSTALL_TYPE="gcp-ipi"

# Tested  OCP_RELEASE  values:  4.6.44, 4.6.46, 4.7.36, 4.8.18
#    Values must match a valid download file value (https://mirror.openshift.com/pub/openshift-v4/clients/ocp/)
OCP_RELEASE="4.8.40"

# Supported VM_TSHIRT_SIZE values: Large, Min
#    Large - 6 Worker Nodes
#    Min   - 3 Worker Nodes
VM_TSHIRT_SIZE="Large"

#Daffy Information Required
#####################################
#This is required - Values POC/Demo/Enablement/HCCX/TechZone
#DAFFY_DEPLOYMENT_TYPE=

#If POC/Demo, these are required. No Spaces or "&" or "?" or "="
#DAFFY_ISC_NUMBER="0045h00000w1nvKAAG"
#DAFFY_CUSTOMER_NAME="AcmeCustomer"

#GCP info
#############################
GCP_PROJECT_ID="your-gcp-project-id"
GCP_REGION="us-central1"

#Enable Features
#############################
#OCP_CREATE_OPENSHIFT_CONTAINER_STORAGE="true"

#Overrides
#############################
#DEBUG="true"
#GCP_API_ENABLE_MISSING_SERVICE=true
#GCP_CREATE_MISSING_DNS_ZONE=true
#https://docs.openshift.com/container-platform/4.6/installing/installing_gcp/installing-gcp-network-customizations.html
#GCP_VPC_NETWORK=ocp-vpc
#GCP_CONTROL_PLANE_SUBNET=ocp-master-subnet1
#GCP_COMPUTE_SUBNET=ocp-worker-subnet2
#GCP_INSTALL_PUBLISH=Internal
#GCP_NETWORKING_CLUSTER_NETWORK_CIDR=10.128.0.0/17
#GCP_NETWORKING_CLUSTER_NETWORK_HOST_PREFIX=19
#GCP_NETWORKING_MACHINE_NETWORK_CIDR=10.0.0.0/17
#GCP_NETWORKING_MACHINE_NETWORK=OpenShiftSDN
#GCP_NETWORKING_SERVICE_NETWORK=172.28.0.0/17
