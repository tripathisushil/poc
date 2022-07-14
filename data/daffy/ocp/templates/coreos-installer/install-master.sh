sudo coreos-installer install   --copy-network --insecure-ignition --ignition-file master.ign /dev/sda
#Send files back to bastion to say that we are good.
#touch $HOSTNAME-all-good.txt
#scp $HOSTNAME-all-good.txt @BASTIONID@@BASTION_HOST@:/${TEMP_DIR}/${PRODUCT_SHORT_NAME}/nodes-checkin
