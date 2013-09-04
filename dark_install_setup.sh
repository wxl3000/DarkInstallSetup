#!/bin/bash
#Copyright (C) Tropo 2013
#DarkInstall setup
#Name:dark_install_setup.sh

PRODUCT_VERSION="${1}"
DARK_DIR_ADDRESS="${2%/}"
MANIFEST_NAME="release-manifest.txt"
WGET_FILE_NAME="wget-1.11.4-3.el5_8.2.x86_64.rpm"
PRODUCT_CACHE_DIR="./chef/tropo"
COOKBOOK_CACHE_DIR="./cookbook_cache"
PRODUCT_NAME=$(ls ${DARK_DIR_ADDRESS} | grep build.sh | cut -d "_" -f 1)
GATEWAY_PACKAGE_NAME="gateway_dark_${PRODUCT_VERSION}.tgz"
RUNTIME_PACKAGE_NAME="runtime_dark_${PRODUCT_VERSION}.tgz"
PRODUCT_UPLOAD_SERVER="ftp2.pek.voxeo.com"
PRODUCT_UPLOAD_LOCATION="/home/tropo/DarkInstall"
YUM_METADATA_LOCATION="/home/tropo/DarkInstall/12.3.0/"
YUM_METADATA_NAME="Yum_server.tgz"
#PRODUCT_UPLOAD_SERVER="10.10.0.6"
#PRODUCT_UPLOAD_LOCATION="/var/ftp/pub/tropo/"
#YUM_METADATA_LOCATION="/test"
#YUM_METADATA_NAME="Yum_server.tgz"
DEBUG_MODE=true

usage(){
  echo -e "\e[33mdark_install_setup.sh [PRODUCT_VERSION] [DARK_DIRECTORY_ADDRESS] \e[0m"
  exit 1
}

debug(){
  ${DEBUG_MODE} && echo -e "\e[36mDEBUG:[${*}]\e[0m"
}

have(){
  type ${1} > /dev/null 2>&1
}

wget_install(){
  if ! have wget
  then
    if [[ -f ${WGET_FILE_NAME} ]]
    then
      rpm -ivh ${WGET_FILE_NAME}
      debug rpm -ivh ${WGET_FILE_NAME}
    else
      echo -e "\e[31m Couldn't find 'Wget' installation file, please change to your uncompressed directory.\e[0m"
      exit 2
    fi
  fi
}

manifest_download(){
  if ! wget -P "./" "http://artifacts.voxeolabs.net.s3.amazonaws.com/tropo/${PRODUCT_VERSION}/artifacts/${MANIFEST_NAME}"
  then
    echo -e "\e[31mCouldn't find manifest file, please check your product version number and try again.\e[0m"
    exit 3
  fi
}

product_package_download(){
  mkdir -p ${PRODUCT_CACHE_DIR}
  debug mkdir -p ${PRODUCT_CACHE_DIR}
  if [[ ${PRODUCT_NAME} == 'gateway' ]]
  then
    sh ${DARK_DIR_ADDRESS}/bootstrap.sh  -M -m ${MANIFEST_NAME} -c ./${PRODUCT_CACHE_DIR} trial-gateway
    debug sh ${DARK_DIR_ADDRESS}/bootstrap.sh  -M -m ${MANIFEST_NAME} -c ./${PRODUCT_CACHE_DIR} trial-gateway
  elif [[ ${PRODUCT_NAME} == 'runtime' ]]
  then
    sh ${DARK_DIR_ADDRESS}/bootstrap.sh  -M -m ${MANIFEST_NAME} -c ./${PRODUCT_CACHE_DIR} trial-runtime
    debug sh ${DARK_DIR_ADDRESS}/bootstrap.sh  -M -m ${MANIFEST_NAME} -c ./${PRODUCT_CACHE_DIR} trial-runtime
  fi
}

