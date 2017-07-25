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

        private var centralManager: CentralManager

        internal var peripheraDelegates = [String : PeripheralDelegate]()
        
        internal init(centralManager: CentralManager) {
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
                centralManager.sendEvent(.ready(centralManager))
                
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

            let advertisement = Advertisement(data)
            let key = getKey(for: cbPeripheral)
            var delegate = peripheraDelegates[key]

            if let peripheral = delegate?.peripheral {
                peripheral.updateReceived(newAdvertisement: advertisement, newRssi: signalStrength)
                return
            }
            
            let peripheral = centralManager.factory.makePeripheral(for: cbPeripheral, manager: centralManager, advertisement: advertisement, rssi: signalStrength)
            delegate = PeripheralDelegate(centralManager: centralManager, peripheral: peripheral)
            self.peripheraDelegates[key] = delegate
            
            centralManager.sendEvent(.peripheralDiscovered(peripheral))

            if centralManager.subscription.autoConnect && peripheral.connectable {
                manager.connect(cbPeripheral, options: nil)
                peripheral.sendEvent(.stateChanged(peripheral)) // disconnected => connecting
            }


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
        
        @objc func centralManager(_ manager: CBCentralManager, didConnect cbPeripheral: CBPeripheral) {
            let key = getKey(for: cbPeripheral)
            guard let delegate = peripheraDelegates[key] else { fatalError("Unrecognized peripheral - \(cbPeripheral)") }
            let peripheral = delegate.peripheral

            if let handler = peripheral.connectCompletionhandler {
                peripheral.connectCompletionhandler = nil
                handler(peripheral, .success)
            }

            if centralManager.subscription.autoDiscover {
                let serviceUuids = centralManager.subscription.getServiceUuids()
                peripheral.cbPeripheral.discoverServices(serviceUuids)
            }

            peripheral.sendEvent(.stateChanged(peripheral)) // connecting => connected
        }
        
        @objc func centralManager(_ manager: CBCentralManager, didFailToConnect cbPeripheral: CBPeripheral, error: Error?) {
            let key = getKey(for: cbPeripheral)
            guard let delegate = peripheraDelegates[key] else { fatalError("Unrecognized peripheral - \(cbPeripheral)") }
            let peripheral = delegate.peripheral

            let centralManagerError = CentralManagerError.peripheralFailedToConnect(peripheral, cbError: error)
            
            if let handler = peripheral.connectCompletionhandler {
                peripheral.connectCompletionhandler = nil
                handler(peripheral, .failure(centralManagerError))
            }
            
            centralManager.sendEvent(.error(centralManagerError))

            peripheral.sendEvent(.stateChanged(delegate.peripheral)) // connecting => disconnected
        }

        // TODO: If the subscription has Auto Connect on then should a disconnect automatically trigger a reconnect?
        @objc func centralManager(_ manager: CBCentralManager, didDisconnectPeripheral cbPeripheral: CBPeripheral, error: Error?) {
            let key = getKey(for: cbPeripheral)
            guard let delegate = peripheraDelegates[key] else { fatalError("Unrecognized peripheral - \(cbPeripheral)") }
            let peripheral = delegate.peripheral

            peripheral.services.removeAll()
            peripheral.servicesDiscovered = false
            peripheral.servicesDiscoveryInProgress = false

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

            peripheral.sendEvent(.stateChanged(delegate.peripheral)) // disconnecting => disconnected, or connected => disconnected
        }
 
        internal func removePeripheral(_ peripheral: Peripheral) -> Bool {
            for (key, value) in peripheraDelegates {
                if (value.peripheral === peripheral) {
                    self.peripheraDelegates.removeValue(forKey: key);
                    return true
                }
            }
            return false
        }

        private func getKey(for cbPeripheral: CBPeripheral) -> String {
            return cbPeripheral.identifier.uuidString
        }
        
        // TODO: Create a Blacklisting API
        private func blackListed(_ name: String?) -> Bool {
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
