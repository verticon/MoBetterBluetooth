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
    internal var data: [String : Any]
    
    internal init(_ data: [String : Any]) {
        self.data = data
    }
    
    // TODO: Why is the manufacturer ID being skipped?
    public var manufacturerSpecificData: [String]? {
        get {
            if let manufacturerData = data[CBAdvertisementDataManufacturerDataKey] as? Data {
                let skipManufacturerId = manufacturerData.subdata(in: 2..<(manufacturerData.count - 2))
                return dataToStringArray(skipManufacturerId)
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
                description += "\(firstEntry ? "" : ", ")\(entry.0) = "
                
                if let array = entry.1 as? Array<Any> {
                    description += "["
                    
                    var firstEntry = true
                    array.forEach { description += "\(firstEntry ? "" : ", ")\($0)"; firstEntry = false }
                    
                    description += "]"
                }
                else {
                    description += "\(entry.1)"
                }
                
                firstEntry = false
            }
            
        }
        else {
            description += "no advertisement data"
        }
        
        description += ">"
        
        return description
    }
}
