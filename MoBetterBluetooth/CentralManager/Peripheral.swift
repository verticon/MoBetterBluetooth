//
//  Peripheral.swift
//  MoBetterBluetooth
//
//  Created by Robert Vaessen on 10/31/18.
//  Copyright © 2018 Verticon. All rights reserved.
//

import Foundation
import CoreBluetooth
import CoreLocation
import VerticonsToolbox

extension CentralManager {
    open class Peripheral : Broadcaster<PeripheralEvent>, CustomStringConvertible, Hashable {
        
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
            
            if let location = UserLocation.instance.currentLocation {
                CLGeocoder().reverseGeocodeLocation(location, completionHandler: geocoderCompletionHandler)
            }
            
            if manager.subscription.monitorAdvertisements {
                initiateTimeoutDetection()
            }
        }
        
        deinit {
            let _ = disconnect(completionhandler: nil)
        }
        
        private func geocoderCompletionHandler(placemarks: [CLPlacemark]?, error: Error?) {
            if let address = placemarks?[0].thoroughfare {
                discoveryLocation = String(describing: address)
                sendEvent(.locationDetermined(self, discoveryLocation!))
            }
        }
        
        public class Time {
            private static let dateFormatter: DateFormatter = {
                var formatter = DateFormatter()
                formatter.setLocalizedDateFormatFromTemplate("HH:mm:ss.SSS")
                return formatter
            }()
            
            public class var text : String {
                return dateFormatter.string(from: Date())
            }
        }
        
        // ************************************************************************************************************************
        // Advertisments
        // ************************************************************************************************************************
        
        private static let defaultAdvertisementTimeout = 20
        private var advertisementTimeout = defaultAdvertisementTimeout
        private var lastAdvertisementReceivedTime: Date? = Date()
        private var advertisementTimeoutDetector: DispatchWorkItem?
        
        private var isAdvertising: Bool = true {
            didSet {
                if oldValue != isAdvertising { updateReceptionState() }
            }
        }
        
        public private(set) var receptionState: AdvertisementReceptionState = .receiving
        
        internal func updateReceptionState() {
            let prevReceptionState = receptionState
            
            if cbPeripheral.state != .disconnected { receptionState = .connected }
            else if !manager.isScanning { receptionState = .notScanning }
            else { receptionState = isAdvertising ? .receiving : .notReceiving } // The peripheral has powered off, or moved out of range, or been connected to by another central.
            
            if receptionState != prevReceptionState { sendEvent(.advertisementReceptionStateChange(self, newState: receptionState)) }
        }
        
        public func updateReceived(newAdvertisement: Advertisement, newRssi: NSNumber) {
            
            advertisementTimeoutDetector?.cancel()
            isAdvertising = true
            
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
            
            if manager.subscription.monitorAdvertisements {
                let receiveTime = Date()
                
                // Adjust the timeout period based on the observed advertising interval
                if let prevReceiveTime = self.lastAdvertisementReceivedTime {
                    let elapsedTime = Int(receiveTime.timeIntervalSince(prevReceiveTime).rounded(.up))
                    if elapsedTime > 1 { // Skip the intervals produced by the scan response
                        advertisementTimeout = 2 * elapsedTime // Let's be conservative. iOS seems to vary the delivery rate.
                    }
                }
                else {
                    advertisementTimeout = Peripheral.defaultAdvertisementTimeout
                }
                
                self.lastAdvertisementReceivedTime = receiveTime
                
                initiateTimeoutDetection()
            }
        }
        
        private func initiateTimeoutDetection() {
            advertisementTimeoutDetector = DispatchWorkItem() { [weak self] in
                guard let peripheral = self else { return }
                peripheral.isAdvertising = false
                peripheral.lastAdvertisementReceivedTime = nil
            }
            manager.dispatchQueue.asyncAfter(deadline: .now() + .seconds(advertisementTimeout), execute: advertisementTimeoutDetector!)
        }
        
        // ************************************************************************************************************************
        //
        // ************************************************************************************************************************
        
        public var name: String {
            return cbPeripheral.name ?? cbPeripheral.identifier.uuidString
        }
        
        public var description : String {
            var description = "\(cbPeripheral)"
            if cbPeripheral.state == .connected { description += ", services \(servicesDiscovered ? "discovered, count = \(services.count)" : "not discovered")" }
            description += "\nAdvertisement\(advertisement)"
            
            if servicesDiscovered {
                for service in services {
                    description += increaseIndent("\n\(service)")
                }
            }
            
            return description
        }
        
        public var connectable: Bool {
            return advertisement.isConnectable
        }
        
        // TODO: add an optional timeout parameter
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
            guard cbPeripheral.state == .connected || cbPeripheral.state == .connecting else {  return .failure(.notConnected) }
            
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
        
        public var hashValue : Int {
            get {
                return cbPeripheral.hash
            }
        }
    }
}

extension CentralManager.Peripheral : Equatable {
    public static func == (lhs: CentralManager.Peripheral , rhs: CentralManager.Peripheral ) -> Bool {
        return lhs.cbPeripheral.identifier.uuidString == rhs.cbPeripheral.identifier.uuidString
    }
}


