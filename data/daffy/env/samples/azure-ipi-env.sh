############################################################
#Author           : Daffy
#Modified Date    : 2022-02-24
#Environemnt      : Azure
############################################################
#This is for Azure environment
############################################################
#Daffy Information Required
#####################################
#No spaces and only AlphaNumeric and  @ or . or -
DAFFY_UNIQUE_ID="YourEmail.com"
#This is required - Values POC/Demo/Enablement/HCCX/TechZone/HCCX/TechZone
#DAFFY_DEPLOYMENT_TYPE=
#If POC/Demo, these are required. No Spaces or "&" or "?" or "="
#DAFFY_ISC_NUMBER="0045h00000w1nvKAAG"
#DAFFY_CUSTOMER_NAME="AcmeCustomer"

#OpenShift Cluster info
#####################################
BASE_DOMAIN="yourdomain.com"
CLUSTER_NAME="yourcluster"
OCP_INSTALL_TYPE="azure-ipi"

# Tested  OCP_RELEASE  values:  4.6.44, 4.6.46, 4.7.36, 4.8.17
#    Values must match a valid download file value (https://mirror.openshift.com/pub/openshift-v4/clients/ocp/)
OCP_RELEASE="4.8.40"

# Supported VM_TSHIRT_SIZE values: Large, Min
#    Large - 6 Worker Nodes
#    Min   - 3 Worker Nodes
VM_TSHIRT_SIZE="Large"

#Azure Required Settings
#####################################
AZURE_SUBSCRIPTION_ID="ZZZZZZZZ-ZZZZZZZZ-ZZZZZZZZ-ZZZZZZZZ-ZZZZZZZZ"
AZURE_CLIENT_ID="ZZZZZZZZ-ZZZZZZZZ-ZZZZZZZZ-ZZZZZZZZ-ZZZZZZZZ"
AZURE_TENANT_ID="ZZZZZZZZ-ZZZZZZZZ-ZZZZZZZZ-ZZZZZZZZ-ZZZZZZZZ"
AZURE_BASE_DOMAIN_RESOURCE_GROUP_NAME="your-dns-zone-resource-group"
AZURE_REGION="eastus"


#Enable Features
#############################
#OCP_CREATE_OPENSHIFT_CONTAINER_STORAGE="true"


#Azure Overrides
#########################
#AZURE_RESOURCE_GROUP_NAME=existing-rg-name
#AZURE_RESOURCE_GROUP_NAME_CREATE_MISSING=false
#AZURE_GROUP_ID=
#AZURE_NETWORKING_CLUSTER_NETWORK_CIDR=10.128.0.0/14
#AZURE_NETWORKING_CLUSTER_NETWORK_HOST_PREFIX=23
#AZURE_NETWORKING_MACHINE_NETWORK_CIDR=10.0.0.0/16
#AZURE_NETWORKING_NETWORK_TYPE=OpenShiftSDN
#AZURE_NETWORKING_SERVICE_NETWORK=172.30.0.0/16
#AZURE_OUTBOUND_TYPE=Loadbalancer
#AZURE_ZONE=
#AZURE_NETWORK_RESOURCE_GROUP_NAME=
#AZURE_VIRTUAL_NETWORK=
#AZURE_CONTROL_PLANE_SUBNET=
#AZURE_COMPUTE_SUBNET=
#AZURE_CLOUD_NAME=


#Overrides
#########################
DEBUG=true
