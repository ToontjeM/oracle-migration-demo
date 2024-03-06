#!/usr/local/bin/bash
clear
source ./env.sh

printf "${H}--- Stopping and removing containers ---${N}\n"
docker stop orademo && docker container rm -fv orademo
docker stop edbdemo && docker container rm -fv edbdemo

printf "${H}--- Stopping and removing Big Animal instance ---${N}\n"
biganimal cluster delete -n tons-biganimal-cluster -p bah:aws -r eu-west-1
biganimal credential delete ton -y

rm docker/my_project.ini
