############################################################
#Author           : Kyle Dawson
#Author email     : Kyle.Dawson@us.ibm.com
#Original Date    : 2021-12-16
#Initial Version  : v2022-01-18
############################################################
applyFix()
{
  if [ -z $1 ]; then
    echo "${RED_TEXT} Missing Fix number${RESET_TEXT}"
  else
    printHeaderMessage "Applying Fix ${1}"
    if [ ! -f "${DATA_DIR}/daffy/fixpaks/${PRODUCT_SHORT_NAME}/${1}.sh" ]; then
        echo "${RED_TEXT}Unable to find fixpak script:"
        echo "${DATA_DIR}/daffy/fixpaks/${PRODUCT_SHORT_NAME}/${1}.sh${RESET_TEXT}"
    else
        source ${DATA_DIR}/daffy/fixpaks/${PRODUCT_SHORT_NAME}/${1}.sh ${1}
    fi
  fi

}