cookbook_update(){
  if wget -P ${COOKBOOK_CACHE_DIR} "http://artifacts.voxeolabs.net/tropo/${PRODUCT_VERSION}/cookbooks/functional_deployment/${PRODUCT_NAME}_server-${PRODUCT_VERSION}-dark.tar.gz" 
  then
    COOKBOOK_INITIAL_NAME=$(ls ${COOKBOOK_CACHE_DIR})
    debug ${COOKBOOK_INITIAL_NAME}
    COOKBOOK_NAME="trial-${PRODUCT_NAME}-cookbooks.tgz"
    debug ${COOKBOOK_NAME}
    tar zxvf ${COOKBOOK_CACHE_DIR}/${COOKBOOK_INITIAL_NAME} -C ${COOKBOOK_CACHE_DIR}
    debug tar zxvf ${COOKBOOK_CACHE_DIR}/${COOKBOOK_INITIAL_NAME}
    sed -i 's/default\[:base\]\[:dark_install\] = false/default\[:base\]\[:dark_install\] = true/' ${COOKBOOK_CACHE_DIR}/cookbooks/base/attributes/defaults.rb
    debug sed -i 's/default\[:base\]\[:dark_install\] = false/default\[:base\]\[:dark_install\] = true/' ${COOKBOOK_CACHE_DIR}/cookbooks/base/attributes/defaults.rb
    cd ${COOKBOOK_CACHE_DIR}
    tar zcvf ${COOKBOOK_NAME} ./cookbooks  
    debug tar zcvf ${COOKBOOK_NAME} ./cookbooks  
    cd ..
    mv ${COOKBOOK_CACHE_DIR}/${COOKBOOK_NAME} ${PRODUCT_CACHE_DIR}
    debug mv ${COOKBOOK_CACHE_DIR}/${COOKBOOK_NAME} ${PRODUCT_CACHE_DIR}
    rm -rf ${COOKBOOK_CACHE_DIR}
    debug rm -rf ${COOKBOOK_CACHE_DIR}
  else
    echo -e "\e[31m Cookbook download failed, please chek your cookbook URL and try again.\e[0m"
    exit 4
  fi 
}

file_transfer(){
#cookbook transfer
  PRODUCT_CACHE_DIR_OUTSIDE=$(dirname ${PRODUCT_CACHE_DIR})
  debug ${PRODUCT_CACHE_OUTSIDE}
  if [[ -e ${DARK_DIR_ADDRESS}/chef ]]   
  then
    rm -rf ${DARK_DIR_ADDRESS}/chef 
    debug rm -rf ${DARK_DIR_ADDRESS}/chef 
    mv ${PRODUCT_CACHE_DIR_OUTSIDE} ${DARK_DIR_ADDRESS}
    debug mv ${PRODUCT_CACHE_DIR_OUTSIDE} ${DARK_DIR_ADDRESS}
  else
    mv ${PRODUCT_CACHE_DIR_OUTSIDE} ${DARK_DIR_ADDRESS}
    debug mv ${PRODUCT_CACHE_DIR_OUTSIDE} ${DARK_DIR_ADDRESS}
  fi
#manifest transfer
  if [[ -f ${DARK_DIR_ADDRESS}/${MANIFEST_NAME} ]]
  then
    rm -rf ${DARK_DIR_ADDRESS}/${MANIFEST_NAME}  
    debug rm -rf ${DARK_DIR_ADDRESS}/${MANIFEST_NAME}  
    mv ${MANIFEST_NAME} ${DARK_DIR_ADDRESS}
    debug cp ${MANIFEST_NAME} ${DARK_DIR_ADDRESS}
  else
    mv ${MANIFEST_NAME} ${DARK_DIR_ADDRESS}
    debug cp ${MANIFEST_NAME} ${DARK_DIR_ADDRESS}
  fi
}

product_package(){
  CURRENT_DIR=$(pwd)
  PRODUCT_PATH=$(dirname ${DARK_DIR_ADDRESS})
  PRODUCT_DIR_NAME=$(basename ${DARK_DIR_ADDRESS})
  cd ${PRODUCT_PATH}
  if [[ ${PRODUCT_NAME} == "gateway" ]]
  then
    if [[ -e ${GATEWAY_PACKAGE_NAME} ]]     
    then
      rm -rf ${GATEWAY_PACKAGE_NAME} 
      debug rm -rf ${GATEWAY_PACKAGE_NAME} 
      tar zcvf ${GATEWAY_PACKAGE_NAME} ${PRODUCT_DIR_NAME}
      debug tar zcvf ${GATEWAY_PACKAGE_NAME} ${PRODUCT_DIR_NAME}
      cd ${CURRENT_DIR}
    else
      tar zcvf ${GATEWAY_PACKAGE_NAME} ${PRODUCT_DIR_NAME}
      debug tar zcvf ${GATEWAY_PACKAGE_NAME} ${PRODUCT_DIR_NAME}
      cd ${CURRENT_DIR}
    fi
  else 
    if [[ -e ${RUNTIME_PACKAGE_NAME} ]]
    then
      rm -rf ${RUNTIME_PACKAGE_NAME} 
      debug rm -rf ${RUNTIME_PACKAGE_NAME} 
      tar zcvf ${RUNTIME_PACKAGE_NAME} ${PRODUCT_DIR_NAME}
      debug tar zcvf ${RUNTIME_PACKAGE_NAME} ${PRODUCT_DIR_NAME}
      cd ${CURRENT_DIR}
    else
      tar zcvf ${RUNTIME_PACKAGE_NAME} ${PRODUCT_DIR_NAME}
      debug tar zcvf ${RUNTIME_PACKAGE_NAME} ${PRODUCT_DIR_NAME}
      cd ${CURRENT_DIR}
    fi
  fi
}

