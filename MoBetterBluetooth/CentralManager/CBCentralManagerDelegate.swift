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

        internal var centralManager: CentralManager! = nil // The CentralManager initializes it
        private var discoveredPeripherals = [String : PeripheralDelegate]()

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
                centralManager.sendEvent(.managerReady(centralManager))
                
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
                centralManager.sendEvent(.error(.bleNotSupported))
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

            let key = getKey(for: cbPeripheral)
            
            guard discoveredPeripherals[key] == nil else {
                centralManager.sendEvent(.peripheralRediscovered(cbPeripheral, advertisementData: data))
                return
            }
            
            let peripheral = centralManager.factory.makePeripheral(for: cbPeripheral, manager: centralManager, advertisementData: data)
            let delegate = PeripheralDelegate(centralManager: centralManager, peripheral: peripheral)
            self.discoveredPeripherals[key] = delegate
            cbPeripheral.delegate = delegate
            
            centralManager.sendEvent(.peripheralDiscovered(peripheral, rssi: signalStrength))

            if centralManager.subscription.autoConnect && peripheral.connectable {
                manager.connect(cbPeripheral, options: nil)
                centralManager.sendEvent(.peripheralStateChange(peripheral)) // disconnected => connecting
            }
            else {
                centralManager.sendEvent(.peripheralReady(peripheral))
                
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
            let key = getKey(for: cbPeripheral)
            guard let delegate = discoveredPeripherals[key] else {
                centralManager.sendEvent(.error(.peripheralNotRecognized(cbPeripheral)))
                return
            }
            let peripheral = delegate.peripheral

            if let handler = peripheral.connectCompletionhandler {
                peripheral.connectCompletionhandler = nil
                handler(peripheral, .success)
            }

            if centralManager.subscription.autoDiscover {
                let serviceUuids = centralManager.subscription.getServiceUuids()
                peripheral.cbPeripheral.discoverServices(serviceUuids)
            }
            else {
                centralManager.sendEvent(.peripheralReady(peripheral))
            }

            centralManager.sendEvent(.peripheralStateChange(delegate.peripheral)) // connecting => connected
        }
        
        @objc func centralManager(_ manager: CBCentralManager, didFailToConnect cbPeripheral: CBPeripheral, error: Error?) {
            let key = getKey(for: cbPeripheral)
            guard let delegate = discoveredPeripherals[key] else {
                centralManager.sendEvent(.error(.peripheralNotRecognized(cbPeripheral)))
                return
            }
            let peripheral = delegate.peripheral

            let centralManagerError = CentralManagerError.peripheralFailedToConnect(peripheral, cbError: error)
            
            if let handler = peripheral.connectCompletionhandler {
                peripheral.connectCompletionhandler = nil
                handler(peripheral, .failure(centralManagerError))
            }
            
            centralManager.sendEvent(.error(centralManagerError))

            centralManager.sendEvent(.peripheralStateChange(delegate.peripheral)) // connecting => disconnected
        }
        
        // TODO: Cleanup? From the Apple documentation: Note that when a peripheral is disconnected, all of its services, characteristics, and characteristic descriptors are invalidated.
        @objc func centralManager(_ manager: CBCentralManager, didDisconnectPeripheral cbPeripheral: CBPeripheral, error: Error?) {
            let key = getKey(for: cbPeripheral)
            guard let delegate = discoveredPeripherals[key] else {
                centralManager.sendEvent(.error(.peripheralNotRecognized(cbPeripheral)))
                return
            }
            let peripheral = delegate.peripheral

            // If there is a disconnect completion handler then we are here because a disconnect was requested.
            // Else we are here because of an erroneous disconnection. What if we have both a handler AND an error?

            if let handler = peripheral.disconnectCompletionhandler {
                peripheral.disconnectCompletionhandler = nil
                handler(peripheral, .success)
                
                if let cbError = error {
                    print("didDisconnectPeripheral: We have both a disconnection handler AND an error (\(cbError))???")
                }
            }

            if let error = error {
                centralManager.sendEvent(.error(.peripheralDisconnected(peripheral, cbError: error)))
            }

            centralManager.sendEvent(.peripheralStateChange(delegate.peripheral)) // disconnecting => disconnected, or connected => disconnected
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
