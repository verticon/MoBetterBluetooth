//
//  CentralManagerEvents.swift
//  MoBetterBluetooth
//
//  Created by Robert Vaessen on 4/10/17.
//  Copyright © 2017 Verticon. All rights reserved.
//

import Foundation

public enum CentralManagerEvent {
    case managerReady(CentralManager) // The CentralManager is ready to scan for peripherals
    case managerStartedScanning(CentralManager)
    case managerStoppedScanning(CentralManager)
    
    case peripheralReady(CentralManager.Peripheral)
    case peripheralDisconnected((CentralManager.Peripheral, coreBluetoothError: Error?))
    
    case error(CentralManagerError)
}
