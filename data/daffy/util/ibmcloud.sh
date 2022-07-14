#!/bin/bash
############################################################
#Author           : Kyle Dawson
#Author email     : Kyle.Dawson@us.ibm.com
#Original Date    : 2021-09-25
#Initial Version  : v2021-12-01
############################################################
installIBMCloudCommandLine()
{
  FOUND_CURL_COMMAND=`which curl | grep -c "curl"`
  if [ ${FOUND_CURL_COMMAND} == 0 ] ;then
    echo "Missing curl command, installing now."
    $OS_INSTALL -y install curl > ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/installingCurl.log
  fi
  FOUND_IBM_CLOUD_COMMAND=`which ibmcloud 2>/dev/null | grep -c "ibmcloud"`
  if [ ${FOUND_IBM_CLOUD_COMMAND} == 0 ] ;then
    echo "Missing ibmcloud command, installing now.(This will take a few minutes........)"
    curl -sL https://ibm.biz/idt-installer | bash &> ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/installIBMCloudCommandLine.log
  fi
  FOUND_IBMCLOUD_CIS=`ibmcloud plugin list | grep -c cloud-internet-services`
  if [ ${FOUND_IBMCLOUD_CIS} == 0 ] ;then
    #Install needed plugins here
    #CIS is needed for DNS entry creations in IBM CLoud
    echo "Installing IBM Cloud CIS plugin"
    ibmcloud plugin install cis -f >> ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/installIBMCloudCommandLine.log 2>&1
    echo ""
  fi
  FOUND_IBMCLOUD_KS=`ibmcloud plugin list | grep -c container-service`
  if [ ${FOUND_IBMCLOUD_KS} == 0 ] ;then
    echo "Installing IBM Cloud container-service plugin"
    ibmcloud plugin install container-service -f >> ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/installIBMCloudCommandLine.log 2>&1
    echo ""
  fi
  #To prvent script from prompting user for updates
  ibmcloud config --check-version=false
}
createIBMCloudDNSEntries()
{

    if [[ "${CURRENT_SCRIPT_NAME}" == *build.sh ]];then
          local BASE_SUBDOMAIN=`grep -o "\." <<<"$BASE_DOMAIN" | wc -l`
          if [[ ${BASE_SUBDOMAIN} -eq 2 ]]; then
            local NEW_SUBDOMAIN_NAME=`echo ${BASE_DOMAIN} | sed "s/\..*//g"`
            local NEW_CLUSTER_NAME=${CLUSTER_NAME}.${NEW_SUBDOMAIN_NAME}
          else
            local NEW_CLUSTER_NAME=${CLUSTER_NAME}
          fi
          if [  ${BASE_SUBDOMAIN} -ge 3 ] && [ ! -z "${DNS_API_KEY}" ]; then
            SHOULD_EXIT=1
            printHeaderMessage "Create IBM Cloud DNS Entries"
            echo "${RED_TEXT}Unsupported DNS Subdomain levels, Daffy Only supports one level of Subdomain for IBM Cloud DNS${RESET_TEXT}"
            echo ""
          else
              case ${OCP_INSTALL_TYPE} in
                *upi)
                    if [ -z "${OCP_HOST_IP}" ] || [ -z "${DNS_API_KEY}" ];then
                      #echo "OCP_HOST_IP or DNS_API_KEY not set, will not build IBM Cloud DNS Entries"
                      SKIP_IBM_DNS=true
                    else
                        printHeaderMessage "Create IBM Cloud DNS Entries (LOG ->  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createIBMDNSEntries.log)"
                        installIBMCloudCommandLine
                        ibmcloud login --apikey ${DNS_API_KEY} -r ${IBMCLOUD_REGION} >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createIBMDNSEntries.log 2>&1

                        #*.apps.${CLUSTER_NAME}
                        DNS_RECORD_ID=`ibmcloud cis dns-records ${DNS_DOMAIN_ID} -i ${CIS_INSTANCE_NAME} --name *.apps.${CLUSTER_NAME}.${BASE_DOMAIN} 2>> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/getIBMDNSEntries.log | grep apps.${CLUSTER_NAME}.${BASE_DOMAIN} | awk '{print $1}'`
                        if [ -z "${DNS_RECORD_ID}" ]; then
                            echo "ibmcloud cis dns-record-create ${DNS_DOMAIN_ID} --type A --name "*.apps.${NEW_CLUSTER_NAME}" --content ${OCP_HOST_IP} -i ${CIS_INSTANCE_NAME}"
                            ibmcloud cis dns-record-create ${DNS_DOMAIN_ID} --type A --name \*.apps.${NEW_CLUSTER_NAME} --content ${OCP_HOST_IP} -i ${CIS_INSTANCE_NAME} --ttl 60 >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createIBMDNSEntries.log 2>&1
                            sleep 30
                        else
                            echo "ibmcloud cis dns-record-update ${DNS_DOMAIN_ID} --type A --name *.apps.${NEW_CLUSTER_NAME} --content ${OCP_HOST_IP} -i ${CIS_INSTANCE_NAME}"
                            ibmcloud cis dns-record-update ${DNS_DOMAIN_ID} ${DNS_RECORD_ID} -i ${CIS_INSTANCE_NAME} --content ${OCP_HOST_IP} >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createIBMDNSEntries.log 2>&1
                        fi
                        #api.${CLUSTER_NAME}
                        DNS_RECORD_ID=`ibmcloud cis dns-records ${DNS_DOMAIN_ID} -i ${CIS_INSTANCE_NAME} --name api.${CLUSTER_NAME}.${BASE_DOMAIN} 2>> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/getIBMDNSEntries.log | grep api.${CLUSTER_NAME}.${BASE_DOMAIN} | awk '{print $1}'`
                        if [ -z "${DNS_RECORD_ID}" ]; then
                            echo "ibmcloud cis dns-record-create ${DNS_DOMAIN_ID} --type A --name api.${NEW_CLUSTER_NAME} --content ${OCP_HOST_IP} -i ${CIS_INSTANCE_NAME}"
                            ibmcloud cis dns-record-create ${DNS_DOMAIN_ID} --type A --name api.${NEW_CLUSTER_NAME} --content ${OCP_HOST_IP} -i ${CIS_INSTANCE_NAME} --ttl 60 >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createIBMDNSEntries.log 2>&1
                            sleep 30
                        else
                            echo "ibmcloud cis dns-record-update ${DNS_DOMAIN_ID} --type A --name api.${NEW_CLUSTER_NAME} --content ${OCP_HOST_IP} -i ${CIS_INSTANCE_NAME}"
                            ibmcloud cis dns-record-update ${DNS_DOMAIN_ID} ${DNS_RECORD_ID} -i ${CIS_INSTANCE_NAME} --content ${OCP_HOST_IP} >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createIBMDNSEntries.log 2>&1
                        fi

                        #api-int.${CLUSTER_NAME}
                        DNS_RECORD_ID=`ibmcloud cis dns-records ${DNS_DOMAIN_ID} -i ${CIS_INSTANCE_NAME} --name api-int.${CLUSTER_NAME}.${BASE_DOMAIN} 2>> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/getIBMDNSEntries.log | grep api-int.${CLUSTER_NAME}.${BASE_DOMAIN} | awk '{print $1}'`
                        if [ -z "${DNS_RECORD_ID}" ]; then
                            echo "ibmcloud cis dns-record-create ${DNS_DOMAIN_ID} --type A --name api-int.${NEW_CLUSTER_NAME} --content ${OCP_HOST_IP} -i ${CIS_INSTANCE_NAME}"
                            ibmcloud cis dns-record-create ${DNS_DOMAIN_ID} --type A --name api-int.${NEW_CLUSTER_NAME} --content ${OCP_HOST_IP} -i ${CIS_INSTANCE_NAME} --ttl 60 >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createIBMDNSEntries.log 2>&1
                            sleep 30
                        else
                            echo "ibmcloud cis dns-record-update ${DNS_DOMAIN_ID} --type A --name api-int.${NEW_CLUSTER_NAME} --content ${OCP_HOST_IP} -i ${CIS_INSTANCE_NAME}"
                            ibmcloud cis dns-record-update ${DNS_DOMAIN_ID} ${DNS_RECORD_ID} -i ${CIS_INSTANCE_NAME} --content ${OCP_HOST_IP} >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createIBMDNSEntries.log 2>&1
                        fi

                        echo ""
                        systemd-resolve --flush-caches >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createIBMDNSEntries.log 2>&1
                        resolvectl flush-caches >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createIBMDNSEntries.log 2>&1
                        systemctl restart dnsmasq >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createIBMDNSEntries.log 2>&1
                        DNS_CREATE_FAILED=`cat ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createIBMDNSEntries.log | grep -c FAILED`
                        if [ ${DNS_CREATE_FAILED} -gt 0 ]; then
                          echo "${RED_TEXT} DNS Record Creation failed, will not continue."
                          echo "#######################################################################"
                          echo "New Log file - ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/createIBMDNSEntriesFailed.log"
                          cat ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createIBMDNSEntries.log | grep "Error\|FAILED"
                          echo "#######################################################################${RESET_TEXT}"
                          echo ""
                          echo ""
                          mv ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createIBMDNSEntries.log ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/createIBMDNSEntriesFailed.log
                          exit 9
                        fi
                        echo ""
                    fi
                    ;;
                *ipi)
                    if [ -z "${VSPHERE_API_VIP}" ] ||  [ -z "${VSPHERE_INGRESS_VIP}" ] || [ -z "${DNS_API_KEY}" ] ;then
                        #echo "VSPHERE_API_VIP or VSPHERE_INGRESS_VIP or DNS_API_KEY not set, will not build DNS Entries"
                        SKIP_IBM_DNS=true
                    else
                        printHeaderMessage "Create IBM Cloud DNS Entries (LOG ->  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createIBMDNSEntries.log)"
                        installIBMCloudCommandLine
                        ibmcloud login --apikey ${DNS_API_KEY} -r ${IBMCLOUD_REGION} >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createIBMDNSEntries.log
                        #*.apps.${CLUSTER_NAME}
                        DNS_RECORD_ID=`ibmcloud cis dns-records ${DNS_DOMAIN_ID} -i ${CIS_INSTANCE_NAME}  --name *.apps.${CLUSTER_NAME}.${BASE_DOMAIN} 2>> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/getIBMDNSEntries.log | grep apps.${CLUSTER_NAME}.${BASE_DOMAIN} | awk '{print $1}'`
                        if [ -z "${DNS_RECORD_ID}" ]; then
                            echo "ibmcloud cis dns-record-create ${DNS_DOMAIN_ID} --type A --name *.apps.${NEW_CLUSTER_NAME} --content ${VSPHERE_INGRESS_VIP} -i ${CIS_INSTANCE_NAME}"
                            ibmcloud cis dns-record-create ${DNS_DOMAIN_ID} --type A --name *.apps.${NEW_CLUSTER_NAME} --content ${VSPHERE_INGRESS_VIP} -i ${CIS_INSTANCE_NAME} --ttl 60 >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createIBMDNSEntries.log 2>&1
                            sleep 30
                        else
                            echo "ibmcloud cis dns-record-update ${DNS_DOMAIN_ID} --type A --name *.apps.${NEW_CLUSTER_NAME} --content ${VSPHERE_INGRESS_VIP} -i ${CIS_INSTANCE_NAME}"
                            ibmcloud cis dns-record-update ${DNS_DOMAIN_ID} ${DNS_RECORD_ID} -i ${CIS_INSTANCE_NAME} --content ${VSPHERE_INGRESS_VIP} >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createIBMDNSEntries.log 2>&1
                        fi
                        #api.${CLUSTER_NAME}
                        DNS_RECORD_ID=`ibmcloud cis dns-records ${DNS_DOMAIN_ID} -i ${CIS_INSTANCE_NAME} --name api.${CLUSTER_NAME}.${BASE_DOMAIN} 2>> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/getIBMDNSEntries.log | grep api.${CLUSTER_NAME}.${BASE_DOMAIN} | awk '{print $1}'`
                        if [ -z "${DNS_RECORD_ID}" ]; then
                            echo "ibmcloud cis dns-record-create ${DNS_DOMAIN_ID} --type A --name api.${NEW_CLUSTER_NAME} --content ${VSPHERE_API_VIP} -i ${CIS_INSTANCE_NAME}"
                            ibmcloud cis dns-record-create ${DNS_DOMAIN_ID} --type A --name api.${NEW_CLUSTER_NAME} --content ${VSPHERE_API_VIP} -i ${CIS_INSTANCE_NAME} --ttl 60 >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createIBMDNSEntries.log 2>&1
                            sleep 30
                        else
                            echo "ibmcloud cis dns-record-update ${DNS_DOMAIN_ID} --type A --name api.${NEW_CLUSTER_NAME} --content ${VSPHERE_API_VIP} -i ${CIS_INSTANCE_NAME}"
                            ibmcloud cis dns-record-update ${DNS_DOMAIN_ID} ${DNS_RECORD_ID} -i ${CIS_INSTANCE_NAME} --content ${VSPHERE_API_VIP} >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createIBMDNSEntries.log 2>&1
                        fi
                        DNS_CREATE_FAILED=`cat ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createIBMDNSEntries.log | grep -c FAILED`
                        if [ ${DNS_CREATE_FAILED} -gt 0 ]; then
                          echo "${RED_TEXT} DNS Record Creation failed, will not continue."
                          echo "#######################################################################"
                          echo "New Log file - ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/createIBMDNSEntriesFailed.log"
                          cat ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createIBMDNSEntries.log | grep "Error\|FAILED"
                          echo "#######################################################################${RESET_TEXT}"
                          echo ""
                          echo ""
                          mv ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createIBMDNSEntries.log ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/createIBMDNSEntriesFailed.log
                          exit 9
                        fi
                        systemd-resolve --flush-caches >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createIBMDNSEntries.log 2>&1
                        resolvectl flush-caches >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createIBMDNSEntries.log 2>&1
                        systemctl restart dnsmasq >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/createIBMDNSEntries.log 2>&1
                        #blinkWaitMessage "Sleeping for 3 min to allow DNS entry to propagate!!!!!!" 180
                        echo ""
                    fi
                    ;;
                esac
          fi
    fi

}
removeIBMCloudDNSEntries()
{
  case ${OCP_INSTALL_TYPE} in
  *upi)
        printHeaderMessage "Remove IBM Cloud DNS Entrires" ${RED_TEXT}
        if [ -z "${OCP_HOST_IP}" ] || [ -z "${DNS_API_KEY}" ];then
          echo "OCP_HOST_IP or DNS_API_KEY not set, will not remove DNS Entries"
        else
          installIBMCloudCommandLine
          ibmcloud login --apikey ${DNS_API_KEY} -r ${IBMCLOUD_REGION} >> ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/removeIBMDNSEntries.log 2>&1
          DNS_RECORD_ID=`ibmcloud cis dns-records ${DNS_DOMAIN_ID} -i ${CIS_INSTANCE_NAME} | grep apps.${CLUSTER_NAME} | awk '{print $1}'`
          echo "*.apps.${CLUSTER_NAME}.${BASE_DOMAIN} - ibmcloud cis dns-record-delete ${DNS_DOMAIN_ID} ${DNS_RECORD_ID} -i ${CIS_INSTANCE_NAME}"
          ibmcloud cis dns-record-delete ${DNS_DOMAIN_ID} ${DNS_RECORD_ID} -i ${CIS_INSTANCE_NAME} >> ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/removeIBMDNSEntries.log 2>&1
          DNS_RECORD_ID=`ibmcloud cis dns-records ${DNS_DOMAIN_ID} -i ${CIS_INSTANCE_NAME}| grep api.${CLUSTER_NAME} | awk '{print $1}'`
          echo "api.${CLUSTER_NAME}.${BASE_DOMAIN} - ibmcloud cis dns-record-delete ${DNS_DOMAIN_ID} ${DNS_RECORD_ID} -i ${CIS_INSTANCE_NAME}"
          ibmcloud cis dns-record-delete ${DNS_DOMAIN_ID} ${DNS_RECORD_ID} -i ${CIS_INSTANCE_NAME} >> ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/removeIBMDNSEntries.log 2>&1
          DNS_RECORD_ID=`ibmcloud cis dns-records ${DNS_DOMAIN_ID} -i ${CIS_INSTANCE_NAME} | grep api-int.${CLUSTER_NAME} | awk '{print $1}'`
          echo "api-int.${CLUSTER_NAME}.${BASE_DOMAIN} - ibmcloud cis dns-record-delete ${DNS_DOMAIN_ID} ${DNS_RECORD_ID} -i ${CIS_INSTANCE_NAME}"
          ibmcloud cis dns-record-delete ${DNS_DOMAIN_ID} ${DNS_RECORD_ID} -i ${CIS_INSTANCE_NAME} >> ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/removeIBMDNSEntries.log 2>&1
          DNS_RECORD_ID=`ibmcloud cis dns-records ${DNS_DOMAIN_ID} -i ${CIS_INSTANCE_NAME} | grep ${CLUSTER_NAME}.${BASE_DOMAIN} | awk '{print $1}'`
          fi
        ;;
  *ipi)
        printHeaderMessage "Remove IBM Cloud DNS Entrires" ${RED_TEXT}
        if [ -z "${DNS_API_KEY}" ];then
          echo "DNS_API_KEY not set, will not remove DNS Entries"
        else
          installIBMCloudCommandLine
          ibmcloud login --apikey ${DNS_API_KEY} -r ${IBMCLOUD_REGION} >> ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/removeIBMDNSEntries.log 2>&1
          DNS_RECORD_ID=`ibmcloud cis dns-records ${DNS_DOMAIN_ID} -i ${CIS_INSTANCE_NAME} | grep apps.${CLUSTER_NAME} | awk '{print $1}'`
          echo "*.apps.${CLUSTER_NAME}.${BASE_DOMAIN} - ibmcloud cis dns-record-delete ${DNS_DOMAIN_ID} ${DNS_RECORD_ID} -i ${CIS_INSTANCE_NAME}"
          ibmcloud cis dns-record-delete ${DNS_DOMAIN_ID} ${DNS_RECORD_ID} -i ${CIS_INSTANCE_NAME} >> ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/removeIBMDNSEntries.log 2>&1
          DNS_RECORD_ID=`ibmcloud cis dns-records ${DNS_DOMAIN_ID} -i ${CIS_INSTANCE_NAME}| grep api.${CLUSTER_NAME} | awk '{print $1}'`
          echo "api.${CLUSTER_NAME}.${BASE_DOMAIN} - ibmcloud cis dns-record-delete ${DNS_DOMAIN_ID} ${DNS_RECORD_ID} -i ${CIS_INSTANCE_NAME}"
          ibmcloud cis dns-record-delete ${DNS_DOMAIN_ID} ${DNS_RECORD_ID} -i ${CIS_INSTANCE_NAME} >> ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/removeIBMDNSEntries.log 2>&1
        fi
        ;;
    esac
    systemd-resolve --flush-caches >> ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/removeIBMDNSEntries.log 2>&1
    resolvectl flush-caches >> ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/removeIBMDNSEntries.log 2>&1
    systemctl restart dnsmasq >> ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/removeIBMDNSEntries.log 2>&1
    echo ""
}
getNewCerts()
{
  #printHeaderMessage "Getting IBM Cloud Certs"
  if [ -z "${CERT_API_KEY}" ] || [ -z "${CERT_ID}" ];then
    #echo "CERT_API_KEY,CERT_ID not set, will not download certs."
    SKIP_NEW_DNS_CERTS=true
  else
    mkdir -p ${TEMP_DIR}/${PRODUCT_SHORT_NAME}
    CERT_ID=$(php -r "echo rawurlencode('$CERT_ID');")
    echo "Getting API Token"
    API_TOKEN=`curl -X POST -H "Content-Type: application/x-www-form-urlencoded" -H "Accept: application/json" -d "grant_type=urn%3Aibm%3Aparams%3Aoauth%3Agrant-type%3Aapikey&apikey=${CERT_API_KEY}"  https://iam.cloud.ibm.com/identity/token | sed 's/{"access_token":"//g' | sed 's/","refresh_token.*//g'`
    echo "Downloading Certs from ${IBMCLOUD_REGION}.certificate-manager.cloud.ibm.com"
    curl -H "Authorization: Bearer ${API_TOKEN}" https://${IBMCLOUD_REGION}.certificate-manager.cloud.ibm.com/api/v2/certificate/${CERT_ID} > ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/certs.json

    #Break up certs
    ################
    #Test if valid cert
    VALID_CERTS=`cat ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/certs.json | grep -c BEGIN`
    if [ "${VALID_CERTS}" == "1" ]; then
      cat ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/certs.json | sed 's/.*content":"//g' | sed 's/",".*//g' > ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/tls.crt
      cat ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/certs.json | sed 's/.*intermediate":"//g' |  sed 's/","priv_key.*//g' >> ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/tls.crt
      echo -e `cat ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/tls.crt` > ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/tls.crt
      cat ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/certs.json | sed 's/.*priv_key":"//g' |  sed 's/"},".*//g' > ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/tls.key
      echo -e `cat ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/tls.key` > ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/tls.key
    else
      echo "Invalid Cert was downloaded, will not update cluster Secret"
    fi
  fi
}
restartRoksNodes()
{
  printHeaderMessage "Restart ROKS Nodes"
  testIBMCloudLogin
  local ROKS_SATELLITE=`ibmcloud ks cluster ls --provider satellite --output json |   grep hostname | grep -c ${CLUSTER_NAME}`
  if [  ${ROKS_SATELLITE} -eq 1 ]; then
      echo "The cluster ${CLUSTER_NAME} is a ROKS Satellite and does not support reload feature from command line."
      echo "Please refer to this link to manual steps:  ${BLUE_TEXT}http://ibm.biz/sat-workers${RESET_TEXT}"
      echo "We will continue with install but for the pull secret to work, you will need to reload after this step on your own."
      echo ""
      echo ""
      read -p "Press [Enter] key to resume ..."
  else
      startWaitForNode=$SECONDS
      ROKS_NODES=`ibmcloud oc worker ls -c ${CLUSTER_NAME} | grep -v "ID\|OK\|To update" | awk '{print $1}'`
      ROKS_COUNT=0
      for ROKS_NODE in $ROKS_NODES
      do
        WORKER_LIST="${WORKER_LIST} -w ${ROKS_NODE} "
        let ROKS_COUNT=ROKS_COUNT+1
      done
      echo "ibmcloud oc worker reload -q  -f -c ${CLUSTER_NAME} ${WORKER_LIST}"
      ibmcloud oc worker reload -q -f -c ${CLUSTER_NAME}  ${WORKER_LIST}
      echo ""
      blinkWaitMessage "Waiting for ROKS nodes to trigger Reload(2 Min)" 120
      local LOOP_COUNT=0
      NODES_READY=`oc get nodes 2> /dev/null | grep -c " Ready "`
      while [ ${NODES_READY} -ne ${ROKS_COUNT} ]; do
          blinkWaitMessage "Waiting for ROKS nodes to be ready -  ${LOOP_COUNT} Min(s) so far" 60
          NODES_READY=`oc get nodes 2> /dev/null | grep -c " Ready "`
          let LOOP_COUNT=LOOP_COUNT+1
      done
      now=$SECONDS
      let "diff=now-startWaitForNode"
      startWaitForNode=${diff}
      if (( $startWaitForNode > 3600 )) ; then
          let "hours=startWaitForNode/3600"
          let "minutes=(startWaitForNode%3600)/60"
          let "seconds=(startWaitForNode%3600)%60"
          echo "${BLUE_TEXT}COMPLETE ${RESET_TEXT}All ROKS nodes restarted in $hours hour(s), $minutes minute(s) and $seconds second(s)"
      elif (( $startWaitForNode > 60 )) ; then
          let "minutes=(startWaitForNode%3600)/60"
          let "seconds=(startWaitForNode%3600)%60"
          echo "${BLUE_TEXT}COMPLETE ${RESET_TEXT}All ROKS nodes restarted in $minutes minute(s) and $seconds second(s)"
      else
          echo "${BLUE_TEXT}COMPLETE ${RESET_TEXT}All ROKS nodes restarted in $startWaitForNode seconds"
      fi
  fi
}

