#https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation
#production Deployment
#install Podman
printHeaderMessage "Install Podman"
source /etc/os-release
echo "deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_${VERSION_ID}"
sh -c "echo 'deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_${VERSION_ID}/ /' > /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list" &> /dev/null
echo  "wget -nv https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/xUbuntu_${VERSION_ID}/Release.key -O- | apt-key add -"
wget -nv https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/xUbuntu_${VERSION_ID}/Release.key -O- | apt-key add - &> /dev/null
echo "apt-get update -qq -y"
apt-get update -qq -y &> /dev/null
echo "apt-get -qq --yes install podman"
apt-get -qq --yes install podman &> /dev/null


#Download scripts
wget https://github.com/IBM/cloud-pak/raw/master/repo/case/ibm-cp-automation-3.2.0.tgz
tar -xvzf ibm-cp-automation-3.2.0.tgz
rm -fR ibm-cp-automation-3.2.0.tgz
mv ibm-cp-automation/inventory/cp4aOperatorSdk/files/deploy/crs/cert-k8s-21.0.3.tar .
tar -xvzf cert-k8s-21.0.3.tar
rm -fR cert-k8s-21.0.3.tar

#Run Scripts to prepare scripts
export CP4BA_AUTO_PLATFORM="OCP"
export CP4BA_AUTO_DEPLOYMENT_TYPE="production"
export CP4BA_AUTO_NAMESPACE="cp4ba-instance1"
export CP4BA_AUTO_ALL_NAMESPACES="No"
export CP4BA_AUTO_CLUSTER_USER="ocpadmin"
export CP4BA_AUTO_STORAGE_CLASS_OCP="ocs-storagecluster-cephfs"
export CP4BA_AUTO_ENTITLEMENT_KEY="XXXXX"
cert-kubernetes/scripts/cp4a-clusteradmin-setup.sh

#Option 2 (Private Cloud)
#Option 2 (Production)
#No      AllNameSpaces
#cp4ba-instance
#1  uesr to use
#yes Entitment key
#past entlment key
#ocs-storagecluster-cephfs storage class

#Copy JDBC Jars to pod
podname=$(oc get pod | grep ibm-cp4a-operator | awk '{print $1}')
kubectl cp ~/jdbc cp4ba-instance/$podname:/opt/ansible/share



oc apply -f service-account-for-anyuid.yaml -n ${CP4BA_AUTO_NAMESPACE}
oc adm policy add-scc-to-user anyuid -z ibm-cp4ba-anyuid -n ${CP4BA_AUTO_NAMESPACE}


#Create DB
db2 create database <database name>
#Apply SQL
CREATE BUFFERPOOL BP32K SIZE 2000 PAGESIZE 32K;
CREATE TABLESPACE RESDWTS PAGESIZE 32K BUFFERPOOL BP32K;
CREATE SYSTEM TEMPORARY TABLESPACE RESDWTMPTS PAGESIZE 32K BUFFERPOOL BP32K;

#Create Secret
kubectl create secret generic odm-db-secret --from-literal=db-user=db2inst1 --from-literal=db-password=M45Ca23Pax -n cp4ba-instance
