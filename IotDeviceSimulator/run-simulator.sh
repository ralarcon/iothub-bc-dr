#!/bin/bash

export IOT_HUB_CONNSTR=##REPLACE_IOT_HUB_CONNSTR##
export DEVICE_CONNSTR=##REPLACE_DEVICE_CONNSTR##

chmod +x iot-device-simulator.dll
./iot-device-simulator.dll