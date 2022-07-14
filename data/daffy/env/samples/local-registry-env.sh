############################################################
#Author           : Kyle Dawson
#Author email     : Kyle.Dawson@us.ibm.com
#Original Date    : 2021-10-02
#Initial Version  : v2021-12-01
############################################################

#Local Info Specific
##################
LOCAL_REGISTRY_ENABLED="true"
CA_CERT_OU="YourOU.net"                          #Optional, only need if you plan to build your local repo
OCP_REDHAT_REGISTRY_USERNAME="YourUsername"      #Optional, only need if you plan to build your local repo
LOCAL_REGISTRY_DNS_NAME="YourDNSName.net"
LOCAL_REGISTRY_AUTH_INFO='{"<URL>:5000": {"auth": "<PASSWORD>","email": "<EMAIL>"}}'

#Version Specific
##################
OCP_RELEASE="4.6.44"

#Overrides
##################
#OCP_CATALOG_MIRRORS=local-storage-operator
#DEBUG="true"
