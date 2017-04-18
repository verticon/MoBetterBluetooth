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

    case ready(CentralManager) // The CentralManager is ready to scan for peripherals

    case startedScanning((CentralManager, [CBUUID]?))
    case stoppedScanning(CentralManager)

    case updatedSubscription(CentralManager)
    
    case discoveredPeripheral((CentralManager.Peripheral, rssi: NSNumber))
    
    case error(CentralManagerError)
}

public enum PeripheralEvent {

    case locationDetermined(CentralManager.Peripheral, String)

    case servicesDiscovered(CentralManager.Peripheral)
    case characteristicsDiscovered(CentralManager.Service)
    case descriptorsDiscovered(CentralManager.Characteristic)

    case stateChanged(CentralManager.Peripheral)

    case rssiUpdated(CentralManager.Peripheral, newRssi: NSNumber)
    case advertisementUpdated(CentralManager.Peripheral, newAdvertisement: Advertisement)

    case error(PeripheralError)
}
