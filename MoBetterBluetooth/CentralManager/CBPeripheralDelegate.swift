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
                peripheral.sendEvent(.error(.servicesDiscoveryError(peripheral, cbError: error!)))
                return
            }
            
            guard !peripheral.servicesDiscovered else {
                peripheral.sendEvent(.error(.servicesRediscovered(peripheral)))
                return
            }
            
            if let cbServices = cbPeripheral.services, cbServices.count > 0 {
                for cbService in cbServices {
                    guard let id = centralManager.subscription.match(cbService) else {
                        peripheral.sendEvent(.error(.servicesDiscoverySubscriptionMismatch(peripheral, cbService)))
                        continue
                    }
                    
                    let service = centralManager.factory.makeService(for: cbService, id: id, parent: peripheral)
                    peripheral.services.append(service)
                    
                    if centralManager.subscription.autoDiscover {
                        let characteristicUuids = centralManager.subscription[cbService]?.getCharacteristicUuids()
                        cbPeripheral.discoverCharacteristics(characteristicUuids, for:cbService)
                    }
                }
            }

            peripheral.servicesDiscovered = true

            peripheral.sendEvent(.servicesDiscovered(peripheral))

            if peripheral.services.isEmpty {
                peripheral.sendEvent(.error(.servicesDiscoveryNoServices(peripheral)))
            }
        }
        
        @objc func peripheral(_ cbPeripheral: CBPeripheral, didDiscoverCharacteristicsFor cbService: CBService, error: Error?) {
            guard let service = peripheral[cbService] else {
                peripheral.sendEvent(.error(.charactericticsDiscoveryUnrecognizedService(peripheral, cbService)))
                return
            }
            
            guard error == nil else {
                peripheral.sendEvent(.error(.charactericticsDiscoveryError(service, cbError: error!)))
                return
            }
            
            guard !service.characteristicsDiscovered else {
                peripheral.sendEvent(.error(.characteristicsRediscovered(service)))
                return
            }
            
            if let cbCharacteristics = cbService.characteristics, cbCharacteristics.count > 0 {
                for cbCharacteristic in cbCharacteristics {
                    
                    guard let id = centralManager.subscription.match(cbCharacteristic, of: cbService) else {
                        peripheral.sendEvent(.error(.characteristicsDiscoverySubscriptionMismatch(service, cbCharacteristic)))
                        continue
                    }
                    
                    let characteristic = centralManager.factory.makeCharacteristic(for: cbCharacteristic, id: id, parent: service)
                    service.characteristics.append(characteristic)
                    
                    if centralManager.subscription.autoDiscover {
                        cbPeripheral.discoverDescriptors(for: cbCharacteristic)
                    }
                }
            }

            service.characteristicsDiscovered = true

            peripheral.sendEvent(.characteristicsDiscovered(service))

            if service.characteristics.isEmpty {
                peripheral.sendEvent(.error(.characteristicsDiscoveryNoCharacteristics(service)))
            }
        }
        
        @objc func peripheral(_ cbPeripheral: CBPeripheral, didDiscoverDescriptorsFor cbCharacteristic: CBCharacteristic, error: Error?) {
            guard let characteristic = peripheral[cbCharacteristic.service]?[cbCharacteristic] else {
                peripheral.sendEvent(.error(.descriptorsDiscoveryUnrecognizedCharacterictic(peripheral, cbCharacteristic)))
                return
            }
            
            guard error == nil else {
                peripheral.sendEvent(.error(.descriptorsDiscoveryError(characteristic, cbError: error!)))
                return
            }
            
            guard !characteristic.descriptorsDiscovered else {
                peripheral.sendEvent(.error(.descriptorsRediscovered(characteristic)))
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
            
            peripheral.sendEvent(.descriptorsDiscovered(characteristic))
        }
        
        // Characteristic Read/Write/Notify **********************************************

        @objc func peripheral(_ cbPeripheral: CBPeripheral, didUpdateValueFor cbCharacteristic: CBCharacteristic, error: Error?) {
            guard let characteristic = peripheral[cbCharacteristic.service]?[cbCharacteristic] else {
                peripheral.sendEvent(.error(.updateValueUnrecognizedCharacterictic(peripheral, cbCharacteristic)))
                return
            }
            
            characteristic.readCompleted(cbCharacteristic.value, cbError: error)
        }
        
        @objc func peripheral(_ cbPeripheral: CBPeripheral, didWriteValueFor cbCharacteristic: CBCharacteristic, error: Error?) {
            guard let characteristic = peripheral[cbCharacteristic.service]?[cbCharacteristic] else {
                peripheral.sendEvent(.error(.writeValueUnrecognizedCharacterictic(peripheral, cbCharacteristic)))
                return
            }
            
            characteristic.writeCompleted(cbError: error)
        }
        
        @objc func peripheral(_ cbPeripheral: CBPeripheral, didUpdateNotificationStateFor cbCharacteristic: CBCharacteristic, error: Error?) {
            guard let characteristic = peripheral[cbCharacteristic.service]?[cbCharacteristic] else {
                peripheral.sendEvent(.error(.updateNotificationUnrecognizedCharacterictic(peripheral, cbCharacteristic)))
                return
            }
            
            characteristic.setNotificationStateCompleted(value: cbCharacteristic.isNotifying, cbError: error)
        }

        // Descriptor Read/Write **********************************************

        @objc func peripheral(_ cbPeripheral: CBPeripheral, didUpdateValueFor cbDescriptor: CBDescriptor, error: Error?) {
            guard let descriptor = peripheral[cbDescriptor.characteristic.service]?[cbDescriptor.characteristic]?[cbDescriptor] else {
                peripheral.sendEvent(.error(.updateValueUnrecognizedDescriptor(peripheral, cbDescriptor)))
                return
            }
            
            descriptor.readCompleted(value: cbDescriptor.value, cbError: error)
        }
        
        @objc func peripheral(_ cbPeripheral: CBPeripheral, didWriteValueFor cbDescriptor: CBDescriptor, error: Error?) {
            guard let descriptor = peripheral[cbDescriptor.characteristic.service]?[cbDescriptor.characteristic]?[cbDescriptor] else {
                peripheral.sendEvent(.error(.writeValueUnrecognizedDescriptor(peripheral, cbDescriptor)))
                return
            }
            
            descriptor.writeCompleted(value: cbDescriptor.value, cbError: error)
        }
    }
}
