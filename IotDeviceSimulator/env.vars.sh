#!/bin/bash

## ENSURE YOU SET THE CORRECT RSG and HUB in ../variables.sh
## MAKE THIS SCRIPT AN EXECUTABLE SCRIPT BY RUNNING: chmod +x env.vars.sh
## RUN THE SCRIPT BY RUNNING: . env.vars.sh or source env.vars.sh

source ${BASH_SOURCE%/*}/../variables.sh

echo ">>>>>>>>>>>>>>>>>>>"
echo "Setting environment variables for IoTDeviceSimulator"
echo "Hub $HUB in the resource group $RSG"
echo "Device 'thermostat1'"
echo 

export IOT_HUB_CONNSTR=$(az iot hub connection-string show --hub-name $HUB --resource-group $RSG  --policy-name iothubowner --key-type primary -o tsv -o tsv)
export DEVICE_CONNSTR=$(az iot hub device-identity connection-string show --device-id thermostat1 --hub-name $HUB --resource-group $RSG -o tsv)

echo "IOT_HUB_CONNSTR=$IOT_HUB_CONNSTR"
echo "DEVICE_CONNSTR=$DEVICE_CONNSTR"