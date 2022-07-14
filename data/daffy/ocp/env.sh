#!/bin/bash
############################################################
#Author           : Kyle Dawson
#Author email     : Kyle.Dawson@us.ibm.com
#Original Date    : 2021-12-11
#Initial Version  : v2022-01-18
############################################################
#Standard values but can be overriddn at each lower level
##########################################################
if [ "${OPENSHIFT_INSTALLER_COMMAND_DEBUG_ENABLED}" == "true" ]; then
    OPENSHIFT_INSTALLER_ARGS="--log-level=debug"
fi

#ROKS Defaults
#######################
ROKS_ZONE=dal13
ROKS_PROVIDER=classic
ROKS_HARDWARE_TYPE=shared

#NFS Defaults
#######################
OCP_NFS_IMAGE="k8s.gcr.io/sig-storage/nfs-subdir-external-provisioner:v4.0.2"
OCP_NFS_ENV_PROVISIONER_NAME="k8s-sigs.io/nfs-subdir-external-provisioner"
