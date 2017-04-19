//
//  Factory
//  MoBetterBluetooth
//
//  Created by Robert Vaessen on 10/30/16.
//  Copyright © 2016 Robert Vaessen. All rights reserved.
//

import UIKit
import CoreBluetooth
import CoreLocation
import VerticonsToolbox

public protocol CentralManagerTypesFactory {
    func makePeripheral(for cbPeripheral: CBPeripheral, manager: CentralManager, advertisement: Advertisement, rssi: NSNumber) -> CentralManager.Peripheral
    func makeService(for cbService: CBService, id: CentralManager.Identifier, parent: CentralManager.Peripheral) -> CentralManager.Service
    func makeCharacteristic(for cbCharacteristic: CBCharacteristic, id: CentralManager.Identifier, parent: CentralManager.Service) -> CentralManager.Characteristic
    func makeDescriptor(for cbDescriptor: CBDescriptor, id: CentralManager.Identifier, parent: CentralManager.Characteristic) -> CentralManager.Descriptor
}

extension CentralManagerTypesFactory {
    public func makePeripheral(for cbPeripheral: CBPeripheral, manager: CentralManager, advertisement: Advertisement, rssi: NSNumber) -> CentralManager.Peripheral {
        return CentralManager.Peripheral(cbPeripheral: cbPeripheral, manager: manager, advertisement: advertisement, rssi: rssi)
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

// TODO: Convert the hexidecimal printing of the properties to something more meaningful
extension CentralManager {

    open class Peripheral : Broadcaster<PeripheralEvent>, CustomStringConvertible {
        
        public let manager: CentralManager

        public let cbPeripheral: CBPeripheral
        public private(set) var advertisement: Advertisement
        public private(set) var rssi: NSNumber
        public private(set) var discoveryTime: String
        public private(set) var discoveryLocation: String?

        public internal(set) var services = [Service]()
        public internal(set) var servicesDiscoveryInProgress = false
        public internal(set) var servicesDiscovered: Bool {
            didSet {
                servicesDiscoveryInProgress = false
            }
        }

        public init(cbPeripheral: CBPeripheral, manager: CentralManager, advertisement: Advertisement, rssi: NSNumber) {
            self.cbPeripheral = cbPeripheral
            self.manager = manager
            self.advertisement = advertisement
            self.rssi = rssi

            discoveryTime = LocalTime.text
            servicesDiscovered = false

            super.init()

            if let location = UserLocation.instance?.location {
                CLGeocoder().reverseGeocodeLocation(location, completionHandler: geocoderCompletionHandler)
            }
        }

        private func geocoderCompletionHandler(placemarks: [CLPlacemark]?, error: Error?) {
            if let address = placemarks?[0].addressDictionary?["Street"] {
                discoveryLocation = String(describing: address)
                sendEvent(.locationDetermined(self, discoveryLocation!))
            }
        }

        public func updateReceived(newAdvertisement: Advertisement, newRssi: NSNumber) {
            var modified = false
            newAdvertisement.data.forEach {
                if !advertisement.data.keys.contains($0){
                    advertisement.data[$0] = $1
                    modified = true
                }
            }
            if modified {
                sendEvent(.advertisementUpdated(self, newEntries: newAdvertisement))
            }

            if rssi != newRssi {
                rssi = newRssi
                sendEvent(.rssiUpdated(self, newRssi: newRssi))
            }
            
        }

        public var name: String {
            return cbPeripheral.name ?? cbPeripheral.identifier.uuidString
        }

        public var description : String {
            var description = "\(cbPeripheral), services \(servicesDiscovered ? "discovered" : "not discovered")\n\(advertisement)"
            
            if servicesDiscovered {
                for service in services {
                    description += ("\n\(service)")
                }
            }

            return description
        }
        
        public var connectable: Bool {
            return advertisement.isConnectable
        }
        
        internal var connectCompletionhandler: ((Peripheral, CentralManagerStatus) -> Void)?
        public func connect(completionhandler: ((Peripheral, CentralManagerStatus) -> Void)?) -> PeripheralStatus {
            guard connectable else {  return .failure(.notConnectable) }
            guard cbPeripheral.state == .disconnected else {  return .failure(.notDisconnected) }
            
            connectCompletionhandler = completionhandler
            manager.cbManager.connect(cbPeripheral, options: nil)
            
            sendEvent(.stateChanged(self)) // disconnected => connecting

            return .success
        }
        
        internal var disconnectCompletionhandler: ((Peripheral, CentralManagerStatus) -> Void)?
        public func disconnect(completionhandler: ((Peripheral, CentralManagerStatus) -> Void)?) -> PeripheralStatus {
            guard cbPeripheral.state == .connected else {  return .failure(.notConnected) }
            
            disconnectCompletionhandler = completionhandler
            manager.cbManager.cancelPeripheralConnection(cbPeripheral)
            
            sendEvent(.stateChanged(self)) // connected => disconnecting

            return .success
        }
        
        public func discoverServices() -> PeripheralStatus{
            guard !(servicesDiscoveryInProgress || servicesDiscovered) else { return .failure(.rediscoveryNotAllowed) }

            servicesDiscoveryInProgress = true
            cbPeripheral.discoverServices(manager.subscription.getServiceUuids())
            
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

    open class Attribute {
        public let id: Identifier
        
        init(id: Identifier) {
            self.id = id
        }
    }

    open class Service : Attribute, CustomStringConvertible {

        public weak var cbService: CBService?
        public let parent: Peripheral
        public internal(set) var characteristics = [Characteristic]()

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
            parent.cbPeripheral.discoverCharacteristics(parent.manager.subscription[service]?.getCharacteristicUuids(), for: service)
            
            return .success
        }
        
        public var description : String {
            var description = "\(String(describing: cbService)), characteristics \(characteristicsDiscovered ? "discovered" : "not discovered")"
            for characteristic in characteristics {
                description += "\n\(characteristic)"
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

    open class Characteristic : Attribute, CustomStringConvertible {
        
        public weak var cbCharacteristic : CBCharacteristic?
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
            super.init(id: id)
        }
        
        public var name: String { return id.name ?? id.uuid.uuidString }
        
        public func discoverDescriptors() -> PeripheralStatus {
            guard !(descriptorDiscoveryInProgress || descriptorsDiscovered) else { return .failure(.rediscoveryNotAllowed) }
            
            guard let characteristic = cbCharacteristic else { return .failure(.cbAttributeIsNil) }
            
            descriptorDiscoveryInProgress = true
            parent.parent.cbPeripheral.discoverDescriptors(for: characteristic)
            
            return .success
        }
        
        public var description : String {
            var description =  "\(String(describing: cbCharacteristic)), descriptors \(descriptorsDiscovered ? "discovered" : "not discovered")"
            for descriptor in descriptors {
                description += increaseIndent("\n\(descriptor)")
            }
            return description
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
            return cbCharacteristic?.properties.contains(CBCharacteristicProperties.read) ?? false
        }
        
        public func read(_ completionHandler: @escaping ReadCompletionHandler) -> PeripheralStatus {
            guard readable else { return .failure(.notReadable) }

            guard readCompletionHandler == nil else { return .failure(.readInProgress) }

            guard let characteristic = cbCharacteristic else { return .failure(.cbAttributeIsNil) }

            readCompletionHandler = completionHandler

            parent.parent.cbPeripheral.readValue(for: characteristic)

            return .success
        }
        
        // The Central Manager will call this method when an asynchronous read has completed.
        // The Central Manager will also call this method when a notification is received.
        //
        // I wish that there were a way to distingush read completion from notification.
        public func readCompleted(_ value : Data?, cbError: Error?) {
            guard readCompletionHandler != nil || notificationHandler != nil else {
                fatalError("Read completed method invoked but both completion handlers are nil???")
            }
            
            let result: ReadResult
            if let error = cbError {
                result = .failure(.characteristicReadError(self, cbError: error))
            } else {
                result = .success(value!)
            }

            if let handler = readCompletionHandler {
                readCompletionHandler = nil // Do this first so that the handler can initiate a new read if desired.
                handler(result)
            }

            if let handler = notificationHandler /* , case ReadResult.success = result */ {
                handler(result)
            }
        }
        
        // ************************** Writing ******************************
        
        public typealias WriteCompletionHandler = (PeripheralStatus) -> Void
        private var writeCompletionHandler: WriteCompletionHandler?

        public var writeable : Bool {
            return cbCharacteristic?.properties.contains(CBCharacteristicProperties.write) ?? false
        }
        
        public func write(_ value: Data, completionHandler: @escaping WriteCompletionHandler) -> PeripheralStatus {
            guard writeable else { return .failure(.notWriteable) }
            
            guard writeCompletionHandler == nil else { return .failure(.writeInProgress) }
            
            guard let characteristic = cbCharacteristic else { return .failure(.cbAttributeIsNil) }

            writeCompletionHandler = completionHandler

            parent.parent.cbPeripheral.writeValue(value, for: characteristic, type: CBCharacteristicWriteType.withResponse)

            return .success
        }
        
        // The Central Manager will call this method when the asynchronous write has completed.
        public func writeCompleted(cbError: Error?) {
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

        public var notifiable : Bool {
            return cbCharacteristic?.properties.contains(CBCharacteristicProperties.notify) ?? false
        }
        
        // If enabled is true then handler must not be nil
        public func notify(enabled: Bool, handler: ReadCompletionHandler?) -> PeripheralStatus {
            guard notifiable else { return .failure(.notNotifiable) }

            guard let characteristic = cbCharacteristic else { return .failure(.cbAttributeIsNil) }

            if enabled && handler == nil {
                return .failure(.handlerCannotBeNil)
            }
            
            notificationHandler = handler

            parent.parent.cbPeripheral.setNotifyValue(enabled, for: characteristic)
            
            return .success
        }
        
        // The Central Manager will call this method when the asynchronous notification state update has completed.
        // User types should override this method.
        public func setNotificationStateCompleted(value: Bool, cbError: Error?) {
            if let error = cbError {
                notificationHandler!(.failure(.characteristicNotifyError(self, cbError: error)))
            }
        }
    }
    
    // TODO: Get descriptors squared away
    open class Descriptor : Attribute, CustomStringConvertible {
        
        public weak var cbDescriptor : CBDescriptor?
        public let parent: Characteristic
        
        public init(cbDescriptor: CBDescriptor, id: Identifier, parent: Characteristic) {
            self.cbDescriptor = cbDescriptor
            self.parent = parent
            super.init(id: id)
        }
        
        public var name: String { return id.name ?? id.uuid.uuidString }
        
        public var description: String {
            return "\(String(describing: cbDescriptor))"
        }

        // ************************** Reading ******************************
        
        public enum ReadResult {
            case success(Any)
            case failure(PeripheralError)
        }
        
        public typealias ReadCompletionHandler = (ReadResult) -> Void
        private var readCompletionHandler: ReadCompletionHandler?
        
        public func read(_ completionHandler: @escaping ReadCompletionHandler) -> PeripheralStatus {
           
            guard readCompletionHandler == nil else { return .failure(.readInProgress) }
            
            guard let descriptor = cbDescriptor else { return .failure(.cbAttributeIsNil) }
            
            readCompletionHandler = completionHandler
            
            parent.parent.parent.cbPeripheral.readValue(for: descriptor)
            
            return .success
        }
        
        // The Central Manager will call this method when an asynchronous read has completed.
        public func readCompleted(_ value : Any?, cbError: Error?) {
            guard readCompletionHandler != nil else {
                fatalError("Read completed method invoked but completion handler is nil???")
            }
            
            let result: ReadResult
            if let error = cbError {
                result = .failure(.descriptorReadError(self, cbError: error))
            } else {
                result = .success(value!)
            }
            
            if let handler = readCompletionHandler {
                readCompletionHandler = nil // Do this first so that the handler can initiate a new read if desired.
                handler(result)
            }
        }

        // ************************** Writing ******************************
        
        public typealias WriteCompletionHandler = (PeripheralStatus) -> Void
        private var writeCompletionHandler: WriteCompletionHandler?
        
        public func write(_ value: Data, completionHandler: @escaping WriteCompletionHandler) -> PeripheralStatus {
            
            guard writeCompletionHandler == nil else { return .failure(.writeInProgress) }
            
            guard let descriptor = cbDescriptor else { return .failure(.cbAttributeIsNil) }

            writeCompletionHandler = completionHandler
            
            parent.parent.parent.cbPeripheral.writeValue(value, for: descriptor)
            
            return .success
        }
        
        // The Central Manager will call this method when the asynchronous write has completed.
        public func writeCompleted(cbError: Error?) {
            guard let handler = writeCompletionHandler else {
                fatalError("Write completed method invoked but completion handler is nil???")
            }
            
            writeCompletionHandler = nil // Do this first so that the handler can initiate a new write if desired.
            
            if let error = cbError {
                handler(.failure(.descriptorWriteError(self, cbError: error)))
            }
            else {
                handler(.success)
            }
        }
    }
}
