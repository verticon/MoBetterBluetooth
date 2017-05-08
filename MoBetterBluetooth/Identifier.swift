//
//  Identifier.swift
//  MoBetterBluetooth
//
//  Created by Robert Vaessen on 5/5/17.
//  Copyright © 2017 Verticon. All rights reserved.
//

import Foundation
import CoreBluetooth
import VerticonsToolbox

public struct Identifier : Encodable, CustomStringConvertible  {
    public let uuid: CBUUID
    public let name: String?
    
    public init(uuid: CBUUID, name: String?) {
        self.uuid = uuid
        self.name = name ?? nameForWellKnownUuid(uuid)
    }
    
    public init?(_ properties: Encodable.Properties?) {
        guard let properties = properties else { return nil }
        
        if  let name = properties["name"] as? String,
            let uuid = properties["uuid"] as? String {
            self.name = name
            self.uuid = CBUUID(string: uuid)
        } else {
            return nil
        }
    }
    
    public func encode() -> Encodable.Properties {
        return ["name": name ?? "", "uuid": uuid.uuidString]
    }
    
    public var description : String {
        return "<\(name ?? "<no name>"), \(uuid.uuidString)>"
    }
}

extension Identifier : Equatable {
    public static func == (lhs: Identifier, rhs: Identifier) -> Bool {
        return lhs.uuid == rhs.uuid
    }
}
