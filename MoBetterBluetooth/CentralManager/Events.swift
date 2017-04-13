//
//  CentralManagerEvents.swift
//  MoBetterBluetooth
//
//  Created by Robert Vaessen on 4/10/17.
//  Copyright © 2017 Verticon. All rights reserved.
//

import Foundation
import CoreBluetooth

public enum CentralManagerEvent {

    case managerReady(CentralManager) // The CentralManager is ready to scan for peripherals
    case managerStartedScanning((CentralManager, [CBUUID]?))
    case managerStoppedScanning(CentralManager)
    case managerUpdatedSubscription(CentralManager)
    
    case peripheralDiscovered((CentralManager.Peripheral, rssi: NSNumber))
    case peripheralRediscovered(CBPeripheral, advertisementData: [String : Any])
    case peripheralReady(CentralManager.Peripheral) // TODO: Consider getting rid of the peripheral ready event
    case peripheralStateChange(CentralManager.Peripheral)
    
    case error(CentralManagerError)
}

public enum PeripheralManagerEvent {

    case peripheralStateChange(CentralManager.Peripheral)
    
    case error(CentralManagerError)
}
