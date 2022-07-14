#!/bin/bash
############################################################
#Author           : Kyle Dawson
#Author email     : Kyle.Dawson@us.ibm.com
#Author email     : gerry.baird@uk.ibm.com
#Original Date    : 2022-05-10
#Initial Version  : v2022-05-23
############################################################
cp4baOPSPreCheck()
{
  printHeaderMessage "PreCheck OPS"
  #docker present
  #Access to cluster
  #git
}
cp4baOPSPostgres()
{
  printHeaderMessage "OPS Postgres (LOG -> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/cp4ba-ops-postgres.log)"
  CP4BA_OPS_POSTGRES_DONE=0
  oc apply -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/ops/serviceaccounts/postgres.yaml
  oc adm policy add-scc-to-user anyuid -z postgres 2>/dev/null
  echo "Start Postgres deployment " &>  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/cp4ba-ops-postgres.log
  local FOUND_POSTGRES_SECRET=`oc get secret postgres-secret -n ${CP4BA_OPS_ML_NAMESPACE} 2>/dev/null | grep -c postgres-secret`
  if [  ${FOUND_POSTGRES_SECRET} -eq 0 ]; then
    CP4BA_OPS_POSTGRES_PASSWORD=`date +%s | sha256sum | base64 | head -c 16 ; echo`
    oc create secret generic postgres-secret \
     --from-literal postgres-password=$CP4BA_OPS_POSTGRES_PASSWORD \
     --from-literal postgres-user=pgadmin \
     --from-literal pguser=pgadmin \
     --from-literal pgbench-password=$CP4BA_OPS_POSTGRES_PASSWORD \
     -n ${CP4BA_OPS_ML_NAMESPACE}
  else
    echo "Using existing Postgres Secret password "
    CP4BA_OPS_POSTGRES_PASSWORD=`oc get secret postgres-secret -n ${CP4BA_OPS_ML_NAMESPACE}  --template='{{.data}}' |awk '{print $3}' | sed "s/postgres-password://g" | base64 -d`
  fi

  find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/ops -type f | xargs sed -i'' "s/@CP4BA_OPS_POSTGRES_PASSWORD@/$CP4BA_OPS_POSTGRES_PASSWORD/g"
  oc apply -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/ops/postgres/postgres-pvc.yaml
  local OPS_POSTGRES_PVC_READY=`oc get pvc postgres -n ${CP4BA_OPS_ML_NAMESPACE} | grep -c Bound`
  let  LOOP_COUNT=1
  while [ "${OPS_POSTGRES_PVC_READY}" != "1"  ]
  do
        blinkWaitMessage "Waiting for Postgres PVC (Wait up to 10 Min)" 10
        if [ $LOOP_COUNT -ge 60 ] ;then
            echo "${RED_TEXT}FAILED ${RESET_TEXT}Postgres PVC did not Bond"
            oc get pvc postgres -n ${CP4BA_OPS_ML_NAMESPACE}
            break
            echo ""
        fi
        OPS_POSTGRES_PVC_READY=`oc get pvc postgres -n ads-ml-service | grep -c Bound`
        let LOOP_COUNT=LOOP_COUNT+1
  done
  if [ ${OPS_POSTGRES_PVC_READY} -eq 1 ]; then
    echo "${BLUE_TEXT}COMPLETE ${RESET_TEXT} OPS Postgres PVC Bound"
    oc apply -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/ops/postgres/postgres-deployment.yaml
    let  LOOP_COUNT=1
    local CP4BA_OPS_POSTGRES_POD_READY=`oc get pod -n ${CP4BA_OPS_ML_NAMESPACE}| grep postgres | grep Running | grep -c "1/1"`
    while [ "${CP4BA_OPS_POSTGRES_POD_READY}" != "1" ]
    do
        blinkWaitMessage "Waiting for Postgres pod to be ready (Wait up to 10 Min)" 10
        if [ $LOOP_COUNT -ge 60 ] ;then
            echo "${RED_TEXT}FAILED ${RESET_TEXT} OPS Postgres pod did not start"
            oc get pod -n ${CP4BA_OPS_ML_NAMESPACE}| grep postgres
            break
        fi
        CP4BA_OPS_POSTGRES_POD_READY=`oc get pod -n ${CP4BA_OPS_ML_NAMESPACE}| grep postgres | grep Running | grep -c "1/1"`
        let LOOP_COUNT=LOOP_COUNT+1
    done

    if [ ${CP4BA_OPS_POSTGRES_POD_READY} -eq 1 ]; then
        echo "${BLUE_TEXT}COMPLETE ${RESET_TEXT} OPS Postgres pod started"
        POSTGRES_FAILED=0
        echo ""
        POSTGRES=$(oc get pod -n ${CP4BA_OPS_ML_NAMESPACE} -l app=postgres -oname | sed s,pod/,,g)
        local POSTGRES_READY=`oc logs  $POSTGRES -n ${CP4BA_OPS_ML_NAMESPACE} | grep -c "database system is ready to accept connections"`
        local POSTGRES_READY_SKIP_INIT=`oc logs  $POSTGRES -n ${CP4BA_OPS_ML_NAMESPACE} | grep -c "Skipping initialization"`
        let  LOOP_COUNT=1
        while [ ${POSTGRES_READY} -le 1 ] && [ ${POSTGRES_READY_SKIP_INIT} -ne 1 ] ; do
            blinkWaitMessage "Waiting for Postgres database to be ready (Wait up to 10 Min)" 10
            local POSTGRES_READY=`oc logs  $POSTGRES -n ${CP4BA_OPS_ML_NAMESPACE} | grep -c "database system is ready to accept connections"`
            local POSTGRES_READY_SKIP_INIT=`oc logs  $POSTGRES -n ${CP4BA_OPS_ML_NAMESPACE} | grep -c "Skipping initialization"`
            if [ $LOOP_COUNT -ge 60 ] ;then
                echo "${RED_TEXT}FAILED ${RESET_TEXT} OPS Postgres database did not start"
                oc logs  $POSTGRES -n ${CP4BA_OPS_ML_NAMESPACE}
                echo ""
                echo ""
                POSTGRES_FAILED=1
                break
            fi
            let LOOP_COUNT=LOOP_COUNT+1
        done
        echo ""
        if [ ${POSTGRES_FAILED} -eq 0 ]; then
            echo "${BLUE_TEXT}COMPLETE ${RESET_TEXT} OPS Postgres database ready"
            echo "Creating Postgres Database"
            oc project ${CP4BA_OPS_ML_NAMESPACE} &> /dev/null
            echo "Running oc cp ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/ops/createMlServingDatabase.sh ${CP4BA_OPS_ML_NAMESPACE}/${POSTGRES}:/tmp/" |  tee -a  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/cp4ba-ops-postgres.log
            oc cp ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/ops/createMlServingDatabase.sh  ${CP4BA_OPS_ML_NAMESPACE}/${POSTGRES}:/tmp/
            echo "Running oc exec $POSTGRES -- bash -c chmod +x /tmp/createMlServingDatabase.sh" | tee -a ${LOG_DIR}/${PRODUCT_SHORT_NAME}/cp4ba-ops-postgres.log
            oc exec $POSTGRES -- bash -c "chmod +x /tmp/createMlServingDatabase.sh" &>> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/cp4ba-ops-postgres.log
            echo "Running oc exec $POSTGRES -- bash -c /tmp/createMlServingDatabase.sh" | tee -a  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/cp4ba-ops-postgres.log
            oc exec $POSTGRES -- bash -c "/tmp/createMlServingDatabase.sh" 2>> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/cp4ba-ops-postgres.log
            CP4BA_OPS_POSTGRES_DONE=1
        fi
    else
          echo "${RED_TEXT}FAILED ${RESET_TEXT} OPS Postgres pod did not start"
    fi
  fi
}
cp4baOPSDeploy()
{
  printHeaderMessage "OPS Deploy (LOG -> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/cp4ba-ops-deploy.log)"
  rm -fR ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/ops/tmp 2>/dev/null
  mkdir -p ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/ops/tmp
  cd ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/ops/tmp
  echo "wget https://github.com/IBM/open-prediction-service-hub/archive/refs/tags/${CP4BA_OPS_VERSION}.zip"
  wget https://github.com/IBM/open-prediction-service-hub/archive/refs/tags/${CP4BA_OPS_VERSION}.zip &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/cp4ba-ops-deploy.log
  unzip ${CP4BA_OPS_VERSION}.zip &>> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/cp4ba-ops-deploy.log
  cd open-prediction-service-hub-${CP4BA_OPS_VERSION}/ops-implementations/ads-ml-service
  echo "${TEMP_DIR}/${PRODUCT_SHORT_NAME}/ops/tmp/open-prediction-service-hub-${CP4BA_OPS_VERSION}/ops-implementations/ads-ml-service"

  echo "podman build -t ads-ml-service . (This can take up to 5 min)"
  podman build -t ads-ml-service .   &>> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/cp4ba-ops-deploy.log

  oc project openshift-image-registry 1>/dev/null
  oc create route reencrypt --service=image-registry 2>> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/cp4ba-ops-deploy.log
  imageRegistryRoute=$(oc get route image-registry -n openshift-image-registry -o 'jsonpath={.spec.host}')

  podman login $imageRegistryRoute -u $(oc whoami) -p $(oc whoami -t) --tls-verify=false 1>/dev/null

  echo "podman tag ads-ml-service:latest $imageRegistryRoute/ads-ml-service/ads-ml-service:latest"
  podman tag ads-ml-service:latest $imageRegistryRoute/ads-ml-service/ads-ml-service:latest &>> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/cp4ba-ops-deploy.log

  echo "podman push $imageRegistryRoute/ads-ml-service/ads-ml-service:latest"
  podman push $imageRegistryRoute/ads-ml-service/ads-ml-service:latest --tls-verify=false &>> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/cp4ba-ops-deploy.log

  echo "podman rmi ads-ml-service:latest -f"
  podman rmi ads-ml-service:latest -f &>> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/cp4ba-ops-deploy.log

  echo ""
  echo "Deploying open-prediction service resources"
  oc project ${CP4BA_OPS_ML_NAMESPACE} &>> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/cp4ba-ops-deploy.log
  oc apply -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/ops/configMap.yaml
  oc apply -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/ops/adsMlServiceDeployment.yaml
  oc apply -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/ops/service.yaml
  oc expose service ads-ml-service-service 2>/dev/null
  oc apply -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/ops/networkpolicy.yaml
  cd ${TEMP_DIR}/${PRODUCT_SHORT_NAME}
  rm -fR ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/ops/tmp 2>/dev/null
}
cp4baOPSInstall()
{
  if [ "${CP4BA_ENABLE_SERVICE_OPS}" == "true" ] ;then
    printHeaderMessage "OPS Install"
    oc create namespace ${CP4BA_OPS_ML_NAMESPACE} 2>/dev/null
    applyNameSpaceLabels ${CP4BA_OPS_ML_NAMESPACE} "Open Prediction Service HUB"
    cp4baOPSPostgres
    if [  "${CP4BA_OPS_POSTGRES_DONE}" ==  "1" ]; then
      cp4baOPSDeploy
      cp4baOPSDisplaySwaggerURL
    fi
  fi
}

