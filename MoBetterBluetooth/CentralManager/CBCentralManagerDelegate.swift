//
//  CBCentralManagerDelegate.swift
//  Toolbox
//
//  Created by Robert Vaessen on 10/30/16.
//  Copyright © 2016 Robert Vaessen. All rights reserved.
//

import UIKit
import CoreBluetooth

extension CentralManager {
    class CentralManagerDelegate : NSObject, CBCentralManagerDelegate {

        private let centralManager: CentralManager
        private var discoveredPeripherals = [String : PeripheralDelegate]()
        
        init(centralManager: CentralManager) {
            self.centralManager = centralManager
        }
        
        // This method is invoked when the CentralManager's delegate is set. It is also invoked whenever the Settings app is used to turn Bluetooth On/Off.
        // If the app is in the foreground and bluetooth is turned On/Off then the invocation occurs immediately. If the app is in the
        // background then the timing of the invocation is determined by the Background Mode setting "Uses Bluetooth LE accessories". If
        // the setting is on then the invocation occurs immediately; else the invocation is deferred until the app is restored to the foreground.
        //
        // 1) Do not initiate scanning until this method has been called.
        //
        @objc func centralManagerDidUpdateState(_ manager: CBCentralManager) {
            
            switch manager.state {
            case CBManagerState.poweredOn:
                centralManager.ready = true
                centralManager.sendEvent(Event.managerReady())
                
            case CBManagerState.poweredOff:
                /* We are not setting the CBCentralManagerState initialization option CBCentralManagerOptionShowPowerAlertKey
                 * to false so we do not need to prompt the user, the CentrlManager will do it.
                 *
                 let alert = UIAlertController(title: "Bluetooth Needed", message: "Please turn bluetooth on so that \(applicationName) can function properly", preferredStyle: UIAlertControllerStyle.Alert)
                 alert.addAction(UIAlertAction(title: "Settings", style: UIAlertActionStyle.Default) { _ in
                 if let url = NSURL(string:UIApplicationOpenSettingsURLString) {
                 UIApplication.sharedApplication().openURL(url)
                 }
                 })
                 alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: nil))
                 UIApplication.sharedApplication().delegate?.window??.rootViewController?.presentViewController(alert, animated: true, completion: nil)
                 */
                break
                
            case CBManagerState.unauthorized: // Not sure what to do here
                break
                
            case CBManagerState.resetting:
                break
                
            case CBManagerState.unknown:
                break
                
            case CBManagerState.unsupported:
                centralManager.sendEvent(Event.error(ErrorCode.bleNotSupported))
                break
            }
        }
        
        @objc func centralManager(_ manager: CBCentralManager, willRestoreState state: [String : Any]) {
            var infoMessage: String
            infoMessage  = "CBCentralManager restoring state:\n"
            for entry in state {
                infoMessage += "\t\(entry.0) = \(entry.1)\n"
            }
            print(infoMessage )
        }
        
        @objc func centralManager(_ manager: CBCentralManager, didDiscover cbPeripheral: CBPeripheral, advertisementData data: [String : Any], rssi signalStrength: NSNumber) {
            guard !blackListed(cbPeripheral.name) else { return }
            
            let key = getKey(for: cbPeripheral)
            
            if let peripheralDelegate = discoveredPeripherals[key] {
                centralManager.sendEvent(Event.error(ErrorCode.internalError("Peripheral \(peripheralDelegate.peripheral.name) was rediscovered???")))
                return
            }
            
            let peripheral = centralManager.factory.makePeripheral(for: cbPeripheral, advertisementData: data as [String : AnyObject], signalStrength: signalStrength)
            let delegate = PeripheralDelegate(centralManager: centralManager, peripheral: peripheral)
            self.discoveredPeripherals[key] = delegate
            cbPeripheral.delegate = delegate
            
            if isConnectable(data as [String : AnyObject]) {
                manager.connect(cbPeripheral, options: nil)
            }
            else {
                centralManager.sendEvent(Event.peripheralReady(peripheral))
                
                // TODO: Revisit the scenario of a non Apple beacon
                /*
                 infoMessage += "Manufacturer Specific Data:\n"
                 if let manufacturerStrings = decodeManufacturerSpecificData(advertisementData: data) {
                 for string in manufacturerStrings {
                 infoMessage += "\t\(string)\n"
                 }
                 }
                 */
            }
            
        }
        
        @objc func centralManager(_ manager: CBCentralManager, didConnect cbPeripheral: CBPeripheral) {
            let serviceUuids = centralManager.subscription.getServiceUuids()
            cbPeripheral.discoverServices(serviceUuids)
        }
        
        @objc func centralManager(_ manager: CBCentralManager, didFailToConnect cbPeripheral: CBPeripheral, error: Error?) {
            let key = getKey(for: cbPeripheral)
            let delegate = discoveredPeripherals[key]!
            let theError = ErrorCode.peripheral("Failed to connect to the peripheral \(delegate.peripheral.name)", delegate.peripheral, error)
            centralManager.sendEvent(Event.error(theError))
        }
        
        // TODO: Cleanup? From the Apple documentation: Note that when a peripheral is disconnected, all of its services, characteristics, and characteristic descriptors are invalidated.
        @objc func centralManager(_ manager: CBCentralManager, didDisconnectPeripheral cbPeripheral: CBPeripheral, error: Error?) {
            let key = getKey(for: cbPeripheral)
            let delegate = discoveredPeripherals[key]!
            centralManager.sendEvent(Event.peripheralDisconnected((peripheral: delegate.peripheral, coreBluetoothError: error)))
        }
        
        func getKey(for cbPeripheral: CBPeripheral) -> String {
            return cbPeripheral.identifier.uuidString
        }
        
        // TODO: Create a Blacklisting API
        func blackListed(_ name: String?) -> Bool {
            if let name = name {
                switch name {
                case "Apple TV", "Robert's MacBook Pro":
                    return true
                default:
                    return false
                }
            }
            return false
        }
    }
}
