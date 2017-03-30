//
//  Subscription.swift
//  Toolbox
//
//  Created by Robert Vaessen on 10/30/16.
//  Copyright © 2016 Robert Vaessen. All rights reserved.
//

import UIKit
import CoreBluetooth

extension CentralManager {

    public struct Identifier {
        public let uuid: CBUUID
        public let name: String?
        
        public init(uuid: CBUUID, name: String?) {
            self.uuid = uuid
            self.name = name ?? nameForWellKnownUuid(uuid)
        }
    }

    public struct CharacteristicSubscription {
        public let id: Identifier
        public let discoverDescriptors: Bool

        public init(id: Identifier, discoverDescriptors: Bool) {
            self.id = id
            self.discoverDescriptors = discoverDescriptors
        }
    }

    public struct ServiceSubscription {
        public let id: Identifier
        public var characteristics: [CharacteristicSubscription] // If empty then all of the service's characteristics and descriptors will be discovered
        
        public init(id: Identifier, characteristics: [CharacteristicSubscription] = []) {
            self.id = id
            self.characteristics = characteristics
        }

        subscript(characteristicId: CBUUID) -> CharacteristicSubscription? {
            let result = characteristics.filter() { $0.id.uuid == characteristicId }
            return result.count == 1 ? result[0] : nil
        }
        
        subscript(cbCharacteristic: CBCharacteristic) -> CharacteristicSubscription? {
            return self[cbCharacteristic.uuid]
        }
        
        func match(_ cbCharacteristic: CBCharacteristic) -> Identifier? {
            if characteristics.isEmpty {
                return Identifier(uuid: cbCharacteristic.uuid, name: nil)
            }
            if let subscription = self[cbCharacteristic] {
                return subscription.id
            }
            return nil
        }
        
        func getCharacteristicUuids() -> [CBUUID]? {
            return characteristics.isEmpty ? nil : characteristics.map() { $0.id.uuid }
        }
    }

    public struct PeripheralSubscription {
        public var services: [ServiceSubscription] // If empty then all of the peripheral's services, characteristics and descriptors will be discovered
   
        public init(services: [ServiceSubscription] = []) {
            self.services = services
        }

        subscript(serviceId: CBUUID) -> ServiceSubscription? {
            let result = services.filter() { $0.id.uuid == serviceId }
            return result.count == 1 ? result[0] : nil
        }
        
        subscript(cbService: CBService) -> ServiceSubscription? {
            return self[cbService.uuid]
        }
        
        func match(_ cbService: CBService) -> Identifier? {
            if services.isEmpty {
                return Identifier(uuid: cbService.uuid, name: nil)
            }
            if let subscription = self[cbService] {
                return subscription.id
            }
            return nil
        }
        
        func match(_ cbCharacteristic: CBCharacteristic, of cbService: CBService) -> Identifier? {
            if services.isEmpty {
                return Identifier(uuid: cbCharacteristic.uuid, name: nil)
            }
            if let subscription = self[cbService] {
                return subscription.match(cbCharacteristic)
            }
            return nil
        }
        
        func getServiceUuids() -> [CBUUID]? {
            return services.isEmpty ? nil : services.map() { $0.id.uuid }
        }
    }
}

extension CentralManager.Identifier : Equatable {
    public static func == (lhs: CentralManager.Identifier, rhs: CentralManager.Identifier) -> Bool {
        return lhs.uuid == rhs.uuid
    }
}
