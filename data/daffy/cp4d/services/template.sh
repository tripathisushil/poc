############################################################
#Author           : Kyle Dawson
#Author email     : Kyle.Dawson@us.ibm.com
#Original Date    : ????Put Date Created Here?????
#Initial Version  : ????Put current version here?????
############################################################
#Setup Variables
############################################################
#Put any URL for doc of how we found out to build the service
#https://www.ibm.com/docs/en/cloud-paks/cp-data/4.0
#https://www.ibm.com/docs/en/cloud-paks/cp-data/4.0?topic=tasks-creating-operator-subscriptions
#https://www.ibm.com/docs/en/cloud-paks/cp-data/4.0?topic=services-????????????


##############################################################
#FindReplace the follwing:
#@SERVICENAME@ to new serice name ex. SPSS
#@SERVICENAMELOWER@ to new serice name ex. spss
#@SERVICEDESCRIPTION@ to new serice name ex.  Statistical Package for the Social Sciences
#@OPERATORCATALOG_FOLDER@  to the new folder for subscription yaml ex. ibm-cpd-spss-operator-catalog
#Delete this section when your done
##############################################################



cp4dService@SERVICENAME@()
{
  printHeaderMessage "Cloud Pak for Data Service - @SERVICEDESCRIPTION@(@SERVICENAME@ )"
  if [ "${CP4D_ENABLE_SERVICE_@SERVICENAME@ }" == "true" ]; then
      if [ ${1} == "apply" ]; then
            echo "Enabling Subscriptions"
            oc apply -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/subscriptions/@OPERATORCATALOG_FOLDER@  -operator-catalog/subscription.yaml
            echo ""
            echo ""
            let  LOOP_COUNT=1
            @SERVICENAME@ _KIND_READY="NOT_READY"
            while [ "${@SERVICENAME@ _KIND_READY}" != "1"  ]
            do
                  echo -en "\033[1A"
                  sleep 1
                  blinkWaitMessage "Waiting for @SERVICEDESCRIPTION@(@SERVICENAME@ ) Opertor to be installed before we create instance" 60
                  @SERVICENAME@ _KIND_READY=`oc get crd | grep -c ??????????????`
                  if [ "${@SERVICENAME@ _KIND_READY}" == "1" ]  ;then
                          oc ${1} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/customresource/@SERVICENAMELOWER@ .yaml
                          echo ""
                          echo "Your request to install the service has been submitted.  It can take 2 hours or more."
                          echo "You can check status via this command: ${DATA_DIR}/${PROJECT_NAME}/${PRODUCT_SHORT_NAME}/service.sh  ${ENV_FILE_NAME} --@SERVICENAME@ Status"
                          echo ""
                  fi
                  if [ $LOOP_COUNT -ge 30 ] ;then
                      echo "IBM @SERVICEDESCRIPTION@(@SERVICENAME@ ) instance could not be installed"
                      echo "After some time, you can run the following command to finsish the setup"
                      echo "                           ${RED_TEXT}oc ${1} -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/customresource/@SERVICENAMELOWER@ .yaml${RESET_TEXT}"
                      echo ""
                      break
                  fi
            done
      else
        if [ ${1} == "delete" ]; then
              #echo "Removing Service now"
              echo "Removing Subscriptions"
              oc delete -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/subscriptions/@OPERATORCATALOG_FOLDER@ /subscription.yaml
              echo "Removing Custom Resource"
              oc delete -f ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/customresource/@SERVICENAMELOWER@ .yaml
        fi
      fi
  fi
  echo ""
}
cp4dService@SERVICENAME@ Status()
{
  printHeaderMessage "Cloud Pak for Data Service - @SERVICEDESCRIPTION@(@SERVICENAME@ )"
  validateCP4DVersion
  echo "Daffy Version                     :  ${DAFFY_VERSION}"
  echo "OpenShift Version                 :  ${OCP_SERVER_VERSION}"
  echo "Zen Version                       :  ${CP4D_ZEN_VERSION}"

  local @SERVICENAME@ _CR_STATUS=`oc get Spss spss -o jsonpath='{.status.?????} {"\n"}' 2>&1`
  if [ -z ${@SERVICENAME@ _CR_STATUS} ]; then
    @SERVICENAME@ _CR_STATUS="Not Found"
  fi
  local @SERVICENAME@ _CCS_STATUS=`oc get CCS ccs-cr -n ibm-common-services -o jsonpath='{.status.ccsStatus} {"\n"}' 2> /dev/null`
  local @SERVICENAME@ _CCS_VERSION=`oc get CCS ccs-cr -n ibm-common-services -o jsonpath='{.status.versions.reconciled} {"\n"}' 2> /dev/null`
  if [ -z ${@SERVICENAME@ _CCS_STATUS} ]; then
    @SERVICENAME@ _CCS_STATUS="Not Found"
  else
    if [ ${@SERVICENAME@ _CCS_STATUS} != "InProgress" ] &&  [ ${@SERVICENAME@ _CCS_STATUS} != "Completed" ]; then
        @SERVICENAME@ _CCS_STATUS="Not Found"
    fi
  fi
  echo "     Common Core Services Module  :  ${@SERVICENAME@ _CCS_STATUS} - ${@SERVICENAME@ _CCS_VERSION}"
  ################################################################################
  ##Add other servcie to check for Here




  ################################################################################
  echo "Custom Resource                   :  ${@SERVICENAME@ _CR_STATUS}"
  echo "Pods:  "
  oc get pods -A -l 'app.kubernetes.io/managed-by=??????'
  oc get pods -A -l 'release in (??????)'
  echo ""
}