testIBMCloudLogin()
{
  #printHeaderMessage "Test Login to IBM Cloud"
  if [ "${ROKS_PROVIDER}" != "techzone" ]; then
      installIBMCloudCommandLine
      ibmcloud resource groups -q 1> ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/ibmlogin-output.txt 2> ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/ibmlogin-output.txt
      ERROR_OUTPUT=$(<${TEMP_DIR}/${PRODUCT_SHORT_NAME}/ibmlogin-output.txt)
      NOT_LOGGED_INTO_IBM_CLOUD1=`echo $ERROR_OUTPUT | grep -c "Not logged in"`
      NOT_LOGGED_INTO_IBM_CLOUD2=`echo $ERROR_OUTPUT | grep -c "No API endpoint set"`
      NOT_LOGGED_INTO_IBM_CLOUD3=`echo $ERROR_OUTPUT | grep -c "expired"`
      if [ ${NOT_LOGGED_INTO_IBM_CLOUD1} = 1 ] || [ ${NOT_LOGGED_INTO_IBM_CLOUD2} = 1 ] || [ ${NOT_LOGGED_INTO_IBM_CLOUD3} = 1 ]   ;  then
          if [ ! -z ${IBMCLOUD_API_KEY} ]; then
              echo "${BLUE_TEXT}INFO ${RESET_TEXT} Signing in with IBM Cloud API Key"
              ibmcloud login --apikey ${IBMCLOUD_API_KEY} -g ${IBMCLOUD_RESOURCE_GROUP} -r ${IBMCLOUD_REGION}
          else
              echo "${RED_TEXT}You are not logged into ibmcloud. PLease login:${RESET_TEXT}";
              ibmcloud login --sso -g ${IBMCLOUD_RESOURCE_GROUP}
          fi
          testIBMCloudLogin
      else
          if [ "${IBM_LOGIN_OK}" != "true" ]; then
              echo "${BLUE_TEXT}PASSED ${RESET_TEXT} Your are logged into IBM Cloud"
              IBM_LOGIN_OK=true
          fi
      fi
  fi
}

