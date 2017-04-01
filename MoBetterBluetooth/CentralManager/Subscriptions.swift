//
//  Subscription.swift
//  Toolbox
//
//  Created by Robert Vaessen on 10/30/16.
//  Copyright © 2016 Robert Vaessen. All rights reserved.
//

import UIKit
import CoreBluetooth
import VerticonsToolbox

extension CentralManager {

    public struct Identifier : Encodable  {
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
    }

    public struct CharacteristicSubscription : Encodable {
        public let id: Identifier
        public let discoverDescriptors: Bool

        public init(id: Identifier, discoverDescriptors: Bool) {
            self.id = id
            self.discoverDescriptors = discoverDescriptors
        }

        public init?(_ properties: Encodable.Properties?) {
            guard let properties = properties else { return nil }

            if  let id = Identifier(properties["id"] as? Encodable.Properties),
                let discover = properties["discover"] as? Bool {
                self.id = id
                self.discoverDescriptors = discover
            } else {
                return nil
            }
        }
        
        public func encode() -> Encodable.Properties {
            return ["id": id.encode(), "discover": discoverDescriptors]
        }
    }

    public struct ServiceSubscription : Encodable {
        public let id: Identifier
        public var characteristics: [CharacteristicSubscription] // If empty then all of the service's characteristics and descriptors will be discovered
        
        public init(id: Identifier, characteristics: [CharacteristicSubscription] = []) {
            self.id = id
            self.characteristics = characteristics
        }

        public init?(_ properties: Encodable.Properties?) {
            guard let properties = properties else { return nil }

            if  let id = Identifier(properties["id"] as? Encodable.Properties),
                let characteristics = properties["characteristics"] as? [Encodable.Properties] {
                self.id = id
                self.characteristics = characteristics.decode(type: CharacteristicSubscription.self)
            } else {
                return nil
            }
        }
        
        public func encode() -> Encodable.Properties {
            return ["id": id.encode(), "characteristics": characteristics.encode()]
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

    public struct PeripheralSubscription : Encodable {
        public let name: String
        public var services: [ServiceSubscription] // If empty then all of the peripheral's services, characteristics and descriptors will be discovered
   
        public init(name: String, services: [ServiceSubscription] = []) {
            self.name = name
            self.services = services
        }
        
        public init?(_ properties: Encodable.Properties?) {
            guard let properties = properties else { return nil }
            
            if  let name = properties["name"] as? String,
                let services = properties["services"] as? [Encodable.Properties] {
                self.name = name
                self.services = services.decode(type: ServiceSubscription.self)
            } else {
                return nil
            }
        }
        
        public func encode() -> Encodable.Properties {
            return ["name": name, "services": services.encode()]
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

extension Array where Element == Encodable.Properties {
    func decode<T:Encodable>(type: T.Type) -> [T] {
        return flatMap{ T($0) }
    }
}

extension Array where Element : Encodable {
    func encode() -> [Encodable.Properties] {
        return map{ $0.encode() }
    }
}
