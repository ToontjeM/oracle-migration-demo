#!/bin/bash
clear
source ./env.sh

printf "${H}--- Creating Big Animal instance --- ${N}\n"
biganimal credential create --name ton
biganimal config set confirm_mode off
biganimal cluster create -F ba-config.yaml

printf "${H}--- Pull Oracle images --- ${N}\n"
#docker login container-registry.oracle.com -u $DOCKERID -p $DOCKERPASS
docker pull container-registry.oracle.com/database/express:18.4.0-xe
docker pull oraclelinux:7
docker pull oraclelinux:8

printf "${H}--- (Re)creating container image --- ${N}\n"
docker/build-image $EDBTOKEN

printf "${H}--- Create docker containers --- ${N}\n"
docker/create-container

printf "${H}--- Starting Postgres --- ${N}\n"
docker exec -d -u enterprisedb $CONTAINER_EDB /usr/edb/as15/bin/pg_ctl -D /var/lib/edb/as15/data start

printf "${H}--- Load Oracle database schemas --- ${N}\n"
docker/load-database 

printf "${H}--- Update MTK properties file --- ${N}\n"
ORACLEPASS=$(docker/info | grep Password | awk -F ': ' '{print $2}')
BAHOST=$(biganimal cluster show-connection --name tons-biganimal-cluster -p bah:aws -r eu-west-1 -o json | jq '.data.pgUri' |cut -f2 -d"@" | cut -f1 -d":");
echo $BAHOST
while [ -z "$BAHOST" ]; do
    echo "--- Wait for BA cluster to become ready ---"
    sleep 5; 
    export  BAHOST=$(biganimal cluster show-connection --name tons-biganimal-cluster -p bah:aws -r eu-west-1 -o json | jq '.data.pgUri' |cut -f2 -d"@" | cut -f1 -d":");
done

docker exec -ti -u root $CONTAINER_EDB /bin/bash -c "sed -i 's/localhost:1521:xe/172.17.0.2:1521\/XEPDB1/' /usr/edb/migrationtoolkit/etc/toolkit.properties"
docker exec -ti -u root $CONTAINER_EDB /bin/bash -c "sed -i 's/localhost:5444\/edb/$BAHOST:5432\/edb_admin?sslmode=require/' /usr/edb/migrationtoolkit/etc/toolkit.properties"
docker exec -ti -u root $CONTAINER_EDB /bin/bash -c "sed -i 's/SRC_DB_USER=hr/SRC_DB_USER=system/' /usr/edb/migrationtoolkit/etc/toolkit.properties"
docker exec -ti -u root $CONTAINER_EDB /bin/bash -c "sed -i 's/SRC_DB_PASSWORD=hr/SRC_DB_PASSWORD=$ORACLEPASS/' /usr/edb/migrationtoolkit/etc/toolkit.properties"
docker exec -ti -u root $CONTAINER_EDB /bin/bash -c "sed -i 's/TARGET_DB_USER=enterprisedb/TARGET_DB_USER=edb_admin/' /usr/edb/migrationtoolkit/etc/toolkit.properties"
docker exec -ti -u root $CONTAINER_EDB /bin/bash -c "sed -i 's/TARGET_DB_PASSWORD=edb/TARGET_DB_PASSWORD=enterprisedb/' /usr/edb/migrationtoolkit/etc/toolkit.properties"
docker exec -ti -u root $CONTAINER_EDB /bin/bash -c "sed -i 's/toolkit.properties/toolkit.properties -Djava.class.path=\/root\/jars -Djavax.xml.parsers.DocumentBuilderFactory=com.sun.org.apache.xerces.internal.jaxp.DocumentBuilderFactoryImpl/' /usr/edb/migrationtoolkit/bin/runMTK.sh"

printf "${H}--- Update Livecompare properties file --- ${N}\n"
cp docker/my_projectini docker/my_project.ini
gsed -i 's/biganimal/'"$BAHOST"'/' docker/my_project.ini
gsed -i 's/orapass/'"$ORACLEPASS"'/' docker/my_project.ini

printf "${H}--- Info --- ${N}\n"
docker ps
docker/info
biganimal cluster show -n tons-biganimal-cluster
biganimal cluster show-connection -n tons-biganimal-cluster -p bah:aws -r eu-west-1