createROKSCluster()
{
  printHeaderMessage "Create ROKS Cluster"
  echo "Creation of ROKS cluster is dependent on the IBM Provider, this typical takes 30-45 minutes."
  ibmcloud target -g ${IBMCLOUD_RESOURCE_GROUP}
  if [ "${IBM_VLAN}" == "false" ]; then
     echo "ibmcloud oc cluster create ${ROKS_PROVIDER} --name ${CLUSTER_NAME} --version ${OCP_BASE_VERSION}_openshift --zone ${ROKS_ZONE} --flavor ${ROKS_FLAVOR} --hardware shared --workers ${ROKS_WORKERS} --entitlement cloud_pak" | tee ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ibm-roks-createCluster.log
     ibmcloud oc cluster create ${ROKS_PROVIDER} \
      --name ${CLUSTER_NAME} \
      --version ${OCP_BASE_VERSION}_openshift \
      --zone ${ROKS_ZONE} \
      --flavor ${ROKS_FLAVOR} \
      --hardware shared \
      --workers ${ROKS_WORKERS} \
      --entitlement cloud_pak | tee -a ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ibm-roks-createCluster.log
  else
     echo "ibmcloud oc cluster create ${ROKS_PROVIDER} --name ${CLUSTER_NAME} --version ${OCP_BASE_VERSION}_openshift --zone ${ROKS_ZONE} --flavor ${ROKS_FLAVOR} --hardware shared --workers ${ROKS_WORKERS}   --public-vlan ${ROKS_PUBLIC_LAN} --private-vlan ${ROKS_PRIVATE_LAN} --entitlement cloud_pak" | tee ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ibm-roks-createCluster.log
     ibmcloud oc cluster create ${ROKS_PROVIDER} \
      --name ${CLUSTER_NAME} \
      --version ${OCP_BASE_VERSION}_openshift \
      --zone ${ROKS_ZONE} \
      --flavor ${ROKS_FLAVOR} \
      --hardware shared \
      --workers ${ROKS_WORKERS} \
      --public-vlan ${ROKS_PUBLIC_LAN} \
      --private-vlan ${ROKS_PRIVATE_LAN} \
      --entitlement cloud_pak | tee -a ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ibm-roks-createCluster.log
  fi
}

