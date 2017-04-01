//
//  CentralManager.swift
//  Toolbox
//
//  Created by Robert Vaessen on 10/30/16.
//  Copyright © 2016 Robert Vaessen. All rights reserved.
//

import UIKit
import CoreBluetooth

/*
 *  1. Create a CentralManager
 *  2. Set the eventHandler - Doing this initiates checking if bluetooth is available and permissioned; culminating in the Ready event.
 *  3. Call startScanning().
 */
public class CentralManager {

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
    
    private class DefaultFactory : CentralManagerTypesFactory {}
    
    // Instance Members **********************************************************************************************

    private var cbManager: CBCentralManager?

    // If the subscription is empty then the Central Manager will report any and all peripherals;
    // else the Central Manager will only report those peripherals that provide the specified services.
    public init(subscription: PeripheralSubscription, factory: CentralManagerTypesFactory = DefaultFactory()) {
        self.subscription = subscription
        self.factory = factory
        ready = false
    }
    
    public var name: String {
        get {
            return subscription.name
        }
    }

    public private(set) var subscription: PeripheralSubscription
    
    public private(set) var factory: CentralManagerTypesFactory
    
    public internal(set) var ready: Bool

    public var eventHandler: Event.Handler? {
        didSet {
            if let _ = eventHandler, cbManager == nil { // Once we've got an event handler we can do something useful. Otherwise we're just spinning internally.
                cbManager = CBCentralManager(delegate: CentralManagerDelegate(centralManager: self), queue: nil)
            }
        }
    }
    
    public func startScanning() throws {
        guard ready else { throw ErrorCode.notReady("Scanning may not be started until after the ready event has been delivered.") }
        
        cbManager?.scanForPeripherals(withServices: subscription.getServiceUuids(), options: nil)
    }

    public func stopScanning() {
        if let _ = cbManager?.isScanning { cbManager?.stopScan() }
    }
}
