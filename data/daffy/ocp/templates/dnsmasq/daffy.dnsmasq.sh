#!/bin/sh
### BEGIN INIT INFO
# Provides:       daffy-dnsmasq
# Required-Start: $network $remote_fs $syslog
# Required-Stop:  $network $remote_fs $syslog
# Default-Start:  2 3 4 5
# Default-Stop:   0 1 6
# Description:    fix for dnsmasq on reboot - start up order issue
### END INIT INFO

DAFFY_DNSMASQ_LOG_DIR=@DATA_DIR@/@PROJECT_NAME@/log
mkdir -p ${DAFFY_DNSMASQ_LOG_DIR}
DAFFY_DNSMASQ_LOG_FILE=${DAFFY_DNSMASQ_LOG_DIR}/boot-dnsmasq.log
DAFFY_DATE=`date`
LOOP_COUNT=0
case "$1" in
  start)
		echo "${DAFFY_DATE} Runnning daffy restart of dnsmasq job" >> ${DAFFY_DNSMASQ_LOG_FILE}
		BR_OCP_UP=`systemctl status dnsmasq | grep -c "FAILED"`
		while [ ${BR_OCP_UP} -eq 1 ]
		do
				DAFFY_DATE=`date`
				echo ${DAFFY_DATE} >> ${DAFFY_DNSMASQ_LOG_FILE}
				sleep 10
				systemctl restart dnsmasq > /dev/null
				BR_OCP_UP=`systemctl status dnsmasq | grep -c "FAILED"`
				let LOOP_COUNT=LOOP_COUNT+1
				if [ $LOOP_COUNT -ge 30 ] ;then
					systemctl status dnsmasq  >> ${DAFFY_DNSMASQ_LOG_FILE}
					break
				fi
		done
		DAFFY_DATE=`date`
		echo "${DAFFY_DATE} Finished daffy restart of dnsmasq job" >> ${DAFFY_DNSMASQ_LOG_FILE}
        ;;
esac
exit 0
