//
//  CentralManager.swift
//  Toolbox
//
//  Created by Robert Vaessen on 10/30/16.
//  Copyright © 2016 Robert Vaessen. All rights reserved.
//

import UIKit
import CoreBluetooth

open class CentralManager {

    // Types *********************************************************************************************************

    public enum Event {
        case managerReady() // The CentralManager is ready to scan for peripherals

        case peripheralReady(Peripheral) // A peripheral that matches the subscription has been discovered and all of its matching services, characteristics and descriptors are in place
        case peripheralDisconnected((peripheral: Peripheral, coreBluetoothError: Error?))

        case error(ErrorCode)
        
        public typealias Handler = (_ event: Event) -> Void
    }

    public enum ErrorCode : Error {
        case notReady(String)
        case internalError(String)

        case bleNotSupported
        
        case peripheral(String, Peripheral, Error?)
        case service(String, Service, Error?)
        case characteristic(String, Characteristic, Error?)
    }
    
    private class Factory : CentralManagerTypesFactory {}
    
    // Instance Members **********************************************************************************************

    private let cbManager: CBCentralManager
    private let cbManagerDelegate: CentralManagerDelegate

    // If the subscription is empty then the Central Manager will report any and all peripherals;
    // else the Central Manager will only report those peripherals that provide the specified services.
    public init(name: String = "", subscription: PeripheralSubscription = PeripheralSubscription(), factory: CentralManagerTypesFactory = Factory(), eventHandler: @escaping Event.Handler) {

        self.name = name
        
        cbManagerDelegate = CentralManagerDelegate(subscription: subscription, factory: factory, eventHandler: eventHandler)
        cbManager = CBCentralManager(delegate: cbManagerDelegate, queue: nil)
    }
    
    public private(set) var name: String

    public var subscription: PeripheralSubscription {
        get {
            return cbManagerDelegate.subscription
        }
    }
    
    public var ready: Bool {
        get {
            return cbManagerDelegate.ready
        }
    }
    
    public func startScanning() throws {
        guard ready else { throw ErrorCode.notReady("Scanning may not be started until after the ready event has been delivered.") }
        
        cbManager.scanForPeripherals(withServices: subscription.getServiceUuids(), options: nil)
    }

    public func stopScanning() {
        if cbManager.isScanning { cbManager.stopScan() }
    }
}
