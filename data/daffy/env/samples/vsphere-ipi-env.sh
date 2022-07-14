############################################################
#Author           : Daffy
#Modified Date    : 2022-02-24
#Environemnt      : vSphere-IPI
############################################################
#This is for VCenter enviornment
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

#Bastion info
#####################################
BASTION_HOST="xx.xxx.xxx.x"

#OpenShift Cluster info
#####################################
BASE_DOMAIN="yourdomain.com"
CLUSTER_NAME="YOUR_CLUSTER"
OCP_INSTALL_TYPE="vsphere-ipi"

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

#Enable OCP Storage features
#####################################
#OCP_CREATE_NFS_STORAGE=true
OCP_CREATE_OPENSHIFT_CONTAINER_STORAGE="true"

#VSphere info
#####################################
#    Log into VSphere Console and find these values!!
VSPHERE_USERNAME='userid' # Userid that you use to log into the VSphere Console
VSPHERE_HOSTNAME='vsphere-host-name'
VSPHERE_DATASTORE='datastore'  # This is the name of the VSphere Datastore

#    IF A FAST DISK DATA STOREIS AVAILABLE ON VSPHERE
#    The scripts will use this datastore if it's set.
#VSPHERE_FAST_DISK_DATASTORE='datastore'

VSPHERE_CLUSTER='cluster-name' # This is the name of the VSphere Cluster
VSPHERE_ISO_DATASTORE='iso-datastore' # This is the name of the datastore where the the coreos iso is located
VSPHERE_ISO_IMAGE_BASE='datastore-directory' # This is the directory within the datastore where the iso image is located.
VSPHERE_NETWORK1='vlan-name' # this is the VSphere VLAN name
VSPHERE_DATACENTER='vsphere-datacenter'  # This is the name of the VSphere Datacenter
VSPHERE_FOLDER="/${VSPHERE_DATACENTER}/vm/${CLUSTER_NAME}"  # This is the location of wehre you will store the NEW VM's.

#     VSphere Network details - ONLY USED FOR IPI INSTALL
VSPHERE_API_VIP="xx.xxx.xxx.xxx"  #This must be unused IP in the network
VSPHERE_INGRESS_VIP="xx.xxx.xxx"  #This must be unused IP in the network


#Local Registry Info (AIR GAP INSTALL)
####################################
#   These are ONLY used if you are doing an AIR GAP install.
#LOCAL_REGISTRY_ENABLED=true
#LOCAL_REGISTRY_DNS_NAME=openshift-local-registry.ibm-cp4-dojo.net

#Overrides
#####################################
#ESXi_HARDWARE_VERSION_VM_CREATE=6.5
#VSPHERE_SYNC_TIME_WITH_HOST=false
#VSPHERE_NETWORKING_CLUSTERNETWORK_CIDR=10.128.0.0/14
#VSPHERE_NETWORKING_CLUSTERNETWORK_HOSTPREFIX=23
#VSPHERE_NETWORKING_NETWORKTYPE=OpenShiftSDN
#VSPHERE_NETWORKING_SERVICE_NETWORK=172.30.0.0/16
#VSPHERE_INSTALL_PUBLISH=External
#OCP_FIPS=false
#DEBUG="true"
