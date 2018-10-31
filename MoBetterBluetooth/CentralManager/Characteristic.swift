//
//  Characteristic.swift
//  MoBetterBluetooth
//
//  Created by Robert Vaessen on 10/31/18.
//  Copyright © 2018 Verticon. All rights reserved.
//

import Foundation
import CoreBluetooth
import VerticonsToolbox

extension CentralManager {
    open class Characteristic : Attribute, CustomStringConvertible {
        
        public struct Properties {
            
            public struct Property {
                let property: CBCharacteristicProperties
                let name: String
                let isEnabled: Bool
            }
            
            public let properties: [Property]
            
            init(cbCharacteristic: CBCharacteristic) {
                var properties = [Property]()
                properties.append(Property(property: .broadcast, name: "Broadcast", isEnabled: cbCharacteristic.properties.contains(.broadcast) ? true : false))
                properties.append(Property(property: .read, name: "Read", isEnabled: cbCharacteristic.properties.contains(.read) ? true : false))
                properties.append(Property(property: .writeWithoutResponse, name: "Write w/o Response", isEnabled: cbCharacteristic.properties.contains(.writeWithoutResponse) ? true : false))
                properties.append(Property(property: .write, name: "Write", isEnabled: cbCharacteristic.properties.contains(.write) ? true : false))
                properties.append(Property(property: .notify, name: "Notify", isEnabled: cbCharacteristic.properties.contains(.notify) ? true : false))
                properties.append(Property(property: .indicate, name: "Indicate", isEnabled: cbCharacteristic.properties.contains(.indicate) ? true : false))
                properties.append(Property(property: .authenticatedSignedWrites, name: "Auth Signed Writes", isEnabled: cbCharacteristic.properties.contains(.authenticatedSignedWrites) ? true : false))
                properties.append(Property(property: .extendedProperties, name: "Extended Properties", isEnabled: cbCharacteristic.properties.contains(.extendedProperties) ? true : false))
                properties.append(Property(property: .notifyEncryptionRequired, name: "Notify Encypt Req", isEnabled: cbCharacteristic.properties.contains(.notifyEncryptionRequired) ? true : false))
                properties.append(Property(property: .indicateEncryptionRequired, name: "Indicate Encrypt Req", isEnabled: cbCharacteristic.properties.contains(.indicateEncryptionRequired) ? true : false))
                self.properties = properties
            }
            
            public var all: [String] {
                return properties.map{ $0.name + " : " + ($0.isEnabled ? "yes" : "no") }
            }
            
            public var enabled: [String] {
                return properties.filter{ $0.isEnabled }.map{ $0.name }
            }
        }
        public private(set) var properties: Properties
        
        public internal(set) weak var cbCharacteristic : CBCharacteristic? // TODO: Revisit the need for the cbCharacteristic reference to be weak
        public let parent: Service
        public internal(set) var descriptors = [Descriptor]()
        
        public internal(set) var descriptorDiscoveryInProgress = false
        public internal(set) var descriptorsDiscovered: Bool {
            didSet {
                descriptorDiscoveryInProgress = false
            }
        }
        
        public init(cbCharacteristic: CBCharacteristic, id: Identifier, parent: Service) {
            self.cbCharacteristic = cbCharacteristic
            self.parent = parent
            descriptorsDiscovered = false
            properties = Properties(cbCharacteristic: cbCharacteristic)
            super.init(id: id)
        }
        
        public var name: String {
            if let name = id.name { return name }
            for descriptor in descriptors {
                if descriptor.id.uuid.uuidString == CharacteristicUserDescriptionUUID.uuidString { return descriptor.cbDescriptor?.value as? String ?? id.uuid.uuidString }
            }
            return id.uuid.uuidString
        }
        
        public func discoverDescriptors() -> PeripheralStatus {
            guard !(descriptorDiscoveryInProgress || descriptorsDiscovered) else { return .failure(.rediscoveryNotAllowed) }
            
            guard let characteristic = cbCharacteristic else { return .failure(.cbAttributeIsNil) }
            
            descriptorDiscoveryInProgress = true
            parent.parent.cbPeripheral.discoverDescriptors(for: characteristic)
            
            return .success
        }
        
        public var description : String {
            if let characteristic = cbCharacteristic {
                let properties = self.properties.enabled.reduce(""){ $0 + ($0.isEmpty ? "" : "|" ) + $1 }
                var description = "\(id.name ?? "")\(characteristic), Properties = \(properties), descriptors \(descriptorsDiscovered ? "discovered, count = \(descriptors.count)" : "not discovered")"
                for descriptor in descriptors {
                    description += increaseIndent("\n\(descriptor)")
                }
                return description
            }
            return "\(name)<cbCharacteristic is nil?>"
        }
        
        public subscript(descriptorId: Identifier) -> Descriptor? {
            return self[descriptorId.uuid]
        }
        
        subscript(descriptorId: CBUUID) -> Descriptor? {
            let result = descriptors.filter() { $0.id.uuid == descriptorId }
            return result.count == 1 ? result[0] : nil
        }
        
