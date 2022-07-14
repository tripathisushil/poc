#!/bin/bash
############################################################
#Author           : Kyle Dawson
#Author email     : Kyle.Dawson@us.ibm.com
#Original Date    : 2021-09-23
#Initial Version  : v2021-12-01
############################################################
displayOCPLoadBalanceRules()
{
  printHeaderMessage "Display OCP Load Balancer Rules Needed"
  echo "?????????????????Need to fill out this logic still????????????????????"

}

displayIgnitionFilesInfo()
{
  printHeaderMessage "Display Location of Ignition Files"
  echo "?????????????????Need to fill out this logic still????????????????????"

}
displayOCPDNSRequirements()
{
  printHeaderMessage "Display OCP DNS Records Needed"
  setClusterPTRRecordFromIP
  case ${OCP_INSTALL_TYPE} in
        *upi)
            echo "DNS --type A    --name *.apps.${CLUSTER_NAME}.${BASE_DOMAIN}                --content ${OCP_HOST_IP}"
            echo "DNS --type A    --name api.${CLUSTER_NAME}.${BASE_DOMAIN}                   --content ${OCP_HOST_IP}"
            echo "DNS --type A    --name api-int.${CLUSTER_NAME}.${BASE_DOMAIN}               --content ${OCP_HOST_IP}"
            echo "DNS --type A    --name bootstrap.${CLUSTER_NAME}.${BASE_DOMAIN}             --content ${OCP_INSTALLBOOTSTRAP_IP}"
            echo "DNS --type PTR  --name ${OCP_INSTALL_BOOTSTRAP_PTR_RECORD}                                 --content bootstrap.${CLUSTER_NAME}.${BASE_DOMAIN}"
            echo "DNS --type A    --name master1.${CLUSTER_NAME}.${BASE_DOMAIN}               --content ${OCP_INSTALL_MASTER1_IP}"
            echo "DNS --type PTR  --name ${OCP_INSTALL_MASTER1_PTR_RECORD}                                 --content master1.${CLUSTER_NAME}.${BASE_DOMAIN}"
            echo "DNS --type A    --name Master2.${CLUSTER_NAME}.${BASE_DOMAIN}               --content ${OCP_INSTALL_MASTER2_IP}"
            echo "DNS --type PTR  --name ${OCP_INSTALL_MASTER2_PTR_RECORD}                                 --content master2.${CLUSTER_NAME}.${BASE_DOMAIN}"
            echo "DNS --type A    --name master3.${CLUSTER_NAME}.${BASE_DOMAIN}               --content ${OCP_INSTALL_MASTER3_IP}"
            echo "DNS --type PTR  --name ${OCP_INSTALL_MASTER3_PTR_RECORD}                                 --content master3.${CLUSTER_NAME}.${BASE_DOMAIN}"
            echo "DNS --type A    --name worker1.${CLUSTER_NAME}.${BASE_DOMAIN}               --content ${OCP_INSTALL_WORKER1_IP}"
            echo "DNS --type PTR  --name ${OCP_INSTALL_WORKER1_PTR_RECORD}                                 --content worker1.${CLUSTER_NAME}.${BASE_DOMAIN}"
            echo "DNS --type A    --name worker2.${CLUSTER_NAME}.${BASE_DOMAIN}               --content ${OCP_INSTALL_WORKER2_IP}"
            echo "DNS --type PTR  --name ${OCP_INSTALL_WORKER2_PTR_RECORD}                                 --content worker2.${CLUSTER_NAME}.${BASE_DOMAIN}"
            echo "DNS --type A    --name worker3.${CLUSTER_NAME}.${BASE_DOMAIN}               --content ${OCP_INSTALL_WORKER3_IP}"
            echo "DNS --type PTR  --name ${OCP_INSTALL_WORKER3_PTR_RECORD}                                 --content worker3.${CLUSTER_NAME}.${BASE_DOMAIN}"
            if [ "${VM_TSHIRT_SIZE}" == "Large" ]  ;then
                echo "DNS --type A    --name worker4.${CLUSTER_NAME}.${BASE_DOMAIN}               --content ${OCP_INSTALL_WORKER4_IP}"
                echo "DNS --type PTR  --name ${OCP_INSTALL_WORKER4_PTR_RECORD}                                 --content worker4.${CLUSTER_NAME}.${BASE_DOMAIN}"
                echo "DNS --type A    --name worker5.${CLUSTER_NAME}.${BASE_DOMAIN}               --content ${OCP_INSTALL_WORKER5_IP}"
                echo "DNS --type PTR  --name ${OCP_INSTALL_WORKER5_PTR_RECORD}                                 --content worker5.${CLUSTER_NAME}.${BASE_DOMAIN}"
                echo "DNS --type A    --name worker6.${CLUSTER_NAME}.${BASE_DOMAIN}               --content ${OCP_INSTALL_WORKER6_IP}"
                echo "DNS --type PTR  --name ${OCP_INSTALL_WORKER6_PTR_RECORD}                                 --content worker6.${CLUSTER_NAME}.${BASE_DOMAIN}"
            fi
            ;;
        *ipi)
            echo "DNS --type A --name  api.${OCP_HOST_NAME} --content ${VSPHERE_API_VIP}"
            echo "DNS --type A --name  *.apps.${OCP_HOST_NAME} --content ${VSPHERE_INGRESS_VIP}"
            ;;
  esac
echo ""
echo ""
}
