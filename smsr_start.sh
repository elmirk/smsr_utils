#!/bin/bash

#author: elmir.karimullin@gmail.com
#script used to start smsr (as 3 docker containers) manually
#ordered start used - enode, ss7, cnode

#SCRIPT USAGE:
#to start smsr in production use:
# smsr_start.sh -d 16000 -s PROD
#to start smsr in dev use:
# smsr_start.sh -d 16000 -s DEV

# -c Contaiers: all | enode | ss7 | cnode
# -d Dialogues number (use 16000 for outgoing and incoming dlgs)
# -s Stage = DEV | PROD (PRODuction | DEVeloping)

#NOTES:
#
#1. not used --rm option in docker run,so when DOCKER STOP SS7 used to stop container
#then container not deleted, should delete container by DOCKER RM SS7 before run it again by this script
#2. if you delete container then you couldn't use DOCKER LOGS SS7 to fetch container logs
#3. containers run order - enode, ss7 and then cnode.

#when use ELK
#docker run -it --log-driver gelf --log-opt gelf-address=tcp://localhost:5000 -e DIALOGIC_STAGE=DEV --rm --name=dialogic --ipc="host" --network="host" dialogic:0.0.0 bash

#set -e

usage() { echo "Usage: $0 [-c <all | enode | ss7 | cnode>] [-d <16000>] [-s <string>]" 1>&2; exit 1; }

while getopts ":c:d:s:" o; do
    case "${o}" in
        c)
            CONTAINERS=${OPTARG}
            ;;
        d)
            #s=${OPTARG}
            #((s == 45 || s == 90)) || usage
            TCAP_DLGS_NUM="${OPTARG}"
            ;;
        s)
            STAGE=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [ "${STAGE}" == 'DEV' ] || [ "${STAGE}" == 'PROD' ] ; then
    echo "RUNNING_STAGE=${STAGE}"
else
    echo "Script usage:"
    echo -e "\e[32m $0 -c all -d 16000 -s DEV\e[0m to run smsr in dev environment"
    echo -e "\e[32m $0 -c all -d 16000 -s PROD\e[0m to run smsr in production environment"
    exit
fi

if [ "${CONTAINERS}" == 'all' ] || [ "${CONTAINERS}" == 'enode' ] || [ "${CONTAINERS}" == 'ss7' ] || [ "${CONTAINERS}" == 'cnode' ]  ; then
    echo "Containers to run=${CONTAINERS}"
else
    echo "Script usage:"
    echo -e "\e[32m $0 -c all -d <dlgs_num> -s <DEV | PROD>\e[0m to run all containers for smsr"
    echo -e "\e[32m $0 -c enode -d <dlgs_num> -s <DEV | PROD>\e[0m to run only enode container for smsr"
    echo -e "\e[32m $0 -c ss7 -d <dlgs_num> -s <DEV | PROD>\e[0m to run only ss7 container for smsr"
    echo -e "\e[32m $0 -c cnode -d <dlgs_num> -s <DEV | PROD>\e[0m to run only cnode container for smsr"
    exit
fi


echo "TCAP_DLGS_NUM = ${TCAP_DLGS_NUM}"
echo "STAGE = ${STAGE}"

#check last column of docker ps cmd result
OUT=$(docker ps | awk '{print $NF}' | grep ss7)

if [ $PIPESTATUS -eq 0 ]
then
    echo -e "\e[31m!!!Warning!!!Container ss7 is running, use \e[32mdocker ps\e[31m to check if ss7 running!\e[0m"
    echo -e "\e[31m!!!Warning!!!If running, then use \e[32mdocker stop ss7\e[31m and try again!\e[0m"
    echo -e "\e[31m!!!Warning!!!script exit now...\e[0m"
    exit
fi

#check last column of docker ps cmd result - if container enode is running
OUT=$(docker ps | awk '{print $NF}' | grep enode)

if [ $PIPESTATUS -eq 0 ]
then
    echo -e "\e[31m!!!Warning!!!Container enode is running, use \e[32mdocker ps\e[31m to check if enode running!\e[0m"
    echo -e "\e[31m!!!Warning!!!If running, then use \e[32mdocker stop enode\e[31m and try again!\e[0m"
    echo -e "\e[31m!!!Warning!!!script exit now...\e[0m"
    exit
fi

#check last column of docker ps cmd result - if container cnode is running
OUT=$(docker ps | awk '{print $NF}' | grep cnode)

if [ $PIPESTATUS -eq 0 ]
then
    echo -e "\e[31m!!!Warning!!!Container cnode is running, use \e[32mdocker ps\e[31m to check if cnode running!\e[0m"
    echo -e "\e[31m!!!Warning!!!If running, then use \e[32mdocker stop cnode\e[31m and try again!\e[0m"
    echo -e "\e[31m!!!Warning!!!script exit now...\e[0m"
    exit
fi


#enode
docker run -dit --log-driver=json-file --log-opt max-size=10m --log-opt max-file=15 -e ENV="/root/.shinit" -e SMSR_TCAP_ODLGS_NUM=${TCAP_DLGS_NUM} -e SMSR_TCAP_IDLGS_NUM=${TCAP_DLGS_NUM} -e CONTAINER=enode --name=enode --network="host" enode:0.0.0

sleep 2s
echo "container enode started..."

#ss7
docker run -dit --log-driver=json-file --log-opt env=DIALOGIC_STAGE --log-opt max-size=10m --log-opt max-file=15 -e DIALOGIC_STAGE=${STAGE} -e SMSR_TCAP_ODLGS_NUM=${TCAP_DLGS_NUM} -e SMSR_TCAP_IDLGS_NUM=${TCAP_DLGS_NUM} -e CONTAINER=ss7 --name=ss7 --ipc="host" --network="host" ss7:0.0.0

sleep 2s
echo "container ss7 started..."

#cnode
