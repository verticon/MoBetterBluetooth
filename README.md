# Mo Better Bluetooth
## A better (mo simple, mo intuitive) way to use iOS's Core Bluetooth functionality.

MoBetterBluetooth is a work in progress. It currently provides a mo better way to create central managers. Peripheral managers are coming. Beacon support is partially developed. When MoBetterBluetooth reaches version 1.0.0 then it will be ready for prime time.

Below is some sample code. See [ButtonLed](https://github.com/verticon/ButtonLed.git) for a complete example.

    import UIKit
    import CoreBluetooth
    import MoBetterBluetooth

    class ViewController: UIViewController, CentralManagerTypesFactory {

        private var manager: CentralManager!

        override func viewDidLoad() {
            super.viewDidLoad()

            // Subscribe to a service that provides access to an LED and a push button.

            let ledCharacteristicId = CentralManager.Identifier(uuid: CBUUID(string: "DCBA1523-1212-EFDE-1523-785FEF13D123"), name: "LED")
            let ledSubscription = CentralManager.CharacteristicSubscription(id: ledCharacteristicId, discoverDescriptors: false)

            let buttonCharacteristicId = CentralManager.Identifier(uuid: CBUUID(string: "DCBA1524-1212-EFDE-1523-785FEF13D123"), name: "Button")
            let buttonSubscription = CentralManager.CharacteristicSubscription(id: buttonCharacteristicId, discoverDescriptors: false)

            let buttonLedServiceId = CentralManager.Identifier(uuid: CBUUID(string: "DCBA3154-1212-EFDE-1523-785FEF13D123"), name: "ButtonLed")
            let buttonLedSubscription = CentralManager.ServiceSubscription(id: buttonLedServiceId, characteristics: [buttonSubscription, ledSubscription])

            let peripheralSubscription = CentralManager.PeripheralSubscription(services: [buttonLedSubscription])

            // Obtain a manager for the subscription
            manager = CentralManager(subscription: peripheralSubscription, factory: self) { event in

                switch event { // Respond to the manager's events

                    case .managerReady: // Core Bluetooth is available and ready to use

                        do {
                            try self.manager.startScanning()
                        }
                        catch {
                            print("Cannot start scanning: \(error).")
                        }

                    case .peripheralReady(let peripheral): // A peripheral matching the subscription has been found

                        self.manager.stopScanning()

                        let buttonLedService = peripheral[buttonLedServiceId]!
                        let ledCharacteristic = buttonLedService[ledCharacteristicId]!
                        let buttonCharacteristic = buttonLedService[buttonCharacteristicId]!

                        var ledOn = false

                        do { // Enable button press notifications
                            try buttonCharacteristic.notify(enabled: true) { result in

                                switch result { // Respond to a button press by toggling the LED.

                                    case .success:
                                        do {
                                            ledOn = !ledOn
                                            try ledCharacteristic.write(Data([ledOn ? 1 : 0])) { result in
                                                switch result {

                                                    case .success:
                                                        print("The LED was toggled \(ledOn ? "on" : "off")")

                                                    case .failure(let error):
                                                        print("The LED could not be toggled: \(error)")
                                                }
                                            }
                                        }
                                        catch {
                                            print("Cannot write the LED:  \(error)")
                                        }

                                    case .failure(let error):
                                        print("Button notifications produced an error: \(error).")
                                }
                            }
                        }
                        catch {
                            print("Cannot enable button notifications: \(error).")
                        }

                    default:
                        print("Central Manager Event - \(event).")
                }
            }
        }
    }


Notes:

* To include MoBetterBluetooth in your own projects:
  * Carthage - Add the following two lines to your project's Cartfile
    * github "verticon/VerticonsToolbox"
    * github "verticon/MoBetterBluetooth"
  * CocoaPods - Add the following two lines to your project's Podfile
    * pod 'VerticonsToolbox'
    * pod 'MoBetterBluetooth'


* To build MoBeterBluetooth:
  1. Clone the repository or download the zip archive.
  2. Execute the provided invokeCarthage shell script to build VerticonsToolbox.
  3. Copy VerticonsToolbox.framework from ../MoBetterBluetooth/Carthage/Build/iOS to ../MoBetterBluetooth.
  4. Open MoBetterBluetooth.xcodeproj and build.




[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
