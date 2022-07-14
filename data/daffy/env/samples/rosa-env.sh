############################################################
#Author           : Daffy
#Modified Date    : 2022-02-24
#Environment      : ROSA
############################################################
#This is for ROSA
###########################################
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
CLUSTER_NAME="yourcluster"
OCP_INSTALL_TYPE="rosa-msp"

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

#Enable Features
#############################
#OCP_CREATE_OPENSHIFT_CONTAINER_STORAGE="true"

#Overrides
#####################################
#DEBUG="true"