        subscript(cbDescriptor: CBDescriptor) -> Descriptor? {
            return self[cbDescriptor.uuid]
        }
        
        // ************************** Reading ******************************
        
        public enum ReadResult {
            case success(Data)
            case failure(PeripheralError)
        }
        
        public typealias ReadCompletionHandler = (ReadResult) -> Void
        private var readCompletionHandler: ReadCompletionHandler?
        
        public var isReadable : Bool {
            return cbCharacteristic?.properties.contains(CBCharacteristicProperties.read) ?? false
        }
        
        public func read(_ completionHandler: @escaping ReadCompletionHandler) -> PeripheralStatus {
            guard let characteristic = cbCharacteristic else { return .failure(.cbAttributeIsNil) }
            
            guard isReadable else { return .failure(.notReadable) }
            
            guard readCompletionHandler == nil else { return .failure(.readInProgress) }
            readCompletionHandler = completionHandler
            parent.parent.cbPeripheral.readValue(for: characteristic)
            
            return .success
        }
        
        // The Central Manager will call this method when an asynchronous read has completed.
        // The Central Manager also calls this method when a notification is received.
        // AFAIK CoreBluetooth does not provide a way to distinguish between a read completed
        // and a notification.
        //
        // If notifications are enabled then performing a read will result in the notification
        // handler being invoked even though the peripheral has not produced a new value. This
        // method takes steps to handle that situation.
        func readCompleted(_ value : Data?, cbError: Error?) {
            
            let result: ReadResult
            if let error = cbError {
                result = .failure(.characteristicReadError(self, cbError: error))
            } else {
                result = .success(value!)
            }
            
            // TODO: Reconsider whether or not the following logic works if a read is issued
            // by the central "at the same time" that a notification is being produced by the
            // peripheral. The assumption is that two events will produced. Consider that the
            // timing is such that the read completion handler receives the notification data
            // and the notification handler receives the read result.
            if let handler = readCompletionHandler {
                readCompletionHandler = nil // Do this first so that the handler can initiate a new read if desired.
                handler(result)
            }
            else if let handler = notificationHandler {
                handler(result)
            }
            else {
                fatalError("Read completed method invoked but both completion handlers are nil???")
            }
        }
        
        // ************************** Writing ******************************
        
        public typealias WriteCompletionHandler = (PeripheralStatus) -> Void
        private var writeCompletionHandler: WriteCompletionHandler?
        
        public var isWriteable : Bool {
            return cbCharacteristic?.properties.contains(CBCharacteristicProperties.write) ?? false
        }
        
        public func write(_ value: Data, completionHandler: @escaping WriteCompletionHandler) -> PeripheralStatus {
            guard isWriteable else { return .failure(.notWriteable) }
            
            guard writeCompletionHandler == nil else { return .failure(.writeInProgress) }
            
            guard let characteristic = cbCharacteristic else { return .failure(.cbAttributeIsNil) }
            
            writeCompletionHandler = completionHandler
            
            parent.parent.cbPeripheral.writeValue(value, for: characteristic, type: CBCharacteristicWriteType.withResponse)
            
            return .success
        }
        
        // The Central Manager will call this method when the asynchronous write has completed.
        func writeCompleted(cbError: Error?) {
            guard let handler = writeCompletionHandler else {
                fatalError("Write completed method invoked but completion handler is nil???")
            }
            
            writeCompletionHandler = nil // Do this first so that the handler can initiate a new write if desired.
            
            if let error = cbError {
                handler(.failure(.characteristicWriteError(self, cbError: error)))
            }
            else {
                handler(.success)
            }
        }
        
        // ************************** Notifying ******************************
        
        private var notificationHandler: ReadCompletionHandler?
        
        public var isNotifiable : Bool {
            return cbCharacteristic?.properties.contains(CBCharacteristicProperties.notify) ?? false
        }
        
        public var isNotifying : Bool {
            return cbCharacteristic?.isNotifying ?? false
        }
        
        // If enabled is true then handler must not be nil. If enabled is false then handler is ignored.
        public func notify(enabled: Bool, handler: ReadCompletionHandler?) -> PeripheralStatus {
            guard isNotifiable else { return .failure(.notNotifiable) }
            
            guard let characteristic = cbCharacteristic else { return .failure(.cbAttributeIsNil) }
            
            if enabled {
                if handler == nil { return .failure(.handlerCannotBeNil) }
                notificationHandler = handler
            }
            else {
                notificationHandler = nil
            }
            
            parent.parent.cbPeripheral.setNotifyValue(enabled, for: characteristic)
            
            return .success
        }
        
        // The Central Manager will call this method when the asynchronous notification state update
        // has completed.
        func setNotificationStateCompleted(value: Bool, cbError: Error?) {
            if let error = cbError {
                notificationHandler!(.failure(.characteristicNotifyError(self, cbError: error)))
                notificationHandler = nil
                return
            }
        }
    }
}
