#openssl req -newkey rsa:2048 -nodes -keyout tls.key -subj "/CN=localhost" -x509 -days 3650 -out tls.crt

# Download the MQ Client
#wget https://ak-delivery04-mul.dhe.ibm.com/sdfdl/v2/sar/CM/WS/0a3kg/0/Xa.2/Xb.jusyLTSp44S0BsL1B-yHya5CV2_SpQXCB3CK1e233Y0-QD5wJhiF0LXdbm8/Xc.CM/WS/0a3kg/0/9.2.4.0-IBM-MQC-Redist-LinuxX64.tar.gz/Xd./Xf.LPR.D1VK/Xg.11564195/Xi.habanero/XY.habanero/XZ.kzDX10u5by39hWM-E-BklVe5jU0vLBkc/9.2.4.0-IBM-MQC-Redist-LinuxX64.tar.gz
# All versions of the client can be downloaded here https://public.dhe.ibm.com/ibmdl/export/pub/software/websphere/messaging/mqdev/redist/
# You can also find the MQ Client on Fix Central, but you will need to login to get the downloads.

############################################################
#Setup Variables
############################################################
DIR="$( cd "$( dirname "$0" )" && pwd )"
PRODUCT_SHORT_NAME=cp4i-demo
source ${DIR}/../../../env/${1}-env.sh &> /dev/null
source ${DIR}/../../../env.sh
source ${DIR}/../../env.sh
source ${DIR}/env.sh
if [ ${SHOULD_EXIT} == 1 ] ;then
    echo ""
    echo "${X_MARK}  ${RED_TEXT} *** PRE-CHECK FAILED ********  Exiting Script!!!!!!!${RESET_TEXT}"
    echo ""
    exit 1
fi
source ${DIR}/../../../functions.sh
source ${DIR}/../../functions.sh

prepareCCDTFile()
{
  mkdir -p ${TEMP_DIR}/${PRODUCT_SHORT_NAME}
  cd ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/
  cp -fR ${DIR}/templates/CCDT.JSON ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/
  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME} -type f | xargs sed -i'' "s/@HOSTNAME@/$ROUTE_HOSTNAME/g"
}

if [ ${SHOULD_EXIT} == 1 ] ;then
    echo ""
    echo ""
    echo "${X_MARK}  ${RED_TEXT} *** PRE-CHECK FAILED ********  Exiting Script!!!!!!!${RESET_TEXT}"
    echo ""
    echo ""
    exit 1
