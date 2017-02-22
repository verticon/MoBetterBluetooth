//
//  Bluetooth.swift
//
//  Created by Robert Vaessen on 12/28/15.
//  Copyright © 2015 Robert Vaessen. All rights reserved.
//

import UIKit
import CoreLocation
import CoreBluetooth

public func nameForAuthorizationStatus(_ status: CLAuthorizationStatus) -> String {
    switch status {
    case CLAuthorizationStatus.authorizedAlways: return "AuthorizedAlways"
    case CLAuthorizationStatus.authorizedWhenInUse: return "AuthorizedWhenInUse"
    case CLAuthorizationStatus.denied: return "Denied"
    case CLAuthorizationStatus.notDetermined: return "NotDetermined"
    case CLAuthorizationStatus.restricted: return "Restricted"
    }
}

public func nameForProximity(_ proximity: CLProximity) -> String {
    switch(proximity) {
    case .immediate: return "Immediate"
    case .near: return "Near"
    case .far: return "Far"
    case .unknown: return "Unknown"
    }
}

public func nameForRegionState(_ state: CLRegionState) -> String {
    switch state {
    case CLRegionState.unknown: return "Unknown"
    case CLRegionState.inside: return "Inside"
    case CLRegionState.outside: return "Outside"
    }
}

public func nameForCBManagerState(_ state: CBManagerState) -> String {
    switch state {
    case CBManagerState.poweredOn:
        return "PoweredOn"
    case CBManagerState.poweredOff:
        return "PoweredOff"
    case CBManagerState.resetting:
        return "Resetting"
    case CBManagerState.unauthorized:
        return "Unauthorized"
    case CBManagerState.unknown:
        return "Unknown"
    case CBManagerState.unsupported:
        return "Unsupported"
    }
}

public func decodeManufacturerSpecificData(advertisementData data: [String : AnyObject]) -> [String]? {
    if let manufacturerData = data[CBAdvertisementDataManufacturerDataKey] as? Data {
        let skipManufacturerId = manufacturerData.subdata(in: 2..<(manufacturerData.count - 2))
        return dataToStringArray(skipManufacturerId)
    }
    return nil
}

public func isConnectable(_ advertisementData: [String : AnyObject]) -> Bool {
    if let isConnectable = advertisementData[CBAdvertisementDataIsConnectable] as? Bool {
        return isConnectable
    }
    return false
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

    HeartRateServiceUUID : "Heart Rate",
    HeartRateMeasurementCharacteristicUUID : "Heart Rate Measurement",
    SensorBodyLocationCharacteristicUUID : "Sensor Body Location",
    HeartRateControlPointCharacteristicUUID : "Heart Rate Control Point",

    BatteryServiceUUID : "Battery",
    BatteryLevelCharacteristicUUID : "Battery Level",

    
    CharacteristicExtendedPropertiesUUID : "Characteristic Extended Properties", // 2900
    CharacteristicUserDescriptionUUID : "User Description", // 2901
    ClientCharacteristicConfigurationUUID : "Client Characteristic Configuration", // 2902
    ServerCharacteristicConfigurationUUID : "Server Characteristic Configuration", // 2903
    CharacteristicFormatUUID : "Characteristic Format", // 2904
    CharacteristicAggregateFormatUUID : "Characteristic Aggregate Format", // 2905
]

public func nameForWellKnownUuid(_ uuid: CBUUID) -> String? {
    return uuidMappings[uuid]
}
