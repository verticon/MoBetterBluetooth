//
//  Bluetooth.swift
//
//  Created by Robert Vaessen on 12/28/15.
//  Copyright © 2015 Robert Vaessen. All rights reserved.
//

import UIKit
import CoreLocation
import CoreBluetooth
import VerticonsToolbox

extension CBManagerState{
    var name: String {
        switch self {
        case .poweredOn:
            return "PoweredOn"
        case .poweredOff:
            return "PoweredOff"
        case .resetting:
            return "Resetting"
        case .unauthorized:
            return "Unauthorized"
        case .unknown:
            return "Unknown"
        case .unsupported:
            return "Unsupported"
        }
    }
}

extension CBPeripheralState {
    var name: String {
        switch self {
        case .connecting: return "Connecting"
        case .connected: return "Connected"
        case .disconnecting: return "Disconnecting"
        case .disconnected: return "Disconnected"
        }
    }
}

public let CBUUIDDeviceInformationServiceString = "180A"
public let DeviceInformationServiceUUID = CBUUID(string: CBUUIDDeviceInformationServiceString)
public let CBUUIDSystemIDCharacteristicString = "2A23"
public let SystemIDCharacteristicUUID = CBUUID(string: CBUUIDSystemIDCharacteristicString)
public let CBUUIDModelNumberCharacteristicString = "2A24"
public let ModelNumberCharacteristicUUID = CBUUID(string: CBUUIDModelNumberCharacteristicString)
public let CBUUIDSerialNumberCharacteristicString = "2A25"
public let SerialNumberCharacteristicUUID = CBUUID(string: CBUUIDSerialNumberCharacteristicString)
public let CBUUIDFirmwareRevisionCharacteristicString = "2A26"
public let FirmwareRevisionCharacteristicUUID = CBUUID(string: CBUUIDFirmwareRevisionCharacteristicString)
public let CBUUIDHardwareRevisionCharacteristicString = "2A27"
public let HardwareRevisionCharacteristicUUID = CBUUID(string: CBUUIDHardwareRevisionCharacteristicString)
public let CBUUIDSoftwareRevisionCharacteristicString = "2A28"
public let SoftwareRevisionCharacteristicUUID = CBUUID(string: CBUUIDSoftwareRevisionCharacteristicString)
public let CBUUIDManufacturerNameCharacteristicString = "2A29"
public let ManufacturerNameCharacteristicUUID = CBUUID(string: CBUUIDManufacturerNameCharacteristicString)
public let CBUUIDPnPIDCharacteristicString = "2A50"
public let PnPIDCharacteristicUUID = CBUUID(string: CBUUIDPnPIDCharacteristicString)

public let CBUUIDCurrentTimeServiceString = "1805"
public let CurrentTimeServiceUUID = CBUUID(string: CBUUIDCurrentTimeServiceString)
public let CBUUIDCurrentTimeCharacteristicString = "2A2B"
public let CurrentTimeCharacteristicUUID = CBUUID(string: CBUUIDCurrentTimeCharacteristicString)
public let CBUUIDLocalTimeCharacteristicString = "2A0F"
public let LocalTimeCharacteristicUUID = CBUUID(string: CBUUIDLocalTimeCharacteristicString)

public let CBUUIDHeartRateServiceString = "180D"
public let HeartRateServiceUUID = CBUUID(string: CBUUIDHeartRateServiceString)
public let CBUUIDHeartRateMeasurementCharacteristicString = "2A37"
public let HeartRateMeasurementCharacteristicUUID = CBUUID(string: CBUUIDHeartRateMeasurementCharacteristicString)
public let CBUUIDSensorBodyLocationCharacteristicString = "2A38"
public let SensorBodyLocationCharacteristicUUID = CBUUID(string: CBUUIDSensorBodyLocationCharacteristicString)
public let CBUUIDHeartRateControlPointCharacteristicString = "2A39"
public let HeartRateControlPointCharacteristicUUID = CBUUID(string: CBUUIDHeartRateControlPointCharacteristicString)

public let CBUUIDBatteryServiceString = "180F"
public let BatteryServiceUUID = CBUUID(string: CBUUIDBatteryServiceString)
public let CBUUIDBatteryLevelCharacteristicString = "2A19"
public let BatteryLevelCharacteristicUUID = CBUUID(string: CBUUIDBatteryLevelCharacteristicString)

public let CharacteristicExtendedPropertiesUUID = CBUUID(string: CBUUIDCharacteristicExtendedPropertiesString)
public let CharacteristicUserDescriptionUUID = CBUUID(string: CBUUIDCharacteristicUserDescriptionString)
public let ClientCharacteristicConfigurationUUID = CBUUID(string: CBUUIDClientCharacteristicConfigurationString)
public let ServerCharacteristicConfigurationUUID = CBUUID(string: CBUUIDServerCharacteristicConfigurationString)
public let CharacteristicFormatUUID = CBUUID(string: CBUUIDCharacteristicFormatString)
public let CharacteristicAggregateFormatUUID = CBUUID(string: CBUUIDCharacteristicAggregateFormatString)


private let uuidMappings = [
    DeviceInformationServiceUUID : "Device Information",
    SystemIDCharacteristicUUID : "System ID",
    ModelNumberCharacteristicUUID : "Model Number",
    SerialNumberCharacteristicUUID : "Serial Number",
    FirmwareRevisionCharacteristicUUID : "Firmware Revision",
    HardwareRevisionCharacteristicUUID : "Hardware Revision",
    SoftwareRevisionCharacteristicUUID : "Software Revision",
    ManufacturerNameCharacteristicUUID : "Manufacturer Name",
    PnPIDCharacteristicUUID : "PnP ID",

    CurrentTimeServiceUUID : "Current Time",
    CurrentTimeCharacteristicUUID : "Current Time",
    LocalTimeCharacteristicUUID : "Local Time",

    HeartRateServiceUUID : "Heart Rate",
    HeartRateMeasurementCharacteristicUUID : "Heart Rate Measurement",
    SensorBodyLocationCharacteristicUUID : "Sensor Body Location",
    HeartRateControlPointCharacteristicUUID : "Heart Rate Control Point",

    BatteryServiceUUID : "Battery",
    BatteryLevelCharacteristicUUID : "Battery Level",

    
    CharacteristicExtendedPropertiesUUID : "Extended Properties", // 2900
    CharacteristicUserDescriptionUUID : "User Description", // 2901
    ClientCharacteristicConfigurationUUID : "Client Configuration", // 2902
    ServerCharacteristicConfigurationUUID : "Server Configuration", // 2903
    CharacteristicFormatUUID : "Format", // 2904
    CharacteristicAggregateFormatUUID : "Aggregate Format", // 2905
]

public func nameForWellKnownUuid(_ uuid: CBUUID) -> String? {
    return uuidMappings[uuid]
}
