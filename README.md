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

