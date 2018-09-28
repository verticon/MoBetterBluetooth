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
    
    public class DefaultFactory : CentralManagerTypesFactory { public init() {} }
    
    // Instance Members **********************************************************************************************

    internal var cbManager: CBCentralManager!
    private var cbManagerDelegate: CentralManagerDelegate! // We need to hang on to it because the CBCentralManager's delegate is a weak reference

    // If the subscription is empty then the Central Manager will report any and all peripherals;
    // else the Central Manager will only report those peripherals that provide the specified services.
    // TODO: How are we gauranteeing that the Ready event will be received?
    public init(subscription: PeripheralSubscription, factory: CentralManagerTypesFactory = DefaultFactory()) {
        self.factory = factory
        super.init()

        self.subscription = subscription
    }
    
    public var name: String {
        get {
            return subscription.name
        }
    }

    // TODO: Double check this by actually modifing a subscription
    private var _subscription: PeripheralSubscription!
    public var subscription: PeripheralSubscription {
        get {
            return _subscription
        }
        set {
            let wasScanning = isScanning
            
            if cbManager == nil {
                cbManager = CBCentralManager(delegate: nil, queue: dispatchQueue)
            }
            else {
                _ = stopScanning()
                cbManager.delegate = nil
                for peripheral in peripherals { _ = removePeripheral(peripheral) }
                cbManagerDelegate = nil
            }
            _subscription = newValue
            cbManagerDelegate = CentralManagerDelegate(centralManager: self)
            cbManager.delegate = cbManagerDelegate
            if wasScanning { _ = startScanning() }
            sendEvent(.subscriptionUpdated(self))
        }
    }

    internal var dispatchQueue: DispatchQueue {
        get {
            return DispatchQueue.main
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
            return (cbManager?.isScanning) ?? false
        }
    }
    
    public var peripherals: Set<Peripheral> {
        get {
            return Set<Peripheral>(cbManagerDelegate.peripheraDelegates.values.map { $0.peripheral })
        }
    }

    public func removePeripheral(_ peripheral: Peripheral) -> Bool {
        let status = cbManagerDelegate.removePeripheral(peripheral)
        if status { sendEvent(.peripheralRemoved(peripheral)) }
        return status
    }
    
    internal func sendEvent(_ event: CentralManagerEvent) {
        broadcast(event)
    }

    public func startScanning() -> CentralManagerStatus {
        guard isReady else { return .failure(.notReady) }
        
        let serviceUuids = subscription.getServiceUuids()
        cbManager.scanForPeripherals(withServices: serviceUuids, options: [CBCentralManagerScanOptionAllowDuplicatesKey : NSNumber(value: subscription.monitorAdvertisements)])
        sendEvent(.startedScanning((self, serviceUuids)))

        peripherals.forEach { $0.updateReceptionState() }

        return .success
    }

    // Return true(false) if the CB manager was(was not) scanning
    public func stopScanning() -> Bool {
        if !isScanning { return false }
        
        cbManager.stopScan()
        sendEvent(.stoppedScanning(self))

        peripherals.forEach { $0.updateReceptionState() }

        return true
    }

    public var description : String {
        return "\(name) - \(String(describing: cbManager))"
    }
}
