#!/bin/bash
############################################################
#Author           : Kyle Dawson
#Author email     : Kyle.Dawson@us.ibm.com
#Original Date    : 2021-12-21
#Init Version     : v2022-01-18
############################################################
cloudCTLInstall()
{
  printHeaderMessage "Cloud CTL command line tool"

  case ${CP4D_VERSION} in
    4.02|4.0.2|4.0.3|4.0.4|4.0.5)
        cloudCTLPython2Install
        rm -fR /usr/bin/python
        ln -s /usr/bin/python2 /usr/bin/python
        cloudCTLPip2Install
        ;;
    *)
        cloudCTLPython3Install
        rm -fR /usr/bin/python
        ln -s /usr/bin/python3 /usr/bin/python
        cloudCTLPip3Install
        pip3 install argparse &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/pip3-install.log
        ;;
esac

  CLOUDCTL_INSTALL=`cloudctl version 2>/dev/null | grep -c "Client Version"`
  if [ ${CLOUDCTL_INSTALL} == 1 ] ;then
      echo "${BLUE_TEXT}PASSED ${RESET_TEXT} cloudctl command line tool already installed."
  else
      echo "Missing cloudctl command, installing now. (LOG -> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/cloudctl-install.log )"
      curl -L https://github.com/IBM/cloud-pak-cli/releases/latest/download/cloudctl-linux-amd64.tar.gz -o ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/cloudctl-linux-amd64.tar.gz &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/cloudctl-install.log
      curl -L https://github.com/IBM/cloud-pak-cli/releases/latest/download/cloudctl-linux-amd64.tar.gz.sig -o ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/cloudctl-linux-amd64.tar.gz.sig >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/cloudctl-install.log 2>&1
      tar -xzf ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/cloudctl-linux-amd64.tar.gz -C ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/ >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/cloudctl-install.log 2>&1
      chmod 775 ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/cloudctl-linux-amd64  >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/cloudctl-install.log 2>&1
      rm -fR /usr/local/bin/cloudctl 2&1>/dev/null
      mv ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/cloudctl-linux-amd64 /usr/local/bin/cloudctl >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/cloudctl-install.log 2>&1
      CLOUDCTL_INSTALL=`cloudctl version 2>/dev/null | grep -c "Client Version"`
      if [ ${CLOUDCTL_INSTALL} == 1 ] ;then
           echo "${BLUE_TEXT}PASSED ${RESET_TEXT} cloudctl command line tool installed successfully."
      else
          SHOULD_EXIT=1
          echo "${RED_TEXT}Unable to install cloudctl command, exit script now.${RESET_TEXT}"
      fi
  fi
  echo ""
}
cloudCTLPython2Install()
{
  if [ ${IS_UBUNTU} == 1 ]; then
      PYTHON_INSTALL=`python2 -V 2> ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/python-out.log ; cat ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/python-out.log |   grep -c "Python 2"; rm -fR ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/python-out.log`
      if [ "${PYTHON_INSTALL}" == "1" ] ;then
          echo "${BLUE_TEXT}PASSED ${RESET_TEXT} python2 command line tool already installed."
      else
          echo "Missing python2 command, installing now (LOG ->  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/python-install.log )"
          $OS_INSTALL -y install python  > ${LOG_DIR}/${PRODUCT_SHORT_NAME}/python-install.log
          PYTHON_INSTALL=`python2 -V 2> ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/python-out.log ; cat ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/python-out.log |   grep -c "Python 2"; rm -fR ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/python-out.log`
          if [ "${PYTHON_INSTALL}" == "1" ] ;then
              echo "${BLUE_TEXT}PASSED ${RESET_TEXT} python2 command line tool already installed."
          else
              echo "${RED_TEXT}FAILED: Missing python2 command, unable to install.${RESET_TEXT}"
              exit 99
          fi
      fi
  elif [ ${IS_RH} == 1 ]; then
          $OS_INSTALL -y install python2  > ${LOG_DIR}/${PRODUCT_SHORT_NAME}/python-install.log
          PYTHON_INSTALL=`python2 -V 2> ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/python-out.log ; cat ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/python-out.log |   grep -c "Python 2"; rm -fR ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/python-out.log`
      if [ "${PYTHON_INSTALL}" == "1" ] ;then
          echo "${BLUE_TEXT}PASSED ${RESET_TEXT} python2 command line tool installed successfully."
      else
          echo "${RED_TEXT}FAILED: Missing python2 command, unable to install.${RESET_TEXT}"
          SHOULD_EXIT=1
      fi
  fi
}
cloudCTLPython3Install()
{
  if [ ${IS_UBUNTU} == 1 ]; then
      PYTHON_INSTALL=`python3 -V |   grep -c "Python 3"`
      if [ "${PYTHON_INSTALL}" == "1" ] ;then
          echo "${BLUE_TEXT}PASSED ${RESET_TEXT} python3 command line tool already installed."
      else
          echo "Missing python3 command, installing now (LOG ->  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/python-install.log )"
          $OS_INSTALL -y install python3  > ${LOG_DIR}/${PRODUCT_SHORT_NAME}/python-install.log
          PYTHON_INSTALL=`python3 -V |   grep -c "Python 3"`
          if [ "${PYTHON_INSTALL}" == "1" ] ;then
              echo "${BLUE_TEXT}PASSED ${RESET_TEXT} python3 command line tool already installed."
          else
              echo "${RED_TEXT}FAILED  ${RESET_TEXT} Missing python3 command, unable to install.${RESET_TEXT}"
              exit 99
          fi
      fi
  elif [ ${IS_RH} == 1 ]; then
          $OS_INSTALL -y install python3  > ${LOG_DIR}/${PRODUCT_SHORT_NAME}/python-install.log
          PYTHON_INSTALL=`python3 -V |   grep -c "Python 3"`
      if [ "${PYTHON_INSTALL}" == "1" ] ;then
          echo "${BLUE_TEXT}PASSED ${RESET_TEXT} python3 command line tool installed successfully."
      else
          echo "${RED_TEXT}FAILED: Missing python3 command, unable to install.${RESET_TEXT}"
          SHOULD_EXIT=1
      fi
  fi
}
cloudCTLPip2Install()
{
  if [ ${IS_UBUNTU} == 1 ]; then
      PIP2_INSTALL=`pip2 -V 2>/dev/null |  grep -c "pip 20"`
      if [ "${PIP2_INSTALL}" == "1" ] ;then
          echo "${BLUE_TEXT}PASSED ${RESET_TEXT} pip2 command line tool already installed."
      else
          echo "Missing pip2 command, installing now. (LOG ->  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/pip2-install.log )"
          curl https://bootstrap.pypa.io/pip/2.7/get-pip.py --output ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/get-pip.py &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/pip2-install.log
          python2 ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/get-pip.py >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/pip2-install.log 2>&1
          pip2 install pyyaml >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/pip2-install.log 2>&1
          PIP2_INSTALL=`pip2 -V  |  grep -c "pip 20" 2>/dev/null`
          if [ "${PIP2_INSTALL}" == "1" ] ;then
              echo "${BLUE_TEXT}PASSED ${RESET_TEXT} pip2 command line tool installed successfully."
          else
              echo "${RED_TEXT}FAILED: Missing pip2 command, unable to install.${RESET_TEXT}"
              SHOULD_EXIT=1
          fi
      fi
  elif [ ${IS_RH} == 1 ]; then
      PIP2_INSTALL=`pip2 -V 2>/dev/null |  grep -c "pip 9"`
      if [ "${PIP2_INSTALL}" == "1" ] ;then
          echo "${BLUE_TEXT}PASSED ${RESET_TEXT} pip2 command line tool already installed."
          pip2 install pyyaml >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/pip2-install.log 2>&1
          PIP2_INSTALL=`pip2 -V  |  grep -c "pip 20" 2>/dev/null`
      else
          echo "Missing pip2 command, installing now  (LOG ->  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/pip2-install.log )"
          $OS_INSTALL -y intall python2-pip >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/pip2-install.log 2>&1
          PIP2_INSTALL=`pip2 -V  |  grep -c "pip 9" 2>/dev/null`
          if [ "${PIP2_INSTALL}" == "1" ] ;then
              echo "${BLUE_TEXT}PASSED ${RESET_TEXT} pip2 command line tool installed successfully."
          else
              echo "${RED_TEXT}FAILED: Missing pip2 command, unable to install.${RESET_TEXT}"
              SHOULD_EXIT=1
          fi
      fi
  fi
}

