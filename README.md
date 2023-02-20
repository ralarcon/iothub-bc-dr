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