validateIBMVLANPrivatePublic()
{

  if [ -n ${ROKS_ZONE} ]; then
      ibmcloud ks vlan ls --zone ${ROKS_ZONE} &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ibm-vlan.log
      if [ -z ${ROKS_PRIVATE_LAN} ]; then
            ROKS_PRIVATE_LAN=`cat ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ibm-vlan.log | grep private | head -n 1 | awk '{print $1}'`
            if [ -z ${ROKS_PRIVATE_LAN} ]; then
                IBM_VLAN=false
                echo "${BLUE_TEXT}INFO ${RESET_TEXT} Private VLAN ID not found. Creating for you"
            else
                IBM_VLAN=true
                echo "${BLUE_TEXT}PASSED ${RESET_TEXT} Found Private VLAN ID ${ROKS_PRIVATE_LAN}"
            fi
      else
            local FOUND_ROKS_PRIVATE_LAN=`cat ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ibm-vlan.log | grep private | grep -c ${ROKS_PRIVATE_LAN}`
            if [  ${FOUND_ROKS_PRIVATE_LAN} -eq 1 ]; then
                  IBM_VLAN=true
                  echo "${BLUE_TEXT}PASSED ${RESET_TEXT} Using Private VLAN ID ${ROKS_PRIVATE_LAN}"
            else
                  IBM_VLAN=false
                  echo "${BLUE_TEXT}INFO ${RESET_TEXT} Private VLAN ID not found. Creating for you"
            fi
      fi
      if [ -z ${ROKS_PUBLIC_LAN} ]; then
            ROKS_PUBLIC_LAN=`cat ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ibm-vlan.log | grep public  | head -n 1 | awk '{print $1}'`
            if [ -z ${ROKS_PUBLIC_LAN} ]; then
              IBM_VLAN=false
              echo "${BLUE_TEXT}INFO ${RESET_TEXT} Public VLAN ID not found. Creating for you"
            else
              IBM_VLAN=true
              echo "${BLUE_TEXT}PASSED ${RESET_TEXT} Found Public VLAN ID ${ROKS_PUBLIC_LAN}"
            fi
      else
          local FOUND_ROKS_PUBLIC_LAN=`cat ${LOG_DIR}/${PRODUCT_SHORT_NAME}/ibm-vlan.log | grep public | grep -c ${ROKS_PUBLIC_LAN}`
          if [  ${FOUND_ROKS_PUBLIC_LAN} -eq 1 ]; then
                IBM_VLAN=true
                echo "${BLUE_TEXT}PASSED ${RESET_TEXT} Using Public VLAN ID ${ROKS_PUBLIC_LAN}"
          else
                IBM_VLAN=false
                echo "${BLUE_TEXT}INFO ${RESET_TEXT}  Public VLAN ID not found. Creating for you"
          fi
      fi
  else
      IBM_VLAN=false
  fi


}
validateIBMROKSFlavor()
{
  testIBMCloudLogin
  if [ -z ${ROKS_PROVIDER} ]; then
    SHOULD_EXIT=1
    echo "${RED_TEXT}FAILED ${RESET_TEXT} Unable to validate Zone, missing Provider type"
  else
      local FOUND_ROKS_FLAVOR=`ibmcloud ks flavors --zone ${ROKS_ZONE} --provider  ${ROKS_PROVIDER} 2> /dev/null | grep -c "${ROKS_FLAVOR} "`
      if [  ${FOUND_ROKS_FLAVOR} -eq 1 ]; then
        echo "${BLUE_TEXT}PASSED ${RESET_TEXT} Valid ROKS Flavor ${ROKS_FLAVOR}"
      else
        SHOULD_EXIT=1
        echo "${RED_TEXT}FAILED ${RESET_TEXT} Invalid ROKS Flavor ${ROKS_FLAVOR}"
      fi
  fi

}
ibmCloudROKSClusterDoesNotExist()
{
  testIBMCloudLogin
  CLUSTER_STAUTS=`ibmcloud oc cluster ls 2> /dev/null | grep -c "${CLUSTER_NAME} "`
  if [ "${CLUSTER_STAUTS}" == "0" ]; then
      echo "${BLUE_TEXT}PASSED ${RESET_TEXT} ROKS Cluster does not exist - ${CLUSTER_NAME}"
  else
    SHOULD_EXIT=1
    echo "${RED_TEXT}FAILED ${RESET_TEXT} ROKS Cluster already exist - ${CLUSTER_NAME}"
  fi
}
validROKSZone()
{
  testIBMCloudLogin
  if [ -z ${ROKS_PROVIDER} ]; then
    SHOULD_EXIT=1
    echo "${RED_TEXT}FAILED ${RESET_TEXT} Unable to validate Zone, missing Provider type"
  else
      local FOUND_ZONE=`ibmcloud ks zone ls --provider ${ROKS_PROVIDER} 2> /dev/null | grep -c ${ROKS_ZONE}`
      if [ "${FOUND_ZONE}" == "1" ]; then
        echo "${BLUE_TEXT}PASSED ${RESET_TEXT} Valid ROKS Zone - ${ROKS_ZONE}"
      else
        SHOULD_EXIT=1
        echo "${RED_TEXT}FAILED ${RESET_TEXT} Invalid ROKS Zone - ${ROKS_ZONE}"
      fi
   fi
}
validROKSProviders()
{
  case ${ROKS_PROVIDER} in
  classic|satellite)
        echo "${BLUE_TEXT}PASSED ${RESET_TEXT} Valid ROKS Provider - ${ROKS_PROVIDER}"
        ;;
    *)
        SHOULD_EXIT=1
        echo "${RED_TEXT}FAILED ${RESET_TEXT} Invalid ROKS Provider - ${ROKS_PROVIDER}"
  esac
}

