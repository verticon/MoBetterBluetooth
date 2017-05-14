//
//  Advertisement.swift
//  MoBetterBluetooth
//
//  Created by Robert Vaessen on 4/14/17.
//  Copyright © 2017 Verticon. All rights reserved.
//

import Foundation
import CoreBluetooth
import VerticonsToolbox

public struct Advertisement : CustomStringConvertible {
    public internal(set) var data: [String : Any]
    
    internal init(_ data: [String : Any]) {
        self.data = data
    }
    
    // TODO: Why is the manufacturer ID being skipped?
    public var manufacturerSpecificData: [String]? {
        get {
            if let manufacturerData = data[CBAdvertisementDataManufacturerDataKey] as? Data {
                let skipManufacturerId = manufacturerData.subdata(in: 2..<(manufacturerData.count - 2))
                return skipManufacturerId.toStringArray()
            }
            return nil
        }
    }
    
    public var isConnectable: Bool {
        return data[CBAdvertisementDataIsConnectable] as? Bool ?? false
    }
    
    public var description : String {
        var description = "<"
        
        if data.count > 0 {
            var firstEntry = true
            for entry in data {
                description += "\(firstEntry ? "" : ", ")\(describeEntry(entry))"
                firstEntry = false
            }
        }
        else {
            description += "no advertisement data"
        }
        
        description += ">"
        
        return description
    }
    
    public func describeEntry(_ entry: (key: String, value: Any)) -> String {

        let keyDesc: String
        switch entry.key {
        case CBAdvertisementDataLocalNameKey:
            keyDesc = "Local Name"
        case CBAdvertisementDataIsConnectable:
            keyDesc = "Connectable"
        case CBAdvertisementDataServiceDataKey:
            keyDesc = "Service Data"
        case CBAdvertisementDataServiceUUIDsKey:
            keyDesc = "Service UUIDs"
        case CBAdvertisementDataTxPowerLevelKey:
            keyDesc = "Power Level"
        case CBAdvertisementDataManufacturerDataKey:
            keyDesc = "Manufacturer Data"
        case CBAdvertisementDataOverflowServiceUUIDsKey:
            keyDesc = "Overflow  Service UUIDs"
        case CBAdvertisementDataSolicitedServiceUUIDsKey:
            keyDesc = "Solicited Service UUIDs"
        default:
            keyDesc = "\(entry.key)"
        }

        var valueDesc: String
        if let array = entry.value as? Array<Any> {
            valueDesc = "["
            
            var firstEntry = true
            array.forEach { valueDesc += "\(firstEntry ? "" : ", ")\($0)"; firstEntry = false }
            
            valueDesc += "]"
        }
        else {
            valueDesc = "\(entry.value)"
        }

        return keyDesc + ": " + valueDesc
    }
}