product_upload(){
  ssh root@${PRODUCT_UPLOAD_SERVER} "ls ${PRODUCT_UPLOAD_LOCATION}/${PRODUCT_VERSION} >/dev/null 2>&1"
  if [[ ${?} -ne 0 ]]
  then
    ssh root@${PRODUCT_UPLOAD_SERVER} "mkdir ${PRODUCT_UPLOAD_LOCATION}/${PRODUCT_VERSION}"
    debug ssh root@${PRODUCT_UPLOAD_SERVER} "mkdir ${PRODUCT_UPLOAD_LOCATION}/${PRODUCT_VERSION}"
    if [[ ${PRODUCT_NAME} == "gateway" ]]
    then
      scp ${PRODUCT_PATH}/${GATEWAY_PACKAGE_NAME} root@"${PRODUCT_UPLOAD_SERVER}:${PRODUCT_UPLOAD_LOCATION}/${PRODUCT_VERSION}"
      debug scp ${PRODUCT_PATH}/${GATEWAY_PACKAGE_NAME} root@"${PRODUCT_UPLOAD_SERVER}:${PRODUCT_UPLOAD_LOCATION}/${PRODUCT_VERSION}"
      echo -e "\e[32mGateway package was uploaded successfully\e[0m"
    elif [[ ${PRODUCT_NAME} == "runtime" ]]
    then
      scp ${PRODUCT_PATH}/${RUNTIME_PACKAGE_NAME} root@"${PRODUCT_UPLOAD_SERVER}:${PRODUCT_UPLOAD_LOCATION}/${PRODUCT_VERSION}"
      debug scp ${PRODUCT_PATH}/${RUNTIME_PACKAGE_NAME} root@"${PRODUCT_UPLOAD_SERVER}:${PRODUCT_UPLOAD_LOCATION}/${PRODUCT_VERSION}"
      echo -e "\e[32mRuntime package was uploaded successfully\e[0m"
    else
      echo -e "\e[31mWrong product name given, please current it and try again.\e[0m"
      exit 5
    fi
  else
    if [[ ${PRODUCT_NAME} == "gateway" ]]
    then
      ssh root@${PRODUCT_UPLOAD_SERVER} "ls ${PRODUCT_UPLOAD_LOCATION}/${PRODUCT_VERSION}/${GATEWAY_PACKAGE_NAME} >/dev/null 2>&1"
      if [[ ${?} -ne 0 ]]
      then
        scp ${PRODUCT_PATH}/${GATEWAY_PACKAGE_NAME} root@"${PRODUCT_UPLOAD_SERVER}:${PRODUCT_UPLOAD_LOCATION}/${PRODUCT_VERSION}"
        debug scp ${PRODUCT_PATH}/${GATEWAY_PACKAGE_NAME} root@"${PRODUCT_UPLOAD_SERVER}:${PRODUCT_UPLOAD_LOCATION}/${PRODUCT_VERSION}"
        echo -e "\e[32mGateway package was uploaded successfully\e[0m"
      else
        while true
        do
          read -p "Gateway package is already exist in your ftp server, do you want to replace it? (yes/no): " reply
          reply=$(tr '[A-Z]' '[a-z]' <<< ${reply})
          if [[ ${reply} == "yes" || ${reply} == "y" ]]
          then
            ssh root@${PRODUCT_UPLOAD_SERVER} "rm -rf ${PRODUCT_UPLOAD_LOCATION}/${PRODUCT_VERSION}/${GATEWAY_PACKAGE_NAME}"
            scp ${PRODUCT_PATH}/${GATEWAY_PACKAGE_NAME} root@"${PRODUCT_UPLOAD_SERVER}:${PRODUCT_UPLOAD_LOCATION}/${PRODUCT_VERSION}"
            debug scp ${PRODUCT_PATH}/${GATEWAY_PACKAGE_NAME} root@"${PRODUCT_UPLOAD_SERVER}:${PRODUCT_UPLOAD_LOCATION}/${PRODUCT_VERSION}"
            echo -e "\e[32mGateway package was uploaded successfully\e[0m"
            break
          elif [[ ${reply} == "no" || ${reply} == "n" ]]
          then
            echo -e "\e[31mGateway package is already exist in your ftp server, please check your product version number and try again.\e[0m"
            exit 6
          else
            continue
          fi
        done
      fi
    elif [[ ${PRODUCT_NAME} == "runtime" ]]
    then
      ssh root@${PRODUCT_UPLOAD_SERVER} "ls ${PRODUCT_UPLOAD_LOCATION}/${PRODUCT_VERSION}/${RUNTIME_PACKAGE_NAME} >/dev/null 2>&1"
      if [[ ${?} -ne 0 ]]
      then
        scp ${PRODUCT_PATH}/${RUNTIME_PACKAGE_NAME} root@"${PRODUCT_UPLOAD_SERVER}:${PRODUCT_UPLOAD_LOCATION}/${PRODUCT_VERSION}"
        debug scp ${PRODUCT_PATH}/${RUNTIME_PACKAGE_NAME} root@"${PRODUCT_UPLOAD_SERVER}:${PRODUCT_UPLOAD_LOCATION}/${PRODUCT_VERSION}"
        echo -e "\e[32mRuntime package was uploaded successfully\e[0m"
      else
        while true
        do
          read -p "Runtime package is already exist in your ftp server, do you want to replace it? (yes/no): " reply
          reply=$(tr '[A-Z]' '[a-z]' <<< ${reply})
          if [[ ${reply} == "yes" || ${reply} == "y" ]]
          then
            ssh root@${PRODUCT_UPLOAD_SERVER} "rm -rf ${PRODUCT_UPLOAD_LOCATION}/${PRODUCT_VERSION}/${RUNTIME_PACKAGE_NAME}"
            scp ${PRODUCT_PATH}/${RUNTIME_PACKAGE_NAME} root@"${PRODUCT_UPLOAD_SERVER}:${PRODUCT_UPLOAD_LOCATION}/${PRODUCT_VERSION}"
            debug scp ${PRODUCT_PATH}/${RUNTIME_PACKAGE_NAME} root@"${PRODUCT_UPLOAD_SERVER}:${PRODUCT_UPLOAD_LOCATION}/${PRODUCT_VERSION}"
            echo -e "\e[32mRuntime package was uploaded successfully\e[0m"
            break
          elif [[ ${reply} == "no" || ${reply} == "n" ]]
          then
            echo -e "\e[31mRuntime package is already exist in your ftp server, please check your product version number and try again.\e[0m"
            exit 6
          else
            continue
          fi
        done
      fi
    else
      echo -e "\e[31mWrong product name given, please current it and try again.\e[0m"
      exit 5
    fi
fi
}

