#!/bin/bash

## ENSURE YOU SET THE CORRECT RSG and HUB
## MAKE THIS SCRIPT AN EXECUTABLE SCRIPT BY RUNNING: chmod +x env.vars.sh
## RUN THE SCRIPT BY RUNNING: . env.vars.sh or source env.vars.sh

export SUFIX=bcdr
export RSG=iot-$SUFIX
export HUB=iot-$SUFIX-hub

echo ">>>>>>>>>>>>>>>>>>>"
echo "Setting environment variables for IoTDeviceSimulator"
echo "Hub $HUB in the resource group $RSG"
echo "Device 'thermostat1'"
echo 

export IOT_HUB_CONNSTR=$(az iot hub connection-string show --hub-name $HUB --resource-group $RSG  --policy-name iothubowner --key-type primary -o tsv -o tsv)
export DEVICE_CONNSTR=$(az iot hub device-identity connection-string show --device-id thermostat1 --hub-name $HUB --resource-group $RSG -o tsv)

echo "IOT_HUB_CONNSTR=$SOURCE_IOTHUB_CONN_STRING_CSHARP"
echo "DEVICE_CONNSTR=$DEST_IOTHUB_CONN_STRING_CSHARP"