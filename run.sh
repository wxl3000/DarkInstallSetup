#!/bin/bash
#Copyright (C) Tropo 2013
#DarkInstall setup
#Name:run.sh

DARK_SETUP_FILE_ADDRESS="./dark_install_setup.sh"

usage(){
  echo -e "\e[33mrun.sh [-d <DEBUG_MODE>] [-v <PRODUCT_VERSION>] [GATEWAY_DARK_DIRECTORY] [RUNTIME_DARK_DIRECTORY]\e[0m"
  exit 1
}

initial_clean(){
  rm -rf *manifest*
  rm -rf *cookbook_cache*
  rm -rf *chef*
}

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

debug(){ 
  ${DEBUG_MODE} && echo -e "\e[36mDEBUG:[${*}]\e[0m"
}

shift $((OPTIND-1))

GATEWAY_DARK_DIRECTORY=$1
RUNTIME_DARK_DIRECTORY=$2

initial_clean

if [[ -z ${PRODUCT_VERSION} || -z ${GATEWAY_DARK_DIRECTORY} || -z ${RUNTIME_DARK_DIRECTORY} ]]
then
  debug ${PRODUCT_VERSION} ${GATEWAY_DARK_DIRECTORY} ${RUNTIME_DARK_DIRECTORY}
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
  if ! sed -i 's/DEBUG_MODE=false/DEBUG_MODE=true/' ${DARK_SETUP_FILE_ADDRESS}
  then
    echo "\e[31mPlease make sure you have file 'run.sh' in the same directory with file 'dark_install_setup.sh' \e[0m"
  fi
fi

sh ${DARK_SETUP_FILE_ADDRESS} ${PRODUCT_VERSION} ${GATEWAY_DARK_DIRECTORY}
debug sh ${DARK_SETUP_FILE_ADDRESS} ${PRODUCT_VERSION} ${GATEWAY_DARK_DIRECTORY}
sh ${DARK_SETUP_FILE_ADDRESS} ${PRODUCT_VERSION} ${RUNTIME_DARK_DIRECTORY}
debug sh ${DARK_SETUP_FILE_ADDRESS} ${PRODUCT_VERSION} ${RUNTIME_DARK_DIRECTORY}

