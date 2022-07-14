############################################################
#Author           : Daffy
#Modified Date    : 2022-02-24
#Environemnt      : ROKS
############################################################
#This is for ROKS
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
CLUSTER_NAME="yourcluster"
OCP_INSTALL_TYPE="roks-msp"

# Version must match support version of ROKS only
OCP_RELEASE="4.8.36"

# Supported VM_TSHIRT_SIZE values: Large, Min
#    Large - 6 Worker Nodes
#    Min   - 3 Worker Nodes
VM_TSHIRT_SIZE="Large"

#ROKS Platform
#####################################
#    Zone that ROKS will be installed, default is dal13
#    https://cloud.ibm.com/docs/containers?topic=containers-regions-and-zones
#ROKS_ZONE="dal13"

#      Defaut provider is classic, but if your cluster was provised by techzone, use that as value
#ROKS_PROVIDER="<classic|techzone>"

#    Your own Public VLAN ID. If omitted, will pick existing or craete new one
#ROKS_PUBLIC_LAN="9999999"
#    Your own Private VLAN ID. If omitted, will pick existing or craete new one
#ROKS_PRIVATE_LAN="9999999"


#Overrides
#####################################
#DEBUG="true"
