//
//  CentralManagerError.swift
//  MoBetterBluetooth
//
//  Created by Robert Vaessen on 4/10/17.
//  Copyright © 2017 Verticon. All rights reserved.
//

import Foundation
import CoreBluetooth

// The majority of these errors result from sanity checks performed by the delegates.
// TODO: Consider whether some of the sanity checks should instead result in a fatal error.
public enum CentralManagerError : Error {

    case notReady
    case bleNotSupported
    
    case peripheralNotRecognized(CBPeripheral)
    case peripheralFailedToConnect(CentralManager.Peripheral, cbError: Error?)
    case peripheralDisconnected(CentralManager.Peripheral, cbError: Error)
}

public enum PeripheralError : Error {

    case notConnectable
    case notConnected
    case notDisconnected
    
    case servicesDiscoveryError(CentralManager.Peripheral, cbError: Error)
    case servicesRediscovered(CentralManager.Peripheral)
    case servicesDiscoverySubscriptionMismatch(CentralManager.Peripheral, CBService)
    case servicesDiscoveryNoServices(CentralManager.Peripheral)
    
    case charactericticsDiscoveryUnrecognizedService(CentralManager.Peripheral, CBService)
    case charactericticsDiscoveryError(CentralManager.Service, cbError: Error)
    case characteristicsRediscovered(CentralManager.Service)
    case characteristicsDiscoverySubscriptionMismatch(CentralManager.Service, CBCharacteristic)
    case characteristicsDiscoveryNoCharacteristics(CentralManager.Service)
    
    case descriptorsDiscoveryUnrecognizedCharacterictic(CentralManager.Peripheral, CBCharacteristic)
    case descriptorsDiscoveryError(CentralManager.Characteristic, cbError: Error)
    case descriptorsRediscovered(CentralManager.Characteristic)
    
    case updateValueUnrecognizedCharacterictic(CentralManager.Peripheral, CBCharacteristic)
    case writeValueUnrecognizedCharacterictic(CentralManager.Peripheral, CBCharacteristic)
    case updateNotificationUnrecognizedCharacterictic(CentralManager.Peripheral, CBCharacteristic)
    
    case updateValueUnrecognizedDescriptor(CentralManager.Peripheral, CBDescriptor)
    case writeValueUnrecognizedDescriptor(CentralManager.Peripheral, CBDescriptor)
    
    case notReadable(CentralManager.Characteristic)
    case readInProgress(CentralManager.Characteristic)
    case readError(CentralManager.Characteristic, cbError: Error)
    case notNotifiable(CentralManager.Characteristic)
    case nilNotificationHandler(CentralManager.Characteristic)
    case cannotNotify(CentralManager.Characteristic, cbError: Error)
    case notWriteable(CentralManager.Characteristic)
    case writeInProgress(CentralManager.Characteristic)
    case writeError(CentralManager.Characteristic, cbError: Error)
}