waitForROKSClusterDeleted()
{
  testIBMCloudLogin
  echo ""
  local CLUSTER_PRESENT=`ibmcloud ks cluster ls 2> /dev/null | grep -c "${CLUSTER_NAME} "`
  while [ "${CLUSTER_PRESENT}" == "1" ]; do
      blinkWaitMessage "Waiting for cluster to be deleted" 60
      CLUSTER_PRESENT=`ibmcloud ks cluster ls 2> /dev/null | grep -c "${CLUSTER_NAME} "`
  done
  echo "${BLUE_TEXT}COMPLETE ${RESET_TEXT} ROKS Cluster has been deleted - ${CLUSTER_NAME}"
}
waitForROKSClusterReady()
{
  testIBMCloudLogin
  echo ""
  local CLUSTER_STATE=`ibmcloud ks cluster ls 2> /dev/null | grep "${CLUSTER_NAME} " | grep -v Name | awk '{print $3}' `
  while [ "${CLUSTER_STATE}" != "normal" ]; do
      blinkWaitMessage "Waiting for cluster to be ready" 60
      testIBMCloudLogin
      CLUSTER_STATE=`ibmcloud ks cluster ls 2> /dev/null | grep "${CLUSTER_NAME} " | grep -v Name | awk '{print $3}' `
  done
  echo "${BLUE_TEXT}COMPLETE ${RESET_TEXT} ROKS Cluster ready"
  ibmcloud ks cluster ls 2> /dev/null | grep " ${CLUSTER_NAME} " | grep -v Name

}
validROKSOCPVersion()
{
  testIBMCloudLogin
  local VALID_ROKS_VERSION=`ibmcloud ks versions | grep -c ${OCP_RELEASE}`
  if [ ${VALID_ROKS_VERSION} -eq 1 ]; then
      echo "${BLUE_TEXT}PASSED ${RESET_TEXT} Valid ROKS OpenShift Version ${OCP_RELEASE}"
  else
    SHOULD_EXIT=1
    echo "${RED_TEXT}FAILED ${RESET_TEXT} Invalid ROKS OpenShift Version - ${OCP_RELEASE}"
    echo "Please update OCP_RELEASE to one of the valid versions below and then execute the script again!!!!"
    echo "Valid Versions of ROKS OpenShift Versions:"
    ibmcloud ks versions | grep openshift
  fi
}
validROKSHardwareType()
{
  if [ -z ${ROKS_HARDWARE_TYPE}  ]; then
      ROKS_HARDWARE_TYPE=shared
      echo "${BLUE_TEXT}PASSED ${RESET_TEXT} Valid ROKS Hardware Type - ${ROKS_HARDWARE_TYPE}"
  else
    case ${ROKS_HARDWARE_TYPE} in
    dedicated|shared)
          echo "${BLUE_TEXT}PASSED ${RESET_TEXT} Valid ROKS Hardware Type - ${ROKS_HARDWARE_TYPE}"
          ;;
      *)
          SHOULD_EXIT=1
          echo "${RED_TEXT}FAILED ${RESET_TEXT} Invalid ROKS Provider - ROKS Hardware Type - ${ROKS_HARDWARE_TYPE} (Should be dedicated or shared)"
    esac
  fi
}

validROKSNumberOfWorkers()
{
      if [  ${ROKS_WORKERS}  -ge 2 ]; then
         echo "${BLUE_TEXT}PASSED ${RESET_TEXT} Valid number of Workers - ${ROKS_WORKERS}"
      else
         SHOULD_EXIT=1
         echo "${RED_TEXT}FAILED ${RESET_TEXT} Invalid number of Workers - ${ROKS_WORKERS} (Must be greater then equal to 2)"
      fi
}
