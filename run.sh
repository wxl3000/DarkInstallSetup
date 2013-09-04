#!/bin/bash
#Copyright (C) Tropo 2013
#DarkInstall setup
#Name:run.sh

DARK_SETUP_FILE="./dark_install_setup.sh"
ARTIFACTS_SERVER="ftp2.pek.voxeo.com"
ARTIFACTS_LOCATION="${ARTIFACTS_SERVER}:/workstation"

while getopts dv: opt;
do 
  case ${opt} in
    d)
      DEBUG_MODE=true 
    ;;  
    v)
      PRODUCT_VERSION=${OPTARG}
    ;;
  esac
done

usage(){
  echo -e "\e[33mrun.sh [-d DEBUG_MODE] [-v <PRODUCT_VERSION>]\e[0m"
  exit 1
}

debug(){ 
  ${DEBUG_MODE} && echo -e "\e[36mDEBUG:[${*}]\e[0m"
}

initial_clean(){
  rm -rf *manifest*
  rm -rf *cookbook_cache*
  rm -rf *chef*
  rm -rf *ratical*
  rm -rf *server*
}

artifacts_download(){
  scp root@${ARTIFACTS_LOCATION}/${1} ./
}

shift $((OPTIND-1))
GATEWAY_DARK_DIRECTORY=$1
RUNTIME_DARK_DIRECTORY=$2

initial_clean

if [[ -z ${PRODUCT_VERSION} ]]
then
  usage
else
  echo ${PRODUCT_VERSION} | grep -o -E "[0-9]{1,2}\.[0-9]{1,2}\.[0-9]{1,2}" >/dev/null 2>&1
  if [[ ${?} -ne 0 ]]
  then
    debug ${PRODUCT_VERSION}
    echo -e "\e[31mWrong version number, please current it and try again.\e[0m"
    exit 2
  fi
fi

if [[ ${DEBUG_MODE} == true ]]
then
  if ! sed -i 's/DEBUG_MODE=false/DEBUG_MODE=true/' ${DARK_SETUP_FILE}
  then
    echo "\e[31mPlease make sure you have file 'run.sh' in the same directory with file 'dark_install_setup.sh' \e[0m"
  fi
fi

artifacts_download gateway_ratical.tgz && tar zxvf gateway_ratical.tgz
artifacts_download runtime_ratical.tgz && tar zxvf runtime_ratical.tgz

sh ${DARK_SETUP_FILE} ${PRODUCT_VERSION} ./gateway_server
debug sh ${DARK_SETUP_FILE} ${PRODUCT_VERSION} ./gateway_server
sh ${DARK_SETUP_FILE} ${PRODUCT_VERSION} ./runtime_server
debug sh ${DARK_SETUP_FILE} ${PRODUCT_VERSION} ./runtime_server

rm -rf gateway_ratical.tgz runtime_ratical.tgz gateway_server runtime_server gateway_dark*.tgz runtime_dark*.tgz