cloudCTLPip3Install()
{
  if [ ${IS_UBUNTU} == 1 ]; then
      PIP3_INSTALL=`pip3 -V 2>/dev/null |  grep -c "pip 21"`
      if [ "${PIP3_INSTALL}" == "1" ] ;then
          echo "${BLUE_TEXT}PASSED ${RESET_TEXT} pip3 command line tool already installed."
      else
          echo "Missing pip3 command, installing now.  (LOG ->  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/pip3-install.log )"
          curl https://bootstrap.pypa.io/pip/3.6/get-pip.py --output ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/get-pip.py &> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/pip3-install.log
          python3 ${TEMP_DIR}/${PRODUCT_SHORT_NAME}/get-pip.py  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/pip3-install.log
          pip3 install pyyaml >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/pip3-install.log 2>&1
          PIP3_INSTALL=`pip3 -V  |  grep -c "pip 21" 2>/dev/null`
          if [ "${PIP3_INSTALL}" == "1" ] ;then
              echo "${BLUE_TEXT}PASSED ${RESET_TEXT} pip3 command line tool installed successfully."
          else
              echo "${RED_TEXT}FAILED: Missing pip3 command, unable to install.${RESET_TEXT}"
              SHOULD_EXIT=1
          fi
      fi
  elif [ ${IS_RH} == 1 ]; then
      PIP3_INSTALL=`pip3 -V 2>/dev/null |  grep -c "pip 9"`
      if [ "${PIP3_INSTALL}" == "1" ] ;then
          echo "${BLUE_TEXT}PASSED ${RESET_TEXT} pip3 command line tool already installed."
          pip3 install pyyaml >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/pip3-install.log 2>&1
          PIP3_INSTALL=`pip3 -V  |  grep -c "pip 21" 2>/dev/null`
      else
          echo "Missing pip2 command, installing now. (LOG ->  ${LOG_DIR}/${PRODUCT_SHORT_NAME}/pip3-install.log )"
          $OS_INSTALL -y intall python2-pip >> ${LOG_DIR}/${PRODUCT_SHORT_NAME}/pip3-install.log 2>&1
          PIP3_INSTALL=`pip3 -V  |  grep -c "pip 9" 2>/dev/null`
          if [ "${PIP3_INSTALL}" == "1" ] ;then
              echo "${BLUE_TEXT}PASSED ${RESET_TEXT} pip3 command line tool installed successfully."
          else
              echo "${RED_TEXT}FAILED: Missing pip3 command, unable to install.${RESET_TEXT}"
              SHOULD_EXIT=1
          fi
      fi
  fi
}
