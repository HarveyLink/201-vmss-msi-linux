#!/bin/bash
startuptime1=$(date +%s%3N)

while getopts ":i:a:c:r:p:" opt; do
  case $opt in
    i) docker_image="$OPTARG"
    ;;
    a) storage_account="$OPTARG"
    ;;
    c) container_name="$OPTARG"
    ;;
    r) resource_group="$OPTARG"
    ;;
    p) password="$OPTARG"
    ;;

t) script_file="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
    ;;
  esac
done

if [ -z $docker_image ]; then
    docker_image="azuresdk/azure-cli-python:latest"
fi

if [ -z $script_file ]; then
    script_file="writeblob.sh"
fi

for var in storage_account resource_group
do

    if [ -z ${!var} ]; then
        echo "Argument $var is not set" >&2
        exit 1
    fi 

done

# Install Azure CLI and then build image with az

sudo apt-get -y update
sudo apt-get -y install linux-image-extra-$(uname -r) linux-image-extra-virtual
sudo apt-get -y update
sudo apt-get -y install apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get -y update

#Install Azure CLI
AZ_REPO=$(lsb_release -cs)
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | \
     sudo tee /etc/apt/sources.list.d/azure-cli.list
sudo apt-key adv --keyserver packages.microsoft.com --recv-keys 52E16F86FEE04B979B07E28DB02C46DF417A0893
sudo apt-get install apt-transport-https
sudo apt-get update && sudo apt-get install azure-cli

sudo apt-get -y update
sudo apt-get install cifs-utils

sudo apt-get -y update
sudo apt install git-all

today=$(date +%Y-%m-%d)
currenttime=$(date +%s)
machineName=$(hostname)
sudo mkdir /mnt/azurefiles
sudo mount -t cifs //acrtestlogs.file.core.windows.net/logshare /mnt/azurefiles -o vers=3.0,username=acrtestlogs,password=ZIisPCN0UrjLfhv6Njiz0Q8w9YizeQgIm6+DIfMtjak4RJrRlzJFn4EcwDUhNvXmmDv5Axw9yGePh3vn1ak8cg==,dir_mode=0777,file_mode=0777,sec=ntlmssp
sudo mkdir /mnt/azurefiles/$today
sudo mkdir /mnt/azurefiles/$today/Scenario1
sudo mkdir /mnt/azurefiles/$today/Scenario1/$machineName$currenttime


ACR_NAME="NewACRLoadTestBuildCR"
sudo git clone https://github.com/SteveLasker/node-helloworld.git
cd node-helloworld
az login -u azcrci@microsoft.com -p $p
az account set --subscription "c451bd61-44a6-4b44-890c-ef4c903b7b12"
az extension remove -n acrbuildext
az extension add --source https://acrbuild.blob.core.windows.net/cli/acrbuildext-0.0.2-py2.py3-none-any.whl -y

echo "---ACR Build Test---"
pullbegin=$(date +%s%3N)
PullStartTime=$(date +%H:%M:%S)
for (( i=1; i<=100; i++ ))  
  do    
   az acr build -t helloworld$i:v1 --context . -r $ACR_NAME
  done
pullend=$(date +%s%3N)
PullEndTime=$(date +%H:%M:%S)
pulltime=$((pullend-pullbegin))
echo starttime,endtime,pulltime:$PullStartTime,$PullEndTime,$pulltime >> /mnt/azurefiles/$today/Scenario1/$machineName$currenttime/acr-buid-output.log
