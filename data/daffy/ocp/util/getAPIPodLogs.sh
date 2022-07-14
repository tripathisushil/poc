#!/bin/bash
############################################################
#Author           : Kyle Dawson
#Author email     : Kyle.Dawson@us.ibm.com
#Original Date    : 2021-08-15
#Initial Version  : v2021-12-01
############################################################
echo "Tailing apiserver pod logs. --- They will be created in current directory with pod name."

POD_OPERATOR=`oc get pods -n openshift-apiserver-operator | grep -v NAME | grep openshift-apiserver-operator | awk '{print $1}'`
if [[ -z "${POD_OPERATOR}" ]] ;then
    echo "Unable to find pod for openshift-apiserver-operator"
else
        oc logs -f ${POD_OPERATOR} -n openshift-apiserver-operator > ${POD_OPERATOR}.log &
fi

POD_LIST=`oc get pods -n openshift-apiserver | grep -v NAME | grep apiserver | awk '{print $1}'`
if [[ -z "${POD_LIST}" ]] ;then
    echo "Unable to find pods for openshift-apiserver"
else
        for POD_NAME in ${POD_LIST}
        do
                oc logs ${POD_NAME} openshift-apiserver -n openshift-apiserver > ${POD_NAME}.log &
        done
fi
