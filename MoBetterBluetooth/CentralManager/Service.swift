//
//  Service.swift
//  MoBetterBluetooth
//
//  Created by Robert Vaessen on 10/31/18.
//  Copyright © 2018 Verticon. All rights reserved.
//

import Foundation
import CoreBluetooth
import VerticonsToolbox

extension CentralManager {
    open class Service : Attribute, CustomStringConvertible {
        
        public internal(set) weak var cbService: CBService?
        public let parent: Peripheral
        open internal(set) var characteristics = [Characteristic]()
        
        public internal(set) var characteristicDiscoveryInProgress = false
        public internal(set) var characteristicsDiscovered: Bool {
            didSet {
                characteristicDiscoveryInProgress = false
            }
        }
        
        public init(cbService: CBService, id: Identifier, parent: Peripheral) {
            self.cbService = cbService
            self.parent = parent
            characteristicsDiscovered = false
            super.init(id: id)
        }
        
        public var name: String { return id.name ?? id.uuid.uuidString }
        
        public func discoverCharacteristics() -> PeripheralStatus {
            guard !(characteristicDiscoveryInProgress || characteristicsDiscovered) else { return .failure(.rediscoveryNotAllowed) }
            
            guard let service = cbService else { return .failure(.cbAttributeIsNil) }
            
            characteristicDiscoveryInProgress = true
            let uuids = parent.manager.subscription[service]?.getCharacteristicUuids()
            parent.cbPeripheral.discoverCharacteristics(uuids, for: service)
            
            return .success
        }
        
        public var description : String {
            if let service = cbService {
                var description = "\(id.name ?? "")\(service), characteristics \(characteristicsDiscovered ? "discovered, count = \(characteristics.count)" : "not discovered")"
                for characteristic in characteristics {
                    description += increaseIndent("\n\(characteristic)")
                }
                return description
            }
            return "\(name)<cbService is nil?>"
        }
        
        public subscript(characteristicId: Identifier) -> Characteristic? {
            return self[characteristicId.uuid]
        }
        
        subscript(characteristicId: CBUUID) -> Characteristic? {
            let result = characteristics.filter() { $0.id.uuid == characteristicId }
            return result.count == 1 ? result[0] : nil
        }
        
        subscript(cbCharacteristic: CBCharacteristic) -> Characteristic? {
            return self[cbCharacteristic.uuid]
        }
    }
}
