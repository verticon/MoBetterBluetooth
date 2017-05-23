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
 *  2. Set the eventHandler - Doing this initiates checking if bluetovar is available and permissioned; culminating in the Ready event.
 *  3. Call startScanning().
 */

public class CentralManager : Broadcaster<CentralManagerEvent>, CustomStringConvertible {
    
    private class DefaultFactory : CentralManagerTypesFactory {}
    
    // Instance Members **********************************************************************************************

    internal var cbManager: CBCentralManager
    private var cbManagerDelegate: CentralManagerDelegate // We need to hang on to it because the CBCentralManager's delegate is a weak reference

    // If the subscription is empty then the Central Manager will report any and all peripherals;
    // else the Central Manager will only report those peripherals that provide the specified services.
    // TODO: How are we gauranteeing that the Ready event will be received?
    public init(subscription: PeripheralSubscription, factory: CentralManagerTypesFactory = DefaultFactory()) {
        self.factory = factory
        _subscription = subscription
        cbManagerDelegate = CentralManagerDelegate()
        cbManager = CBCentralManager(delegate: nil, queue: nil)
        super.init()

        cbManagerDelegate.centralManager = self
        cbManager.delegate = cbManagerDelegate
    }
    
    public var name: String {
        get {
            return subscription.name
        }
    }

    // Changing the subscription results in the current cbManager being discarded and a new one being created.
    // This is done so as to discard any existing peripherals that might not match the new subscription.
    // It is up to the application to restart scanning, if desired, after receiving the new manager's ready event.
    // TODO: Is there a better way?
    // TODO: Double check this by actually modifing a subscription
    private var _subscription: PeripheralSubscription
    public var subscription: PeripheralSubscription {
        get {
            return _subscription
        }
        set {
            let _ = stopScanning()
            peripherals.removeAll()
            _subscription = newValue
            cbManagerDelegate = CentralManagerDelegate()
            cbManagerDelegate.centralManager = self
            cbManager = CBCentralManager(delegate: cbManagerDelegate, queue: nil)
            sendEvent(.updatedSubscription(self))
        }
    }

    public let factory: CentralManagerTypesFactory
    
    public var isReady: Bool {
        get {
            return cbManager.state == .poweredOn
        }
    }
    
    public var isScanning : Bool {
        get {
            return cbManager.isScanning
        }
    }
    
    public private(set) var peripherals = [Peripheral]()
    
    internal func sendEvent(_ event: CentralManagerEvent) {
        if case let .peripheralDiscovered((peripheral,_)) = event { peripherals.append(peripheral) }
        
        broadcast(event)
    }

    public func startScanning() -> CentralManagerStatus {
        guard isReady else { return .failure(.notReady) }
        
        let serviceUuids = subscription.getServiceUuids()
        cbManager.scanForPeripherals(withServices: serviceUuids, options: nil)
        sendEvent(.startedScanning(self, serviceUuids))

        return .success
    }

    // Return true(false) if the CB manager was(was not) scanning
    public func stopScanning() -> Bool {
        if !isScanning { return false }
        
        cbManager.stopScan()
        sendEvent(.stoppedScanning(self))

        return true
    }

    public var description : String {
        return "\(name) \(cbManager)"
    }
}
