//
//  CentralManagerError.swift
//  MoBetterBluetooth
//
//  Created by Robert Vaessen on 4/10/17.
//  Copyright © 2017 Verticon. All rights reserved.
//

import Foundation
import CoreBluetooth

public enum CentralManagerError : Error {

    case notReady
    case bleNotSupported
    
    case peripheralFailedToConnect(CentralManager.Peripheral, cbError: Error?)
    case peripheralDisconnected(CentralManager.Peripheral, cbError: Error)
}

public enum PeripheralError : Error {

    case notConnectable
    case notDisconnected
    case notConnected
    
    case cbAttributeIsNil
    case rediscoveryNotAllowed

    case handlerCannotBeNil

    case servicesDiscoveryError(CentralManager.Peripheral, cbError: Error)
    case charactericticsDiscoveryError(CentralManager.Service, cbError: Error)
    case descriptorsDiscoveryError(CentralManager.Characteristic, cbError: Error)

    // So far I have only tested performing attribute reads and writes on the main thread.
    // I have observed that core bluetooth executes the callbacks on the main thread.
    // What would happen if a read or write were issued from another thread: would the
    // callback occur on that thread? Also, I have written code that is not thread
    // safe: it assumes that reads, writes, and callbacks always occur on the same thread.
    case notMainThread

    case notReadable
    case readInProgress
    case characteristicReadError(CentralManager.Characteristic, cbError: Error)
    case descriptorReadError(CentralManager.Descriptor, cbError: Error)

    case notWriteable
    case writeInProgress
    case characteristicWriteError(CentralManager.Characteristic, cbError: Error)
    case descriptorWriteError(CentralManager.Descriptor, cbError: Error)

    case notNotifiable
    case characteristicNotifyError(CentralManager.Characteristic, cbError: Error)
}
