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

* The MoBetterBluetooth framework's xcode project includes a subprojects which are in the submodules of the framework's GitHub repository. Therefore, clone the framework's repository using the --recursive option so as to obtain the submodules. Downloading the ZIP archive will not work; it does not capture the submodules.

* Dependency Managers:
    * CocoaPods: There are pods for MoBetterBluetooth and its dependencies.

    * Carthage: You can add `github "verticon/MoBetterBluetooth" ~> x.x.x` to your Cartfile. `carthage  update` will build MoBetterBlutooth and its dependencies. As usual, you will find the binaries in Carthage/Build and the project files in Carthage/Checkouts. A consequence of using submodules is that the dependency projects will exist in two places: Carthage/Checkouts and Carthage/Checkouts/MoBeterBluetooth/Carthage/Checkouts. If you choose to ad the MoBetterBlutooth project to your xcode project/workspace then you only need to add /Carthage/Checkouts/MoBetterBluetooth/MoBetterBlutooth.xcodeproj; doing so will give you everything.

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
