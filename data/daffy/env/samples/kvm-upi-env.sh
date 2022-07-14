############################################################
#Author           : Daffy
#Modified Date    : 2022-02-24
#Environemnt      : KVM
############################################################
#This is a sample KVM install Env file.
############################################################
#No spaces and only AlphaNumeric and  @ or . or -
DAFFY_UNIQUE_ID="YourEmail.com" 


#Bastion info
#####################################
BASTION_HOST="xxx.xxx.xxx.xxx"

#OpenShift Cluster info
#####################################
BASE_DOMAIN="yourdomain.com"
CLUSTER_NAME="yourcluster"
OCP_INSTALL_TYPE="kvm-upi"
OCP_HOST_IP=${BASTION_HOST}

# Tested  OCP_RELEASE  values:  4.6.44, 4.6.46, 4.7.36, 4.8.17
#    Values must match a valid download file value (https://mirror.openshift.com/pub/openshift-v4/clients/ocp/)
OCP_RELEASE="4.8.40"

# Supported VM_TSHIRT_SIZE values: Large, Min
#    Large - 6 Worker Nodes
#    Min - 3 Worker Nodes
VM_TSHIRT_SIZE="Large"

#Network info
####################################
#    KVM IP address are set by default in the env.sh file. You have the option to override these value!
#    All IP addresses will be addresses in this range 192.168.10.90 - 99

#Enable features
#####################################
#VM Dashboard is a web based tool that allows you to mannaged the VM that are build from browser
#VM_DASHBOARD_ENABLED=true

#OCP_CREATE_NFS_STORAGE=false
OCP_CREATE_OPENSHIFT_CONTAINER_STORAGE="true"

#Overrides
#####################################
#    By default Debug is set to true, which will STOP
#DEBUG="true"
