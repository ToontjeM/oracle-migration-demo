#!/usr/local/bin/bash
clear
source ./env.sh

printf "${H}--- Creating Big Animal instance --- ${N}\n"
biganimal credential create --name “ton”
biganimal config set confirm_mode off
biganimal cluster create -F ba-config.yaml | tee clusterinfo.json

printf "${H}--- Login to Oracle repo ---${N}\n"
docker login container-registry.oracle.com

printf "${H}--- Pull Oracle images --- ${N}\n"
docker pull container-registry.oracle.com/database/express:18.4.0-xe
docker pull oraclelinux:7

printf "${H}--- (Re)creating container image --- ${N}\n"
docker/build-image $EDBTOKEN

printf "${H}--- Create docker containers --- ${N}\n"
docker/create-container

printf "${H}--- Load Oracle database schemas --- ${N}\n"
docker/load-database

printf "${H}--- Update MTK properties file --- ${N}\n"
ORACLEPASS=$(docker/info | grep Password | awk -F ': ' '{print $2}')
BAHOST=$(biganimal cluster show-connection --name tons-biganimal-cluster -p bah:aws -r eu-west-1 -o json | jq '.data.pgUri' |cut -f2 -d"@" | cut -f1 -d":")
docker exec -ti -u root $CONTAINER_EDB /bin/bash -c "sed -i 's/localhost:1521/172.17.0.2:1521/' /usr/edb/migrationtoolkit/etc/toolkit.properties"
docker exec -ti -u root $CONTAINER_EDB /bin/bash -c "sed -i 's/SRC_DB_USER=hr/SRC_DB_USER=system/' /usr/edb/migrationtoolkit/etc/toolkit.properties"
docker exec -ti -u root $CONTAINER_EDB /bin/bash -c "sed -i 's/SRC_DB_PASSWORD=hr/SRC_DB_PASSWORD=$ORACLEPASS/' /usr/edb/migrationtoolkit/etc/toolkit.properties"
docker exec -ti -u root $CONTAINER_EDB /bin/bash -c "sed -i 's/localhost:5444:$BAHOST:1521/' /usr/edb/migrationtoolkit/etc/toolkit.properties"
docker exec -ti -u root $CONTAINER_EDB /bin/bash -c "sed -i 's/TARGET_DB_PASSWORD=edb/TARGET_DB_PASSWORD=enterprisedb/' /usr/edb/migrationtoolkit/etc/toolkit.properties"

printf "${H}--- Configure PEM --- ${N}\n"
docker/config-pem

printf "${H}--- Info --- ${N}\n"
docker ps
docker/info
biganimal cluster show -n tons-biganimal-cluster
biganimal cluster show-connection -n tons-biganimal-cluster -p bah:aws -r eu-west-1