cp4baOPSImageCertTrust()
{
    printHeaderMessage "OPS Update image-registry Trust CA Cert (LOG -> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/update-image-registry-ca-certificates.log)"
    local OCP_AUTH_POD=`oc get po -n openshift-authentication | grep -v NAME | head -1 | awk '{print $1}'`
    oc rsh -n openshift-authentication ${OCP_AUTH_POD} cat /run/secrets/kubernetes.io/serviceaccount/ca.crt > ${LOCAL_CA_CERT_FOLDER}/ingress-ca.cr
    if [ ${IS_UBUNTU}  -eq 1 ]; then
        update-ca-certificates 1>> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/update-image-registry-ca-certificates.log
        echo "OpenShift Ingress Cert added to local OS trust store  - ${LOCAL_CA_CERT_FOLDER}/ingress-ca.cr"
    fi
    if [ ${IS_RH} -eq 1 ]; then
        update-ca-trust extract 1>> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/update-image-registry-ca-certificates.log
        echo "OpenShift Ingress Cert added to local OS trust store  - ${LOCAL_CA_CERT_FOLDER}/ingress-ca.cr"
    fi
}
cp4baOPSDisplaySwaggerURL()
{
  printHeaderMessage "OPS Swagger URL"
  ADS_ML_HOST=`oc get route -n ${CP4BA_OPS_ML_NAMESPACE} | grep -v NAME | awk '{print $2}'`
  echo "OPS Swagger URL                            : ${BLUE_TEXT}http://${ADS_ML_HOST}${RESET_TEXT}"


}
