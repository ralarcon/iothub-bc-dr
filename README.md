# iothub-bc-dr
Business Continuity and Disaster Recover for IoT Hub

## Scenarios:
- Business Continuity:
  - IoT Hub needs to Fail Over, ensure the connectivity is maintained using the primary region PE.
  - Network disruption (I imagine a possible issue like Express Route failure / Networking outage in the primary region so they need to Fail Over the IoT Hub + configure dns resolution for the PE in the secondary region.

- Disaster Recovery:
  - Clonning an IoT Hub
  - Using DPS


Keep in mind to consider the devices as part of the important pieces for BC/DR
- React and Control Connectivity Events
- Retries & Considerations

## Environment Setup
1. Scripts are designed to run in bash and assume you are logged in to run az cli commands (az login).
2. Execute the `setup.env.sh` script to create the whole environment
3. Build & Deploy IoT Device Simulator by running the `build-deploy.sh` script. You will need to introduce the vm password to copy the binaries.
4. Configure the IoT Edge Temperature Sensor Module for the edge101 device
    - To be able to run this configuration you will need to change the NSG Rule `BlockInternetTraffic` from Deny to Allow (to enable download the containers etc.)
    - Configure the Temperature as explained [here](https://learn.microsoft.com/en-us/azure/iot-edge/quickstart-linux?view=iotedge-1.4#deploy-a-module) 
    - Disable the internet traffic from the VM by changinging the NSG Rule `BlockInternetTraffic` from Allow to Deny.
    - Restart the iotedge runtime module to reset the connection status: `sudo iotedge system restart` (if not, the module already have the connection established and the traffic is not blocked).
    - Verify the Temerature Sensor continue sending even the internet connectivity is lost: `sudo iotedge logs SimulatedTemperatureSensor -f`.
        - You can verify the hub is not receving traffic by executing `az iot hub monitor-events --output table -d edge101 -n iot-bcdr-hub -g iot-bcdr`
        - WARN - TO BE INVESTIGATED-: THIS POINT IS NOT TRUE, NOT SURE WHY, I EXPECT THE MODULE CAN CONTINUE SENDING TO THE EDGE HUB AND THE EDGE HUB TO STORE THE MESSAGES WHILE NOT CONNECTIVITY
    - Ensure the Internet traffic is blocked by running the device simulator: `~/iot-device-simulator$ ./run-simulator.sh`. 
5. Close IoT HUB public access and configure IoT Hub Private Endpoints within the WE & NE VNETS.
    - Ensure you attach the **WE Private DNS records** to the VNET where the VM is deployed.
    - Now you should have access to the IoT Hub thru the private endopoint.
6. Execute the iot-device-simulator by running the `~/iot-device-simulator$ ./run-simulator.sh`
7. Verify the Temperature Sensor Module and IoT Simulated Device are sending data properly (`az iot hub monitor-events --output table -d edge101 -n iot-bcdr-hub -g iot-bcdr` ` az iot hub monitor-events --output table -d thermostat1 -n iot-bcdr-hub -g iot-bcdr`)

## TESTS
1. Fail Over with only one PE attached to WE region
    a) Fail over the IoT Hub and Check that the clients can continue sending data after a period of transient failure
3. Fail Over with with a WE Network failure
     - This requires to set the Private DNS records of NE attached to the VNET of the VM.
  
## Disaster Recovery Notes
Code in ImportExportIotDevices is a sample. It has been fixed to export the device identities WITH authorization settings as explained here:  
Specially pay attention to the fact that to export the identities with authentication you need to explicit specify it:
```
 var exportJob = JobProperties.CreateForExportJob(
                    _containerUri,
                    **excludeKeysInExport: false**,
                    devicesBlobName);
                exportJob.IncludeConfigurations = includeConfigurations;
                exportJob.ConfigurationsBlobName = configsBlobName;
                exportJob = await registryManager.ExportDevicesAsync(exportJob);
                await WaitForJobAsync(registryManager, exportJob);
```

At the same time, be concious of storing this information which contain SECRETS. 

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
