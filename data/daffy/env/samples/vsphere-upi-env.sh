############################################################
#Author           : Daffy
#Modified Date    : 2022-02-24
#Environemnt      : vSphere-upi
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
BASTION_USER="bastion"

#OpenShift Cluster info
#####################################
BASE_DOMAIN="yourdomain.com"
CLUSTER_NAME="yourcluster"
OCP_INSTALL_TYPE="vsphere-upi"
OCP_HOST_IP="${BASTION_HOST}"

# Tested  OCP_RELEASE  values:  4.6.44, 4.6.46, 4.7.36, 4.8.18
#    Values must match a valid download file value (https://mirror.openshift.com/pub/openshift-v4/clients/ocp/)
OCP_RELEASE="4.8.40"

# Supported VM_TSHIRT_SIZE values: Large, Min
#    Large - 6 Worker Nodes
#    Min   - 3 Worker Nodes
VM_TSHIRT_SIZE="Large"

#VSphere info
#####################################
#    Log into VSphere Console and find these values!!
VSPHERE_USERNAME='userid' # Userid that you use to log into the VSphere Console
VSPHERE_HOSTNAME='vsphere-host-name'
VSPHERE_DATASTORE='datastore'  # This is the name of the VSphere Datastore
# *******************************
#    IF A FAST DISK DATA STOREIS AVAILABLE ON VSPHERE
#    The scripts will use this datastore if it's set.
VSPHERE_FAST_DISK_DATASTORE='FS9100_VCdemo3_0'
# *******************************
VSPHERE_CLUSTER='cluster-name' # This is the name of the VSphere Cluster
VSPHERE_ISO_DATASTORE='iso-datastore' # This is the name of the datastore where the the coreos iso is located
VSPHERE_ISO_IMAGE_BASE='datastore-directory' # This is the directory within the datastore where the iso image is located.
VSPHERE_NETWORK1='vlan-name' # this is the VSphere VLAN name
VSPHERE_DATACENTER='vsphere-datacenter'  # This is the name of the VSphere Datacenter
VSPHERE_FOLDER="/${VSPHERE_DATACENTER}/vm/${CLUSTER_NAME}"  # This is the location of wehre you will store the NEW VM's.

######  This is a default value
VSPHERE_SYNC_TIME_WITH_HOST="false"     # This setting will allow you to sync the time with the host if not connected to internet (AIR GAP)

#Network info
#####################################
#      Only used for vsphere-upi install
OCP_INSTALL_GATEWAY="xx.xxx.xxx.xx"      # This is the Network Gateway
OCP_FORWARD_DNS="xx.xxx.xxx.xxx"       # This is your Network Forward DNS
OCP_INSTALL_DNS="${BASTION_HOST}"        # This will be the IP address of your Bastion Host
OCP_NODE_SUBNET_MASK="xx"                # This is the subnet mask (usually this is a value of 24)
OCP_INSTALLBOOTSTRAP_IP="xx.xxx.xxx.xx"  # This is the IP address your assigning to the Bootstrap machine
OCP_INSTALL_MASTER1_IP="xx.xxx.xxx.xx"   # This is the IP address your assigning to the Master1 machine
OCP_INSTALL_MASTER2_IP="xx.xxx.xxx.xx"   # This is the IP address your assigning to the Master2 machine
OCP_INSTALL_MASTER3_IP="xx.xxx.xxx.xx"   # This is the IP address your assigning to the Master3 machine
OCP_INSTALL_WORKER1_IP="xx.xxx.xxx.xx"   # This is the IP address your assigning to the Worker1 machine
OCP_INSTALL_WORKER2_IP="xx.xxx.xxx.xx"   # This is the IP address your assigning to the Worker2 machine
OCP_INSTALL_WORKER3_IP="xx.xxx.xxx.xx"   # This is the IP address your assigning to the Worker3 machine

###  Adding 3 Additioanl Worker nodes for a Large T-Shirt Size Cluster
OCP_INSTALL_WORKER4_IP="xx.xxx.xxx.xx"   # This is the IP address your assigning to the Worker4 machine
OCP_INSTALL_WORKER5_IP="xx.xxx.xxx.xx"   # This is the IP address your assigning to the Worker5 machine
OCP_INSTALL_WORKER6_IP="xx.xxx.xxx.xx"   # This is the IP address your assigning to the Worker6 machine

#Enable storage features
#####################################
#   Defalut values are false!
#OCP_CREATE_NFS_STORAGE=false
OCP_CREATE_OPENSHIFT_CONTAINER_STORAGE="true"

#Local Registry Info (AIR GAP INSTALL)
####################################
#   These are ONLY used if you are doing an AIR GAP install.
#LOCAL_REGISTRY_ENABLED=true
#LOCAL_REGISTRY_DNS_NAME=openshift-local-registry.ibm-cp4-dojo.net

#Cert info EXAMPLE
#####################################
#   These are just sample values. They are specific to the domain and requires a CERT API Key.
#CERT_ID=crn:v1:bluemix:public:cloudcerts:us-south:a/1df0f17a7f0213c2c6ee94b97e3712b7:1760927f-b3ac-41b2-a0cf-b4cd23d37b27:certificate:8ba37ec565ca3ca732031e3cb1d09bf3
#OCP_TRUSTE_CA_NAME=lets-encrypt


#Overrides
#####################################
#VSPHERE_RESOURCE_POOL='*/Resources'   # This is where the pooled resources are stored. It's not normally something we will need to change.
#ESXi_HARDWARE_VERSION_VM_CREATE=6.5
#VSPHERE_SYNC_TIME_WITH_HOST=false
#DEBUG="true"
