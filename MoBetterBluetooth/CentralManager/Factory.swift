//
//  Factory
//  MoBetterBluetooth
//
//  Created by Robert Vaessen on 10/30/16.
//  Copyright © 2016 Robert Vaessen. All rights reserved.
//

import Foundation
import CoreBluetooth

public protocol CentralManagerTypesFactory {
    func makePeripheral(for cbPeripheral: CBPeripheral, manager: CentralManager, advertisement: Advertisement, rssi: NSNumber) -> CentralManager.Peripheral
    func makeService(for cbService: CBService, id: Identifier, parent: CentralManager.Peripheral) -> CentralManager.Service
    func makeCharacteristic(for cbCharacteristic: CBCharacteristic, id: Identifier, parent: CentralManager.Service) -> CentralManager.Characteristic
    func makeDescriptor(for cbDescriptor: CBDescriptor, id: Identifier, parent: CentralManager.Characteristic) -> CentralManager.Descriptor
}

extension CentralManagerTypesFactory {
    public func makePeripheral(for cbPeripheral: CBPeripheral, manager: CentralManager, advertisement: Advertisement, rssi: NSNumber) -> CentralManager.Peripheral {
        return CentralManager.Peripheral(cbPeripheral: cbPeripheral, manager: manager, advertisement: advertisement, rssi: rssi)
    }
    
    public func makeService(for cbService: CBService, id: Identifier, parent: CentralManager.Peripheral) -> CentralManager.Service {
        return CentralManager.Service(cbService: cbService, id: id, parent: parent)
    }
    
    public func makeCharacteristic(for cbCharacteristic: CBCharacteristic, id: Identifier, parent: CentralManager.Service) -> CentralManager.Characteristic {
        return CentralManager.Characteristic(cbCharacteristic: cbCharacteristic, id: id, parent: parent)
    }
    
    public func makeDescriptor(for cbDescriptor: CBDescriptor, id: Identifier, parent: CentralManager.Characteristic) -> CentralManager.Descriptor {
        return CentralManager.Descriptor(cbDescriptor: cbDescriptor, id: id, parent: parent)
    }
}

// TODO: Get rid of parent

// TODO: Replace the fatal errors with exceptions





