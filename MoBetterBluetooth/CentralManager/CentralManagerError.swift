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
public enum CentralManagerError : Error {
    case notReady
    case bleNotSupported
    
    case notConnectable
    case notDisconnected
    
    case peripheralNotRecognized(CBPeripheral)
    case peripheralRediscovered(CBPeripheral, advertisementData: [String : Any])
    case peripheralFailedToConnect(CentralManager.Peripheral, cbError: Error?)
    
    case serviceDiscoveryError(CentralManager.Peripheral, cbError: Error)
    case serviceDiscoveryRepeated(CentralManager.Peripheral)
    case serviceDiscoverySubscriptionMismatch(CentralManager.Peripheral, CBService)
    case serviceDiscoveryNoServices(CentralManager.Peripheral)
    
    case charactericticDiscoveryUnrecognizedService(CentralManager.Peripheral, CBService)
    case charactericticDiscoveryError(CentralManager.Service, cbError: Error)
    case characteristicDiscoveryRepeated(CentralManager.Service)
    case characteristicDiscoverySubscriptionMismatch(CentralManager.Service, CBCharacteristic)
    case characteristicDiscoveryNoCharacteristics(CentralManager.Service)
    
    case descriptorDiscoveryUnrecognizedCharacterictic(CentralManager.Peripheral, CBCharacteristic)
    case descriptorDiscoveryError(CentralManager.Characteristic, cbError: Error)
    case descriptorDiscoveryRepeated(CentralManager.Characteristic)
    
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
