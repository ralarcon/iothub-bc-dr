# iothub-bc-dr
Business Continuity and Disaster Recover for IoT Hub

## Scenarios:
- Business Continuity:
  - IoT Hub needs to Fail Over, ensure the connectivity is maintained using the primary region PE.
  - Network disruption (I imagine a possible issue like Express Route failure / Networking outage in the primary region so they need to Fail Over the IoT Hub + configure dns resolution for the PE in the secondary region.

- Disaster Recovery:
  - Cloning an IoT Hub
  - Using DPS


Keep in mind to consider the devices as part of the important pieces for BC/DR
- React and Control Connectivity Events
- Retries & Considerations

## Environment Setup
1. Scripts are designed to run in bash and assume you are logged in to run az cli commands (az login).
2. Execute the `setup.env.sh` script to create the whole environment
3. Build & Deploy IoT Device Simulator by running the `build-deploy.sh` script. You will need to introduce the vm password to copy the binaries.
4. Ensure the Internet traffic is blocked from the VM by running the device simulator: `~/iot-device-simulator$ ./run-simulator.sh`, it will not be able to connect.
5. Close IoT HUB public access and configure IoT Hub Private Endpoints within the WE VNET.
    - Allow access to your IP for managing purposes.
    - Ensure you attach the **WE Private DNS records** to the VNET where the VM is deployed.
    - Now you should have access to the IoT Hub thru the private endpoint.
6. Execute the iot-device-simulator by running the `~/iot-device-simulator$ ./run-simulator.sh` now it should work thru the PE
7. Configure the IoT Edge Temperature Sensor Module for the edge101 device using the ACR deployed with the environment
    - Enable the Private Endpoint to the ACR
    - Ensure the Pivate DNS is linked to the VM VNET/SBNET to enable the resolution
    - Configure the TemperatureSensorModule pointing to the image in the environemnt ACR, for example `iotacrbcdr.azurecr.io/azureiotedge-simulated-temperature-sensor:latest`
    - You can add a "MessageCount" environment variable with -1 as value (no stop sending) or an ammount of messages to be sent high to allow the proper testing (i.e. 5000)
    - Verify the Temperature Sensor is able to send lost: `sudo iotedge logs SimulatedTemperatureSensor -f`.
        - You can verify the hub is not receiving traffic by executing `az iot hub monitor-events --output table -d edge101 -n iot-bcdr-hub -g iot-bcdr`
        - **WARN** - TO BE INVESTIGATED-: THIS POINT IS NOT TRUE, NOT SURE WHY, I EXPECT THE MODULE CAN CONTINUE SENDING TO THE EDGE HUB AND THE EDGE HUB TO STORE THE MESSAGES WHILE NOT CONNECTIVITY
        - **Anyway** the module will reconnect after the failover (edgeAgent take care of it). 
8. OPTIONAL: Verify the Temperature Sensor Module and IoT Simulated Device are sending data properly and the IoT Hub is receiving it (from your computer you can run `az iot hub monitor-events --output table -d edge101 -n iot-bcdr-hub -g iot-bcdr` ` az iot hub monitor-events --output table -d thermostat1 -n iot-bcdr-hub -g iot-bcdr`)

## TESTS
1. Fail Over with only one PE attached to WE region
    - Fail Over the IoT Hub and Check that the clients can continue sending data after a period of transient failure. 
    - The IotDeviceSimulator, which is also suscribed to the EventHubsCompatible endpoint will need an updated PE configuration to continue working. The IoTDeviceSimulator automatically resolves the EventHubs compatible endpoint connection string thru the class `IoTHubConnection`.
    - After the Fail Over, the EventHubs compatible endpoint is changed. If a client is using this compatible endpoint thru PE (which is our case), then it needs to be reconfigured to point to the new EH Compatible Endpoint, this will require to **RE-CREATE** the PE (remove and recreate).
        - **OPPORTUNITY**: Fail over doc does not mention anything regarding private link / private endpoint -> this would be an interesting topic if there are customer that are using the EH compatible endpoint thru a PE. The scenario of having devices connected to the compatible endpoint is not so common.
    - Time tracking of a FailOver with a couple of devices (few minutes after requesting the Fail Over):
        - 14:03 -> Simulated Device stops sending and stop receiving, errors appear (retry in place). Edge TempSensor also stop sending
        - 14:11 -> Simulated Device sends againg. Recive is broken (as per the EH Endpoint change). Edge takes a bit more due to the edgeAgent retries to re-start the module. 
        - 14:13 -> Remove PE from the IoT Hub, remove Nic + Private Link resources.
        - 14:16 -> Recreate PE
        - 14:18 -> Simulated Device Send and Receive working. Edge device too.

2. Fail Over from WE to NE with Network failure
     - This requires DNS configuration to use the NE VNET. So:
     - Fail over from WE to NE
     - Remove the WE PE when possible
     - Create the NE PE when possible
     - Remove the Private DNS records from the VM VNET/SNET
     - Attach the Private DNS records for the NE PE to the VM VNET/SNET 

  
## Disaster Recovery Notes
Code in ImportExportIotDevices is a sample. It has been fixed to export the device identities WITH authorization settings as explained here:  
Pay special attention to the fact that to export the identities with authentication you need to explicit specify it:
```
 var exportJob = JobProperties.CreateForExportJob(
                    _containerUri,
                    excludeKeysInExport: false,
                    devicesBlobName);
                exportJob.IncludeConfigurations = includeConfigurations;
                exportJob.ConfigurationsBlobName = configsBlobName;
                exportJob = await registryManager.ExportDevicesAsync(exportJob);
                await WaitForJobAsync(registryManager, exportJob);
```

At the same time, be conscious of storing this information which contain SECRETS. 

### Execute the tool from dotnet run:

Only Export
``` az cli
>[..] iothub-bc-dr/ImportExportIotDevices$ . env.vars.sh
>[..] iothub-bc-dr/ImportExportIotDevices$ dotnet run --ExportDevices=true --IncludeConfigurations=true
```

Export & Import
``` az cli
>[..] iothub-bc-dr/ImportExportIotDevices$ . env.vars.sh
>[..] iothub-bc-dr/ImportExportIotDevices$ dotnet run --CopyDevices=true --IncludeConfigurations=true
```

### Known Issue
If you get an 401002 error trying to import the devices from other hub, be sure your IP is whitelisted in the the Network firewall of the destination IoT Hub. An error like follows:
```
Error. Description = {"Message":"{\"errorCode\":401002,\"trackingId\":\"5a2bc7c4750f42f5aabefc0de1cd06cc-G:0-TimeStamp:02/23/2023 17:47:52\",\"message\":\"Unauthorized\",\"timestampUtc\":\"2023-02-23T17:47:52.4627397Z\"}","ExceptionMessage":""}
```

## Remarks
Be mindful this content is "under development" & "quick and dirty". 
TODO: Generate a VM pass dynamically. Now is defined in the script. Not an issue as this are transient environments.
WARN: The shell scripts use the environment variable export `SUFIX=bcdr` to create the resources. If you change it in one of the scripts, change it in all (`setup.env.sh build-deploy.sh and ./IotDeviceSimulator/env.vars.sh`)
