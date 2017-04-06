//
//  CentralManager.swift
//  Toolbox
//
//  Created by Robert Vaessen on 10/30/16.
//  Copyright © 2016 Robert Vaessen. All rights reserved.
//

import UIKit
import CoreBluetooth
import VerticonsToolbox

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
    private var cbManagerDelegate: CentralManagerDelegate? // We need to hang on to it because the CBCentralManager's delegate is a weak reference

    // If the subscription is empty then the Central Manager will report any and all peripherals;
    // else the Central Manager will only report those peripherals that provide the specified services.
    public init(subscription: PeripheralSubscription, factory: CentralManagerTypesFactory = DefaultFactory(), eventHandler: Event.Handler? = nil) {
        self.factory = factory
        self.subscription = subscription
        self.eventHandler = eventHandler
    }
    
    public var name: String {
        get {
            return subscription.name
        }
    }

    public let subscription: PeripheralSubscription
    
    public let factory: CentralManagerTypesFactory
    
    public internal(set) var isReady = false
    
    public var isScanning : Bool {
        get {
            return cbManager?.isScanning ?? false
        }
    }
    
    public private(set) var peripherals = [Peripheral]()

    // Setting the event handler to nil will stop events from coming (they will be discarded)
    private var _eventHandler: Event.Handler?
    public var eventHandler: Event.Handler? {
        get {
            return _eventHandler
        }
        set {
            lockObject(self) {
                _eventHandler = newValue
                if let _ = eventHandler, cbManager == nil { // Wait until we've got an event handler, else we're just "spinning our wheels".
                    cbManagerDelegate = CentralManagerDelegate(centralManager: self)
                    cbManager = CBCentralManager(delegate: cbManagerDelegate, queue: nil)
                }
            }
        }
    }
    
    internal func sendEvent(_ event: Event) {
        lockObject(self) {
            if case let .peripheralReady(peripheral) = event { peripherals.append(peripheral) }

            if let handler = eventHandler {
                handler(event)
            }
        }
    }

    public func startScanning() throws {
        guard isReady else { throw ErrorCode.notReady("Scanning may not be started until after the ready event has been delivered.") }
        
        cbManager?.scanForPeripherals(withServices: subscription.getServiceUuids(), options: nil)
    }

    public func stopScanning() {
        if isScanning { cbManager?.stopScan() }
    }
}
