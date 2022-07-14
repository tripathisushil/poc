############################################################
#Author           : Kyle Dawson
#Author email     : Kyle.Dawson@us.ibm.com
#Original Date    : 2021-12-16
############################################################
FIXPACK=${1}
echo "${GREEN_TEXT}Fixing Label and taint on storage nodes${RESET_TEXT}"
mkdir -p ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/fixpaks/${FIXPACK}
cp -fR ${DIR}/../fixpaks/${PRODUCT_SHORT_NAME}/${FIXPACK} ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/fixpaks/

case ${OCP_INSTALL_TYPE} in
   kvm-upi)
      find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/fixpaks/${FIXPACK} -type f | xargs sed -i'' "s|@IBM_OPENSHIFT_LOCAL_STORAGE_DEVICE_PATH@|$IBM_OPENSHIFT_LOCAL_STORAGE_DEVICE_PATH_KVM|g"
      find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/fixpaks/${FIXPACK} -type f | xargs sed -i'' "s|@IBM_OPENSHIFT_LOCAL_BULK_STORAGE_DEVICE_PATH@|$IBM_OPENSHIFT_LOCAL_BULK_STORAGE_DEVICE_PATH_KVM|g"
      ;;&
   vsphere-upi)
      find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/fixpaks/${FIXPACK} -type f | xargs sed -i'' "s|@IBM_OPENSHIFT_LOCAL_STORAGE_DEVICE_PATH@|$IBM_OPENSHIFT_LOCAL_STORAGE_DEVICE_PATH_VSPHERE|g"
      find ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/fixpaks/${FIXPACK} -type f | xargs sed -i'' "s|@IBM_OPENSHIFT_LOCAL_BULK_STORAGE_DEVICE_PATH@|$IBM_OPENSHIFT_LOCAL_BULK_STORAGE_DEVICE_PATH_VSPHERE|g"
      ;;&
    *-upi)
      oc apply -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/fixpaks/${FIXPACK}/local.yaml
      oc apply -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/fixpaks/${FIXPACK}/local-bulk.yaml
      ;;
esac


NODE_LIST=`oc get nodes | grep worker | awk '{print $1}'`
case ${OCP_INSTALL_TYPE} in
    aws-ipi|gcp-ipi|azure-ipi|vsphere-ipi)
        local workerLoop=1
        for WORKER_NODE_NAME in $NODE_LIST
        do
          oc label nodes ${WORKER_NODE_NAME} cluster.ocs.openshift.io/openshift-storage=""  --overwrite=true
          oc label nodes ${WORKER_NODE_NAME} topology.rook.io/rack=rack${workerLoop} --overwrite=true
          oc label nodes ${WORKER_NODE_NAME} node-role.kubernetes.io/infra="" --overwrite=true
          oc adm taint nodes ${WORKER_NODE_NAME} node.ocs.openshift.io/storage=true:NoSchedule  --overwrite=true
          oc label nodes ${WORKER_NODE_NAME} node-role.kubernetes.io/worker="" --overwrite=true
          let workerLoop=workerLoop+1
          if [ $workerLoop -gt 3 ]; then
            break
          fi
        done
        ;;
    kvm-upi|vsphere-upi)
        local workerLoop=1
        for WORKER_NODE_NAME in $NODE_LIST
        do
          case ${WORKER_NODE_NAME} in
            *worker4*|*worker5*|*worker6*)
                oc label nodes ${WORKER_NODE_NAME} cluster.ocs.openshift.io/openshift-storage=""  --overwrite=true
                oc label nodes ${WORKER_NODE_NAME} topology.rook.io/rack=rack${workerLoop} --overwrite=true
                oc label nodes ${WORKER_NODE_NAME} node-role.kubernetes.io/infra="" --overwrite=true
                oc adm taint nodes ${WORKER_NODE_NAME} node.ocs.openshift.io/storage=true:NoSchedule  --overwrite=true
                oc label nodes ${WORKER_NODE_NAME} node-role.kubernetes.io/worker="" --overwrite=true
                let workerLoop=workerLoop+1
                  ;;
          esac
        done
        ;;
esac
restartCrashLoopBackOffPods ibm-common-services
restartImagePullBackOffPods ibm-common-services
echo ""
