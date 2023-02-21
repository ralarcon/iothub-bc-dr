#!/bin/bash

export IOT_HUB_CONNSTR='##REPLACE_IOT_HUB_CONNSTR##'
export DEVICE_CONNSTR='##REPLACE_DEVICE_CONNSTR##'

rm -f output.log
chmod +x iot-device-simulator
nohup ./iot-device-simulator > output.log 2>&1 &

echo ">>>"
echo "Simulator started in background. Log generated in output.log."
echo "To stop the simulator, run the following command: killall iot-device-simulator"
echo "To view the output log, run the following command: tail output.log -f"
echo "<<<"