yum_metadata_transfer(){
  ssh root@${PRODUCT_UPLOAD_SERVER} "ls ${PRODUCT_UPLOAD_LOCATION}/${PRODUCT_VERSION}/${YUM_METADATA_NAME} >/dev/null 2>&1"
      if [[ ${?} -ne 0 ]]
      then
        ssh root@${PRODUCT_UPLOAD_SERVER} "ln ${YUM_METADATA_LOCATION}/${YUM_METADATA_NAME} ${PRODUCT_UPLOAD_LOCATION}/${PRODUCT_VERSION}"  
        debug ssh root@${PRODUCT_UPLOAD_SERVER} "ln ${YUM_METADATA_LOCATION}/${YUM_METADATA_NAME} ${PRODUCT_UPLOAD_LOCATION}/${PRODUCT_VERSION}"        echo -e "\e[32mYum package was uploaded successfully\e[0m"
      else
        echo -e "\e[32mYum package is already exist\e[0m"
      fi
}

if [[ -z ${PRODUCT_VERSION} || -z ${DARK_DIR_ADDRESS} ]]
then
  usage
else
  echo ${PRODUCT_VERSION} | grep -o -E "[0-9]{1,2}\.[0-9]{1,2}\.[0-9]{1,2}" >/dev/null 2>&1
  if [[ ${?} -ne 0 ]]
  then
    debug ${PRODUCT_VERSION}
    echo -e "\e[31mWrong version number, please current it and try again.\e[0m"
    exit 7
  fi
fi

wget_install
manifest_download
product_package_download
cookbook_update
file_transfer
product_package
product_upload
yum_metadata_transfer

