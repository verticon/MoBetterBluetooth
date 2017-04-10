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
        }

        // Discovery **********************************************

        // TODO: Handle secondary services
        @objc func peripheral(_ cbPeripheral: CBPeripheral, didDiscoverServices error: Error?) {
            guard error == nil else {
                centralManager.sendEvent(.error(.serviceDiscoveryError(peripheral, cbError: error!)))
                return
            }
            
            guard !peripheral.servicesDiscovered else {
                centralManager.sendEvent(.error(.serviceDiscoveryRepeated(peripheral)))
                return
            }
            
            if let cbServices = cbPeripheral.services, cbServices.count > 0 {
                for cbService in cbServices {
                    guard let id = centralManager.subscription.match(cbService) else {
                        centralManager.sendEvent(.error(.serviceDiscoverySubscriptionMismatch(peripheral, cbService)))
                        continue
                    }
                    
                    let service = centralManager.factory.makeService(for: cbService, id: id, parent: peripheral)
                    peripheral.services.append(service)
                    
                    let characteristicUuids = centralManager.subscription[cbService]?.getCharacteristicUuids()
                    cbPeripheral.discoverCharacteristics(characteristicUuids, for:cbService)
                }
            }

            if peripheral.services.isEmpty {
                centralManager.sendEvent(.error(.serviceDiscoveryNoServices(peripheral)))
                return
            }
            
            peripheral.servicesDiscovered = true
            
            if peripheral.discoveryCompleted {
                centralManager.sendEvent(.peripheralReady(peripheral))
            }
        }
        
        @objc func peripheral(_ cbPeripheral: CBPeripheral, didDiscoverCharacteristicsFor cbService: CBService, error: Error?) {
            guard let service = peripheral[cbService] else {
                centralManager.sendEvent(.error(.charactericticDiscoveryUnrecognizedService(peripheral, cbService)))
                return
            }
            
            guard error == nil else {
                centralManager.sendEvent(.error(.charactericticDiscoveryError(service, cbError: error!)))
                return
            }
            
            guard !service.characteristicsDiscovered else {
                centralManager.sendEvent(.error(.characteristicDiscoveryRepeated(service)))
                return
            }
            
            if let cbCharacteristics = cbService.characteristics, cbCharacteristics.count > 0 {
                for cbCharacteristic in cbCharacteristics {
                    
                    guard let id = centralManager.subscription.match(cbCharacteristic, of: cbService) else {
                        centralManager.sendEvent(.error(.characteristicDiscoverySubscriptionMismatch(service, cbCharacteristic)))
                        continue
                    }
                    
                    let characteristic = centralManager.factory.makeCharacteristic(for: cbCharacteristic, id: id, parent: service)
                    service.characteristics.append(characteristic)
                    
                    var discoverDescriptors = true
                    if let characteristicSubscription = centralManager.subscription[cbService]?[cbCharacteristic] {
                        discoverDescriptors = characteristicSubscription.discoverDescriptors
                    }
                    if discoverDescriptors {
                        cbPeripheral.discoverDescriptors(for: cbCharacteristic)
                    } else {
                        characteristic.descriptorsDiscovered = true
                    }
                }
            }

            if service.characteristics.isEmpty {
                centralManager.sendEvent(.error(.characteristicDiscoveryNoCharacteristics(service)))
                return
            }
            
            service.characteristicsDiscovered = true
            
            if peripheral.discoveryCompleted {
                centralManager.sendEvent(.peripheralReady(peripheral))
            }
        }
        
        @objc func peripheral(_ cbPeripheral: CBPeripheral, didDiscoverDescriptorsFor cbCharacteristic: CBCharacteristic, error: Error?) {
            guard let characteristic = peripheral[cbCharacteristic.service]?[cbCharacteristic] else {
                centralManager.sendEvent(.error(.descriptorDiscoveryUnrecognizedCharacterictic(peripheral, cbCharacteristic)))
                return
            }
            
            guard error == nil else {
                centralManager.sendEvent(.error(.descriptorDiscoveryError(characteristic, cbError: error!)))
                return
            }
            
            guard !characteristic.descriptorsDiscovered else {
                centralManager.sendEvent(.error(.descriptorDiscoveryRepeated(characteristic)))
                return
            }
            
            if let cbDescriptors = cbCharacteristic.descriptors, cbDescriptors.count > 0 {
                for cbDescriptor in cbDescriptors {
                    let id = CentralManager.Identifier(uuid: cbDescriptor.uuid, name: nil)
                    let descriptor = centralManager.factory.makeDescriptor(for: cbDescriptor, id: id, parent: characteristic)
                    characteristic.descriptors.append(descriptor)
                }
            }
            
            characteristic.descriptorsDiscovered = true
            
            if peripheral.discoveryCompleted {
                centralManager.sendEvent(.peripheralReady(peripheral))
            }
        }
        
        // Characteristic Read/Write/Notify **********************************************

        @objc func peripheral(_ cbPeripheral: CBPeripheral, didUpdateValueFor cbCharacteristic: CBCharacteristic, error: Error?) {
            guard let characteristic = peripheral[cbCharacteristic.service]?[cbCharacteristic] else {
                centralManager.sendEvent(.error(.updateValueUnrecognizedCharacterictic(peripheral, cbCharacteristic)))
                return
            }
            
            characteristic.readCompleted(cbCharacteristic.value, cbError: error)
        }
        
        @objc func peripheral(_ cbPeripheral: CBPeripheral, didWriteValueFor cbCharacteristic: CBCharacteristic, error: Error?) {
            guard let characteristic = peripheral[cbCharacteristic.service]?[cbCharacteristic] else {
                centralManager.sendEvent(.error(.writeValueUnrecognizedCharacterictic(peripheral, cbCharacteristic)))
                return
            }
            
            characteristic.writeCompleted(cbError: error)
        }
        
        @objc func peripheral(_ cbPeripheral: CBPeripheral, didUpdateNotificationStateFor cbCharacteristic: CBCharacteristic, error: Error?) {
            guard let characteristic = peripheral[cbCharacteristic.service]?[cbCharacteristic] else {
                centralManager.sendEvent(.error(.updateNotificationUnrecognizedCharacterictic(peripheral, cbCharacteristic)))
                return
            }
            
            characteristic.setNotificationStateCompleted(value: cbCharacteristic.isNotifying, cbError: error)
        }

        // Descriptor Read/Write **********************************************

        @objc func peripheral(_ cbPeripheral: CBPeripheral, didUpdateValueFor cbDescriptor: CBDescriptor, error: Error?) {
            guard let descriptor = peripheral[cbDescriptor.characteristic.service]?[cbDescriptor.characteristic]?[cbDescriptor] else {
                centralManager.sendEvent(.error(.updateValueUnrecognizedDescriptor(peripheral, cbDescriptor)))
                return
            }
            
            descriptor.readCompleted(value: cbDescriptor.value, cbError: error)
        }
        
        @objc func peripheral(_ cbPeripheral: CBPeripheral, didWriteValueFor cbDescriptor: CBDescriptor, error: Error?) {
            guard let descriptor = peripheral[cbDescriptor.characteristic.service]?[cbDescriptor.characteristic]?[cbDescriptor] else {
                centralManager.sendEvent(.error(.writeValueUnrecognizedDescriptor(peripheral, cbDescriptor)))
                return
            }
            
            descriptor.writeCompleted(value: cbDescriptor.value, cbError: error)
        }
    }
}
