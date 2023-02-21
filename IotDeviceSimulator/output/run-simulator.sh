#!/bin/bash

export IOT_HUB_CONNSTR=HostName=iot-bcdr-hub.azure-devices.net;SharedAccessKeyName=iothubowner;SharedAccessKey=91JgIwcmb5Xxu0R0yDD4Vgi6OeDLViduyztHQKoE2To=
export DEVICE_CONNSTR=HostName=iot-bcdr-hub.azure-devices.net;DeviceId=thermostat1;SharedAccessKey=ot4aVREcnup1LaUar+NhYNCeiW2OXt9NGVlcg1Obbic=

chmod +x iot-device-simulator
./iot-device-simulator