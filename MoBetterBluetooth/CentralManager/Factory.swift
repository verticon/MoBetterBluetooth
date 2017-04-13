//
//  Factory
//  MoBetterBluetooth
//
//  Created by Robert Vaessen on 10/30/16.
//  Copyright © 2016 Robert Vaessen. All rights reserved.
//

import UIKit
import CoreBluetooth
import VerticonsToolbox


public protocol CentralManagerTypesFactory {
    func makePeripheral(for cbPeripheral: CBPeripheral, manager: CentralManager, advertisementData: [String : Any]) -> CentralManager.Peripheral
    func makeService(for cbService: CBService, id: CentralManager.Identifier, parent: CentralManager.Peripheral) -> CentralManager.Service
    func makeCharacteristic(for cbCharacteristic: CBCharacteristic, id: CentralManager.Identifier, parent: CentralManager.Service) -> CentralManager.Characteristic
    func makeDescriptor(for cbDescriptor: CBDescriptor, id: CentralManager.Identifier, parent: CentralManager.Characteristic) -> CentralManager.Descriptor
}

extension CentralManagerTypesFactory {
    public func makePeripheral(for cbPeripheral: CBPeripheral, manager: CentralManager, advertisementData: [String : Any]) -> CentralManager.Peripheral {
        return CentralManager.Peripheral(cbPeripheral: cbPeripheral, manager: manager, advertisementData: advertisementData)
    }
    
    public func makeService(for cbService: CBService, id: CentralManager.Identifier, parent: CentralManager.Peripheral) -> CentralManager.Service {
        return CentralManager.Service(cbService: cbService, id: id, parent: parent)
    }
    
    public func makeCharacteristic(for cbCharacteristic: CBCharacteristic, id: CentralManager.Identifier, parent: CentralManager.Service) -> CentralManager.Characteristic {
        return CentralManager.Characteristic(cbCharacteristic: cbCharacteristic, id: id, parent: parent)
    }
    
    public func makeDescriptor(for cbDescriptor: CBDescriptor, id: CentralManager.Identifier, parent: CentralManager.Characteristic) -> CentralManager.Descriptor {
        return CentralManager.Descriptor(cbDescriptor: cbDescriptor, id: id, parent: parent)
    }
}

extension CentralManager {

    open class Peripheral : Broadcaster<PeripheralEvent>, CustomStringConvertible {
        
        public let cbPeripheral: CBPeripheral
        public let manager: CentralManager
        public let advertisementData: [String : Any]
        public internal(set) var services = [Service]()

        var servicesDiscovered = false


        public init(cbPeripheral: CBPeripheral, manager: CentralManager, advertisementData: [String : Any]) {
            self.cbPeripheral = cbPeripheral
            self.manager = manager
            self.advertisementData = advertisementData
        }

        public var name: String {
            return cbPeripheral.name ?? cbPeripheral.identifier.uuidString
        }

        public var description : String {
            var description = "\(cbPeripheral)\n"
            
            description += "Advertisement Data:\n"
            for entry in advertisementData {
                let value = "\(entry.1)".replacingOccurrences(of: "\n", with: "\n\t") // When the value is an array the default string interpolation is not pretty
                description += "\t\(entry.0) = \(value)\n"
            }
            
            if cbPeripheral.state == .connected {
                description += "Services:\n"
                for service in services {
                    description += increaseIndent("\(service)")
                }
            }

            return description
        }
        
        public var connectable: Bool {
            return isConnectable(advertisementData)
        }
        
        internal var connectCompletionhandler: ((Peripheral, CentralManagerStatus) -> Void)?
        public func connect(completionhandler: @escaping (Peripheral, CentralManagerStatus) -> Void) -> PeripheralStatus {
            guard connectable else {  return .failure(.notConnectable) }
            guard cbPeripheral.state == .disconnected else {  return .failure(.notDisconnected) }
            
            connectCompletionhandler = completionhandler
            manager.cbManager.connect(cbPeripheral, options: nil)
            
            sendEvent(.stateChanged(self)) // disconnected => connecting

            return .success
        }
        
        internal var disconnectCompletionhandler: ((Peripheral, CentralManagerStatus) -> Void)?
        public func disconnect(completionhandler: @escaping (Peripheral, CentralManagerStatus) -> Void) -> PeripheralStatus {
            guard cbPeripheral.state == .connected else {  return .failure(.notConnected) }
            
            disconnectCompletionhandler = completionhandler
            manager.cbManager.cancelPeripheralConnection(cbPeripheral)
            
            sendEvent(.stateChanged(self)) // connected => disconnecting

            return .success
        }
        
        internal func sendEvent(_ event: PeripheralEvent) {
            broadcast(event)
        }
        
        public subscript(serviceId: Identifier) -> Service? {
            return self[serviceId.uuid]
        }
        
        subscript(serviceId: CBUUID) -> Service? {
            let result = services.filter() { $0.id.uuid == serviceId }
            return result.count == 1 ? result[0] : nil
        }
        
        subscript(cbService: CBService) -> Service? {
            return self[cbService.uuid]
        }
    }

    open class Service : CustomStringConvertible {

        public let id: Identifier
        public let cbService: CBService
        public let parent: Peripheral
        public internal(set) var characteristics = [Characteristic]()

        var characteristicsDiscovered = false

        public init(cbService: CBService, id: Identifier, parent: Peripheral) {
            self.cbService = cbService
            self.id = id
            self.parent = parent
        }

        public var name: String { return id.name ?? id.uuid.uuidString }

