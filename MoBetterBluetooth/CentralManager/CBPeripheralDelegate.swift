//
//  CBPeripheralDelegate.swift
//  Toolbox
//
//  Created by Robert Vaessen on 10/30/16.
//  Copyright © 2016 Robert Vaessen. All rights reserved.
//

import UIKit
import CoreBluetooth

extension CentralManager {
    class PeripheralDelegate : NSObject, CBPeripheralDelegate {
        
        let peripheral: Peripheral
        private let centralManager: CentralManager
        
        init(centralManager: CentralManager, peripheral: Peripheral) {
            self.centralManager = centralManager
            self.peripheral = peripheral
            super.init()
            
            peripheral.cbPeripheral.delegate = self
        }

        deinit {
            peripheral.cbPeripheral.delegate = nil
        }

        // Discovery **********************************************

        // TODO: Handle secondary services
        @objc func peripheral(_ cbPeripheral: CBPeripheral, didDiscoverServices error: Error?) {
            
            validatePeripheral(cbPeripheral)

            guard !peripheral.servicesDiscovered else { fatalError("Services rediscovered - \(peripheral)") }

            guard error == nil else {
                peripheral.sendEvent(.error(.servicesDiscoveryError(peripheral, cbError: error!)))
                return
            }

            cbPeripheral.services?.forEach { cbService in
                guard let id = centralManager.subscription.match(cbService) else { fatalError("Service \(cbService) does not match the subscription \(centralManager.subscription)") }
                
                let service = centralManager.factory.makeService(for: cbService, id: id, parent: peripheral)
                peripheral.services.append(service)
            }

            peripheral.servicesDiscovered = true
            peripheral.sendEvent(.servicesDiscovered(peripheral))

            if centralManager.subscription.autoDiscover {
                peripheral.services.forEach { service in
                    if case .failure(let error) = service.discoverCharacteristics() { fatalError("Cannot discover \(service)'s characteristics\n\(error)\n") }
                }
            }
        }
        
        @objc func peripheral(_ cbPeripheral: CBPeripheral, didDiscoverCharacteristicsFor cbService: CBService, error: Error?) {
            
            validatePeripheral(cbPeripheral)

            guard let service = peripheral[cbService] else { fatalError("Unrecognized service - \(cbService)") }
            
            guard !service.characteristicsDiscovered else { fatalError("Characteristics rediscovered - \(service)") }

            guard error == nil else {
                peripheral.sendEvent(.error(.charactericticsDiscoveryError(service, cbError: error!)))
                return
            }
            
            cbService.characteristics?.forEach { cbCharacteristic in
                guard let id = centralManager.subscription.match(cbCharacteristic, of: cbService) else { fatalError("\(cbService)'s \(cbCharacteristic) does not match the subscription \(centralManager.subscription)") }
                
                let characteristic = centralManager.factory.makeCharacteristic(for: cbCharacteristic, id: id, parent: service)
                service.characteristics.append(characteristic)
            }

            service.characteristicsDiscovered = true
            peripheral.sendEvent(.characteristicsDiscovered(service))

            if centralManager.subscription.autoDiscover {
                service.characteristics.forEach { characteristic in
                    if case .failure(let error) = characteristic.discoverDescriptors() { fatalError("Cannot discover \(characteristic)'s descriptors\n\(error)\n") }
                }
            }
            
        }
        
        @objc func peripheral(_ cbPeripheral: CBPeripheral, didDiscoverDescriptorsFor cbCharacteristic: CBCharacteristic, error: Error?) {
            
            validatePeripheral(cbPeripheral)

            guard let characteristic = peripheral[cbCharacteristic.service]?[cbCharacteristic] else { fatalError("Unrecognized characteristic - \(cbCharacteristic)") }
            
            guard !characteristic.descriptorsDiscovered else { fatalError("Descriptors rediscovered - \(characteristic)") }

            guard error == nil else {
                peripheral.sendEvent(.error(.descriptorsDiscoveryError(characteristic, cbError: error!)))
                return
            }
            
            cbCharacteristic.descriptors?.forEach {
                let id = Identifier(uuid: $0.uuid, name: nil)
                let descriptor = centralManager.factory.makeDescriptor(for: $0, id: id, parent: characteristic)
                characteristic.descriptors.append(descriptor)
            }
            
            characteristic.descriptorsDiscovered = true
            
            peripheral.sendEvent(.descriptorsDiscovered(characteristic))
        }
        
        // Characteristic Read/Write/Notify **********************************************

        @objc func peripheral(_ cbPeripheral: CBPeripheral, didUpdateValueFor cbCharacteristic: CBCharacteristic, error: Error?) {
            
            validatePeripheral(cbPeripheral)

            guard let characteristic = peripheral[cbCharacteristic.service]?[cbCharacteristic] else { fatalError("Unrecognized characteristic - \(cbCharacteristic)") }
            
            characteristic.readCompleted(cbCharacteristic.value, cbError: error)
        }
        
        @objc func peripheral(_ cbPeripheral: CBPeripheral, didWriteValueFor cbCharacteristic: CBCharacteristic, error: Error?) {
            
            validatePeripheral(cbPeripheral)

            guard let characteristic = peripheral[cbCharacteristic.service]?[cbCharacteristic] else { fatalError("Unrecognized characteristic - \(cbCharacteristic)") }
            
            characteristic.writeCompleted(cbError: error)
        }
        
        @objc func peripheral(_ cbPeripheral: CBPeripheral, didUpdateNotificationStateFor cbCharacteristic: CBCharacteristic, error: Error?) {
            
            validatePeripheral(cbPeripheral)

            guard let characteristic = peripheral[cbCharacteristic.service]?[cbCharacteristic] else { fatalError("Unrecognized characteristic - \(cbCharacteristic)") }
            
            characteristic.setNotificationStateCompleted(value: cbCharacteristic.isNotifying, cbError: error)
        }

        // Descriptor Read/Write **********************************************

        @objc func peripheral(_ cbPeripheral: CBPeripheral, didUpdateValueFor cbDescriptor: CBDescriptor, error: Error?) {
            
            validatePeripheral(cbPeripheral)

            guard let descriptor = peripheral[cbDescriptor.characteristic.service]?[cbDescriptor.characteristic]?[cbDescriptor] else { fatalError("Unrecognized descriptor - \(cbDescriptor)") }
            
            descriptor.readCompleted(cbDescriptor.value, cbError: error)
        }
        
        @objc func peripheral(_ cbPeripheral: CBPeripheral, didWriteValueFor cbDescriptor: CBDescriptor, error: Error?) {
            
            validatePeripheral(cbPeripheral)

            guard let descriptor = peripheral[cbDescriptor.characteristic.service]?[cbDescriptor.characteristic]?[cbDescriptor] else {  fatalError("Unrecognized descriptor - \(cbDescriptor)") }
            
            descriptor.writeCompleted(cbError: error)
        }

        private func validatePeripheral(_ cbPeripheral: CBPeripheral) {
            if cbPeripheral !== peripheral.cbPeripheral {
                fatalError("Peripheral is not mine:\n\tmine  - \(peripheral.cbPeripheral)\n\tother - \(cbPeripheral)")
            }
        }
    }
}
