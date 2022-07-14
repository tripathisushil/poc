############################################################
#Author           : Gerry Baird
#Author email     : gerry.baird@uk.ibm.com
#Original Date    : 2022-05-10
#Initial Version  : v2022-05-23
############################################################
set -x
mkdir -p /mnt/mlserving
chown postgres:postgres /mnt/mlserving
psql -c "create database mlserving template template0 encoding UTF8"