        public var description : String {
            var description = "\(cbService) has \(characteristics.count) characteristics\n"
            for characteristic in characteristics {
                description += increaseIndent("\(characteristic)")
            }
            return description
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

    open class Characteristic : CustomStringConvertible {
        
        public let id: Identifier
        public let cbCharacteristic : CBCharacteristic
        public let parent: Service
        public internal(set) var descriptors = [Descriptor]()

        var descriptorsDiscovered = false
        
        public init(cbCharacteristic: CBCharacteristic, id: Identifier, parent: Service) {
            self.id = id
            self.cbCharacteristic = cbCharacteristic
            self.parent = parent
        }
        
        public var name: String { return id.name ?? id.uuid.uuidString }
        
        public var description : String {
            return "\(cbCharacteristic) has \(descriptors.count) descriptors\n"
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
        
        public var readable : Bool {
            return cbCharacteristic.properties.contains(CBCharacteristicProperties.read)
        }
        
        public func read(_ completionHandler: @escaping ReadCompletionHandler) -> PeripheralStatus {
            guard readable else { return .failure(.notReadable(self)) }

            guard readCompletionHandler == nil else { return .failure(.readInProgress(self)) }

            readCompletionHandler = completionHandler

            parent.parent.cbPeripheral.readValue(for: cbCharacteristic)

            return .success
        }
        
        // The Central Manager will call this method when an asynchronous read has completed.
        // The Central Manager will also call this method when a notification is received.
        //
        // I wish that there were a way to distingush read completion from notification.
        open func readCompleted(_ value : Data?, cbError: Error?) {
            guard readCompletionHandler != nil || notificationHandler != nil else {
                fatalError("Read completed method invoked but both completion handlers are nil???")
            }
            
            let result: ReadResult
            if let error = cbError {
                result = .failure(.readError(self, cbError: error))
            } else {
                result = .success(value!)
            }

            if let handler = readCompletionHandler {
                readCompletionHandler = nil // Do this first so that the handler can initiate a new read if desired.
                handler(result)
            }

            if let handler = notificationHandler, case ReadResult.success = result {
                handler(result)
            }
        }
        
        // ************************** Writing ******************************
        
        public typealias WriteCompletionHandler = (PeripheralStatus) -> Void
        private var writeCompletionHandler: WriteCompletionHandler?

        public var writeable : Bool {
            return cbCharacteristic.properties.contains(CBCharacteristicProperties.write)
        }
        
        public func write(_ value: Data, completionHandler: @escaping WriteCompletionHandler) -> PeripheralStatus {
            guard writeable else { return .failure(.notWriteable(self)) }
            
            guard writeCompletionHandler == nil else { return .failure(.writeInProgress(self)) }
            
            writeCompletionHandler = completionHandler

            parent.parent.cbPeripheral.writeValue(value, for: cbCharacteristic, type: CBCharacteristicWriteType.withResponse)

            return .success
        }
        
        // The Central Manager will call this method when the asynchronous write has completed.
        open func writeCompleted(cbError: Error?) {
            guard let handler = writeCompletionHandler else {
                fatalError("Write completed method invoked but completion handler is nil???")
            }

            writeCompletionHandler = nil // Do this first so that the handler can initiate a new write if desired.
            
            if let error = cbError {
                handler(.failure(.writeError(self, cbError: error)))
            }
            else {
                handler(.success)
            }
        }
        
        // ************************** Notifying ******************************
        
        private var notificationHandler: ReadCompletionHandler?

        public var notifiable : Bool {
            return cbCharacteristic.properties.contains(CBCharacteristicProperties.notify)
        }
        
        // If enabled is true then handler must not be nil
        public func notify(enabled: Bool, handler: ReadCompletionHandler?) -> PeripheralStatus {
            guard notifiable else { return .failure(.notNotifiable(self)) }

            if enabled && handler == nil {
                return .failure(.nilNotificationHandler(self))
            }
            
            notificationHandler = handler

            parent.parent.cbPeripheral.setNotifyValue(enabled, for: cbCharacteristic)
            
            return .success
        }
        
        // The Central Manager will call this method when the asynchronous notification state update has completed.
        // User types should override this method.
        open func setNotificationStateCompleted(value: Bool, cbError: Error?) {
            if let error = cbError {
                notificationHandler!(.failure(.cannotNotify(self, cbError: error)))
            }
        }
    }
    
    open class Descriptor : CustomStringConvertible {
        
        open let id: Identifier
        open let cbDescriptor : CBDescriptor
        open let parent: Characteristic
        
        public init(cbDescriptor: CBDescriptor, id: Identifier, parent: Characteristic) {
            self.id = id
            self.cbDescriptor = cbDescriptor
            self.parent = parent
        }
        
        public var name: String { return id.name ?? id.uuid.uuidString }
        
        public var description: String {
            return "\(name) \(cbDescriptor)\n"
        }

        // ************************** Reading ******************************
        
        public func readAsync() {
            parent.parent.parent.cbPeripheral.readValue(for: cbDescriptor)
        }
        
        // The Central Manager will call this method when an asynchronous read has completed.
        // The Central Manager will also call this method when a notification is received.
        // User types should override this method.
        open func readCompleted(value : Any?, cbError: Error?) {
            if let error = cbError {
                print("Error reading the \(name) descriptor's value: \(error)")
            }
        }
        
        // ************************** Writing ******************************
        
        public func writeAsync(value: Data) {
            parent.parent.parent.cbPeripheral.writeValue(value, for: cbDescriptor)
        }
        
        // The Central Manager will call this method when the asynchronous write has completed.
        // User types should override this method.
        open func writeCompleted(value : Any?, cbError: Error?) {
            if let error = cbError {
                print("Error writing the \(name) descriptor's value: \(error)")
            }
        }
        
    }
}
