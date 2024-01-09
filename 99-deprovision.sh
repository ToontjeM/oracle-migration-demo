#!/usr/local/bin/bash
clear
source ./env.sh

printf "${H}--- Stopping and removing containers ---${N}\n"
docker ps -q --filter "name=orademo" | grep -q . && docker stop orademo && docker rm -fv orademo
docker ps -q --filter "name=edbdemo" | grep -q . && docker stop edbdemo && docker rm -fv edbdemo

printf "${H}--- Stopping and removing Big Animal instance ---${N}\n"
biganimal cluster delete -n tons-biganimal-cluster -p aws -r eu-west-1
biganimal credential delete ton -y
