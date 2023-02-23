#!/bin/bash

## ENSURE YOU SET THE CORRECT RSG and HUB in ../variables.sh
## MAKE THIS SCRIPT AN EXECUTABLE SCRIPT BY RUNNING: chmod +x env.vars.sh
## RUN THE SCRIPT BY RUNNING: . env.vars.sh or source env.vars.sh

source ${BASH_SOURCE%/*}/../variables.sh

echo ">>>>>>>>>>>>>>>>>>>"
echo "Setting environment variables for export - import device identities"
echo "From iot-playground-devices-hub to the hub $HUB in the resource group $RSG"
echo 

export SOURCE_IOTHUB_CONN_STRING_CSHARP=$(az iot hub connection-string show --hub-name iot-playground-devices-hub --resource-group iot-playground-rsg -o tsv)
export DEST_IOTHUB_CONN_STRING_CSHARP=$(az iot hub connection-string show --hub-name $HUB --resource-group $RSG -o tsv)
export STORAGE_CONN_STRING_CSHARP=$(az storage account show-connection-string --name iotstg$SUFIX --resource-group $RSG -o tsv)

echo "SOURCE_IOTHUB_CONN_STRING_CSHARP=$SOURCE_IOTHUB_CONN_STRING_CSHARP"
echo "DEST_IOTHUB_CONN_STRING_CSHARP=$DEST_IOTHUB_CONN_STRING_CSHARP"
echo "STORAGE_CONN_STRING_CSHARP=$STORAGE_CONN_STRING_CSHARP"