else
    # Download the MQ Client.
    printHeaderMessage "Download the MQ Client for Linux"
    cd ${DIR}

    wget https://public.dhe.ibm.com/ibmdl/export/pub/software/websphere/messaging/mqdev/redist/9.2.4.0-IBM-MQC-Redist-LinuxX64.tar.gz

    echo "${CHECK_MARK} ***** Download Complete ****** "
    echo "  ***** Location of the download: ${DIR}"

    printHeaderMessage "Expanding the MQ Client tar file"
    tar -xvf 9.2.4.0-IBM-MQC-Redist-LinuxX64.tar.gz 1> /dev/null
    echo "${CHECK_MARK} ***** Expanding Complete ****** "
    echo "  ***** Location of the expanded MQ Client: ${DIR}"

    printHeaderMessage "Create KEY STORE Database"
    # Create the key store database
    ${DIR}/bin/runmqakm -keydb -create -db clientkey.kdb -pw password -type cms -stash
    sleep 10
    echo "${CHECK_MARK} ***** KEY STORE Database Created ******"
    echo "  ***** Key Store database name: clientkey.kdb"
    echo "  ***** Key Store database password: password"
    echo "  ***** Location of the newly created Key Store database: ${DIR}"

    printHeaderMessage "Add cert to KEY STORE Database"
    # Add the cert to the key store database.
    ${DIR}/bin/runmqakm -cert -add -db clientkey.kdb -label mqservercert -file tls.crt -format ascii -stashed
    sleep 10
    echo "${CHECK_MARK} ***** Cert (tls.crt) has been added to the KEY STORE Database *****"
    echo "  ***** Cert is located in the ${DIR} directory"

    # Connect to OCP
    logIntoCluster
    validateOCPAccess
    if [ ${SHOULD_EXIT} == 1 ] ;then
        echo ""
        echo ""
        echo "${X_MARK}  ${RED_TEXT}Unable to login. If this is ROKS please copy the oc login command from your cluster and log in. Exiting Script!!!!!!!${RESET_TEXT}"
        echo ""
        echo ""
        exit 1
    else
      # We have access to the cluster!  Need to execute the OC commands to deploy the demo.
      echo "Switch to project:  ${CP4I_NAMESPACE}"
      oc project ${CP4I_NAMESPACE}

      # Deploy the OCP artifacts (Secret, Configmap, Queue Manager)
      printHeaderMessage "Create a Secret with the tls.key and tls.crt"
      oc create secret tls example-tls-secret --key="tls.key" --cert="tls.crt" -n ${CP4I_NAMESPACE}
      sleep 10
      echo "${CHECK_MARK} ***** Secret (example-tls-secret) containing the tls.key and tls.cert has been created ******"

      printHeaderMessage "Create a Configmap with MQSC QM Definitions "
      oc apply -f ${DIR}/templates/tls-configmap.yaml -n ${CP4I_NAMESPACE}
      sleep 10
      echo "${CHECK_MARK} ***** Config map has been created ******"

      printHeaderMessage "Create a Route with TLS Passthrough Security uses Secure MQ Channel"
      oc apply -f ${DIR}/templates/tls-route.yaml -n ${CP4I_NAMESPACE}
      sleep 10
      echo "${CHECK_MARK} ***** OpenShift Route has been  created ******"

      printHeaderMessage "Create Queue Manager using Configmap that has MQSC Definitions"
      oc apply -f ${DIR}/templates/secureqm.yaml -n ${CP4I_NAMESPACE}
      sleep 10
      echo "${CHECK_MARK} ***** New Queue Manager with MQ Definitions from Configmap has been deployed. ******"

      printHeaderMessage "Setup MQ Demo Client on this Bastion (This Machine)"
      oc apply -f ${DIR}/templates/secureqm.yaml -n ${CP4I_NAMESPACE}
      sleep 10
      echo "${CHECK_MARK} ***** New Queue Manager with MQ Definitions from Configmap has been deployed. ******"

      ROUTE_HOSTNAME=`oc get routes secureqm-ibm-mq-qm -n ${CP4I_NAMESPACE} -o jsonpath='{.spec.host}' 2> /dev/null`

      if [ -z ${ROUTE_HOSTNAME} ]; then
        echo "${X_MARK}  Unable to find the Route Host Name!"
        echo " "
        echo " Use this command to find the host name: "
        echo "   oc get routes secureqm-ibm-mq-qm -n ${CP4I_NAMESPACE} -o jsonpath='{.spec.host}'"
        echo "  -- Manually update your CCDT.JSON file with the proper host name!"
      else
        echo "${CHECK_MARK} ***** Your route hoste name was located:  ${ROUTE_HOSTNAME}"
        echo " "
        echo -e "  *****  Updating your CCDT.JSON file with the proper hostname. "
        prepareCCDTFile
        echo " "
        echo "${CHECK_MARK}  Your CCDT File has been updated: ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/CCDT.JSON"

        echo " "
        printHeaderMessage "Testing Secure MQ demo on this Bastion - Put & Get Messages"

        echo "  *****  NOTE: You must first set these two environment variables."
        echo "  *****  Execute these two commands to set your environment variables"
        echo " "
        echo "           export MQSSLKEYR='${DIR}/clientkey'"
        echo "           export MQCCDTURL='${TEMP_DIR}/${PRODUCT_SHORT_NAME}/CCDT.JSON'"
        echo " "
        echo "  ******  Put & Get messages using the following commands:"
        echo "           ${DIR}/samp/bin/amqsputc EXAMPLE.QUEUE SECUREQM"
        echo "           ${DIR}/samp/bin/amqsgetc EXAMPLE.QUEUE SECUREQM"
      fi

      echo " "

      printHeaderMessage "Demonstrate connectivity from a client machine that is external from the OpenShift Cluster"

      echo  "The demo assets have been deployed. Please refer to the PDF in the client side artifacts download (zip file)."
      echo ""
      echo "  Download the client side artifacts here: http://get.daffy-installer.com:1887/cp4idownload/securemqdemo/client-side-artifacts.zip"
      echo " "
      echo "  Client side steps to connect to the secure queue manager using TLS security are as follows:"
      echo "    (1) Install MQ Client on the client machine"
      echo "        Download MQ Client files here: https://public.dhe.ibm.com/ibmdl/export/pub/software/websphere/messaging/mqdev/redist/"
      echo "        Note: The MQ Linux client has been installed on this machine in the following dir: /data/daffy/cp4i/demos/secureqm/ "
      echo " "
      echo "    (2) Download the client side artifacts zip file and expand it on the client machine you wish to connect from. "
      echo "        (2.1)Download the client side artifacts here: http://get.daffy-installer.com:1887/cp4idownload/securemqdemo/client-side-artifacts.zip"
      echo "        (2.2) Locate the Host-Name using the oc commands (see pdf for instructions)"
      echo "        (2.3) Modify the CCDT.JSON file that was downloaded in the client side artifacts. (Add the Host-Name)"
      echo "        (2.4) Export the MQ Client environment variables"
      echo " "
      echo "   Your now ready to run a test using the amqsputc / amqsgetc commands, which are part of the MQ Client."

      # NEED to install MQ client
      # Find Host-Name using OC command.
      # NEED TO MODIFY THE CCDT.JSON FILE - ADD HOST Namespace
      # Copy template CCDT.JSON to client-side-artifacts dir.
      # Modify (REPLACE) @HOSTNAME@
      # find ${DIR}/client-side-artifacts -type f | xargs sed -i'' "s/@HOSTNAME@/$HOST-NAME-VARIABLE/g"
    fi
  fi
