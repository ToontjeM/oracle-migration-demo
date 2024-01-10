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

printf "${H}--- Load database schemas --- ${N}\n"
docker/load-database

printf "${H}--- Configure PEM --- ${N}\n"
docker/config-pem

printf "${H}--- Info --- ${N}\n"
docker/info
biganimal cluster show -n tons-biganimal-cluster
biganimal cluster show-connection -n tons-biganimal-cluster -p bah:aws -r eu-west-1