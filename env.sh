#!/usr/local/bin/bash
clear

export H='\033[1;32m'
export N='\033[0m'
export EDBTOKEN="$(cat $HOME/.edbtoken)"
export CONTAINER_EDB="edbdemo"
export CONTAINER_ORA="orademo"
export IMAGE_EDB="edbdemo"
export IMAGE_ORA="orademo"
export DOCKERID=$(cat ~/.dockercreds | grep user | awk -F ': ' '{print $2}')
export DOCKERPASS=$(cat ~/.dockercreds | grep password | awk -F ': ' '{print $2}')
export ORADOCKERID=$(cat ~/.dockercreds | grep orauser | awk -F ': ' '{print $2}')
export ORADOCKERPASS=$(cat ~/.dockercreds | grep orapassword | awk -F ': ' '{print $2}')