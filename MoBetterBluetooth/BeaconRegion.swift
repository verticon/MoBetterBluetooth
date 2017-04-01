//
//  BeaconRegion.swift
//  BluetoothExplorer
//
//  Created by Robert Vaessen on 12/23/15.
//  Copyright © 2015 Robert Vaessen. All rights reserved.
//

import Foundation
import CoreLocation
import VerticonsToolbox

func ==(lhs: BeaconRegion, rhs: BeaconRegion) -> Bool { return lhs.uuid == rhs.uuid }

open class BeaconRegion : NSObject, NSCoding {

    // Types *********************************************************************************************************

    public enum Event {
        case startedMonitoring
        case enteredRegion
        case startedRanging
        case addedBeacon
        case changedBeaconProximity
        case stoppedRanging
        case exitedRegion
        case stoppedMonitoring
        
        public func describeEvent(_ region: BeaconRegion, beacon: BeaconRegion.Beacon?) -> String {
            switch self {
            case .enteredRegion:
                return "The \(region.name) region was entered"
            case .startedMonitoring:
                return "Monitoring of the \(region.name) region started"
            case .startedRanging:
                return "Ranging of the \(region.name) region started"
            case .addedBeacon:
                return "\(region.name) beacon \(beacon!.identifier) was added with proximity \(nameForProximity(beacon!.currentProximity))"
            case .changedBeaconProximity:
                return "\(region.name) beacon \(beacon!.identifier)'s proximity was changed to \(nameForProximity(beacon!.currentProximity))"
            case .stoppedRanging:
                return "Ranging of the \(region.name) region stopped"
            case .stoppedMonitoring:
                return "Monitoring of the \(region.name) region stopped"
            case .exitedRegion:
                return "The \(region.name) region was exited"
            }
        }
    }

    open class Beacon {
        fileprivate static var nextBeaconIndex = 0
        
        class func beaconAtIndex(_ index: Int) -> BeaconRegion? {
            return index < regions.count ? regions.filter() { $0.1.index == index }[0].1 : nil
        }
        
        class func makeKey(_ identifier: (major: Int, minor: Int)) -> Int {
            return identifier.major << 16 + identifier.minor
        }

        open let index: Int
        open let identifier: (major: Int, minor: Int)

        let beacon: CLBeacon
        let parent: BeaconRegion
        
        init(beacon: CLBeacon, identifier: (major: Int, minor: Int), region: BeaconRegion) {
            self.beacon = beacon
            self.identifier = identifier
            currentProximity = beacon.proximity
            self.parent = region
            index = Beacon.nextBeaconIndex
            Beacon.nextBeaconIndex += 1
        }
        
        open fileprivate(set) var currentProximity: CLProximity {
            didSet(oldValue) {
                if currentProximity != oldValue {
                    parent.fireEvent(.changedBeaconProximity, beacon: self)
                }
            }
        }
    }

    public typealias Listener =  (BeaconRegion, Event, Beacon?) -> ()

    fileprivate class LocationManagerDelegate: NSObject, CLLocationManagerDelegate {
        
        // Even though the documentation states that this callback is only invoked when the authorization
        // status changes, testing reveals that it is always called upon startup regardless of any changes.
        @objc func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
            print("LocationManagerDelegate - Authorization status updated to \(nameForAuthorizationStatus(status)).")
            
            switch status {
                case CLAuthorizationStatus.notDetermined:
                    manager.requestAlwaysAuthorization()
                    break
                    
                case CLAuthorizationStatus.authorizedAlways:
                   break
                    
                default:
                    alertUser(title: "Location Services Needed", body: "Please set location access to \"Always\" so that beacons can be reliably detected")
                    break
            }
        }
        
        @objc func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
            print("LocationManagerDelegate - Location manager failure, error:  \(error)")
        }
        
        @objc func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
            print("LocationManagerDelegate - Monitoring of the \"\(region.identifier)\" region has started")
        }
        
        @objc func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
            print("LocationManagerDelegate - The state of the \(region.identifier) \(type(of: region)) region is \(nameForRegionState(state))")
            
            if let clRegion = region as? CLBeaconRegion, let beaconRegion = BeaconRegion.regions[clRegion.proximityUUID] {
                switch state {
                    case CLRegionState.inside:
                        beaconRegion.locatedInside = true
                        
                    case CLRegionState.outside:
                        beaconRegion.locatedInside = false
                        
                    case CLRegionState.unknown:
                        break
                }
            }
        }

        @objc func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
            print("LocationManagerDelegate - Monitoring failed for the \"\(String(describing: region?.identifier))\" region: \(error)")
        }
        
        @objc func locationManager(_ manager: CLLocationManager, rangingBeaconsDidFailFor region: CLBeaconRegion, withError error: Error) {
            print("LocationManagerDelegate - Beacon ranging failed for the \"\(region.identifier)\", \(region.proximityUUID) region: \(error)")
        }
        
        @objc func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
            if let region = BeaconRegion.regions[region.proximityUUID] {
                for clBeacon in beacons {
                    region.addOrUpdateBeacon(clBeacon)
                }
            }
            else {
                print("LocationManagerDelegate - An unknown region was ranged: identifier= \(region.identifier), UUID = \(region.proximityUUID)")
            }
        }
    }

    // Class Members *************************************************************************************************

    open static let invalidListenerKey = -1

    fileprivate static var locationManagerDelegate: LocationManagerDelegate? // Retain the delegate
    fileprivate static var locationManager: CLLocationManager? = {
        if CLLocationManager.locationServicesEnabled() {
            if (CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self)) {
                if CLLocationManager.isRangingAvailable() {
                    let manager = CLLocationManager()

                    //manager.distanceFilter = 0.5
                    // Setup the manager such that beacon ranging can occur in the background
                    manager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
                    manager.allowsBackgroundLocationUpdates = true
                    manager.startUpdatingLocation()
 
                    locationManagerDelegate = LocationManagerDelegate()
                    manager.delegate = locationManagerDelegate

                    return manager
                }
                else {
                    alertUser(title: "Cannot Work With Beacons", body: "Ranging is not available.")
                }
            }
            else {
                alertUser(title: "Cannot Work With Beacons", body: "Region monitoring is not available.")
            }
        }
        else {
            alertUser(title: "Cannot Work With Beacons", body: "Location services are not enabled.")
        }
        return nil
    }()
    fileprivate static var nextListenerKey = 0
    fileprivate static var listeners: [Int : Listener] = [:]
    fileprivate static var nextRegionIndex = 0
    fileprivate static let regionsArchiveFilePath: String = {
        let fileName = "BeaconRegion.archive";
        let pathes = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true);
        let url = URL(fileURLWithPath: pathes[0]).appendingPathComponent(fileName)
        return url.path
    }()
    fileprivate static var regions: [UUID : BeaconRegion] = {
        var regions = [UUID : BeaconRegion]()

        if let manager = locationManager {

            func addRegion(_ region: AnyObject) {
                var localRegion = region
                if let clBeaconRegion = localRegion as? CLBeaconRegion {
                    localRegion = BeaconRegion(region: clBeaconRegion, manager: manager)
                }
                if let beaconRegion = localRegion as? BeaconRegion {
                    if regions[beaconRegion.uuid] == nil {
                        beaconRegion.index = nextRegionIndex
                        nextRegionIndex += 1
                        regions[beaconRegion.uuid] = beaconRegion;
                    }
                }
            }

            for monitoredRegion in manager.monitoredRegions {
                addRegion(monitoredRegion)
                manager.requestState(for: monitoredRegion)
            }
            
            for rangedRegion in manager.rangedRegions {
                addRegion(rangedRegion)
            }
            
            if let archivedRegions = NSKeyedUnarchiver.unarchiveObject(withFile: regionsArchiveFilePath) as? [BeaconRegion] {
                for archivedRegion in archivedRegions {
                    addRegion(archivedRegion)
                }
            }

            var message = "There \(regions.count == 1 ? "is" : "are") \(regions.count) beacon \(regions.count == 1 ? "region" : "regions")"
            for (uuid, region) in regions {
                message.append("\n\t\(region.name) <\(region.uuid.uuidString)> - monitored \(region.isMonitoring ? "yes": "no"), ranged \(region.isRanging ? "yes": "no")")
            }
            print(message)
            
        }
        else {
            print("BeaconRegion - a Location Manager cnnnot be obtained; one or more of the required capabilities are not available")
        }
        
        return regions
    }()
    fileprivate static let nameKey = "Name"
    fileprivate static let uuidKey = "UUID"

    // This needs some more thought ...
    open class func restore() -> Int {
        return numberOfRegions
    }

    open class var numberOfRegions: Int {
        get {
            return regions.count
        }
    }
    
    open class func addRegion(_ name: String, uuid: UUID, errorDescription: inout String) -> BeaconRegion? {
        if let manager = locationManager {
            if regions[uuid] == nil {
                let region = BeaconRegion(name: name, uuid: uuid, manager: manager)
                region.index = nextRegionIndex; nextRegionIndex += 1
                regions[uuid] = region
                saveRegions()
                return region
            }
            else {
                errorDescription = "The \"\(name)\" region's UUID [\(uuid.uuidString)] is already being used by the \"\(regions[uuid]!.name)\" region"
                return nil
            }
        }
        else {
            errorDescription = "Cannot obtain a Location Manager: one or more of the required capabilities are not available"
            return nil
        }
    }
    
    open class func regionAtIndex(_ index: Int) -> BeaconRegion? {
        return index < numberOfRegions ? regions.filter() { $0.1.index == index }[0].1 : nil
    }

    // The listener will be called for an event on any and all regions.
    // The returned value can be used to remove the listener
    open class func addListener(_ listener: @escaping Listener) -> Int {
        let key = nextListenerKey; nextListenerKey += 1
        listeners[key] = listener
        return key
    }
    
    open class func removeListener(_ key: Int) -> Bool {
        return listeners.removeValue(forKey: key) != nil ? true : false
    }

    fileprivate class func saveRegions() {
        NSKeyedArchiver.archiveRootObject(Array(regions.values), toFile: regionsArchiveFilePath)
    }

    // Instance Members **********************************************************************************************

    open var index: Int!

    fileprivate let manager: CLLocationManager
    fileprivate let clRegion: CLBeaconRegion
    fileprivate var beacons = [Int : Beacon]()
    fileprivate var nextListenerKey = 0
    fileprivate var listeners: [Int : Listener] = [:]


    fileprivate init(region: CLBeaconRegion, manager: CLLocationManager) {
        clRegion = region
        self.manager = manager
        super.init()
    }

    fileprivate convenience init(name: String, uuid: UUID, manager: CLLocationManager) {
        let region = CLBeaconRegion(proximityUUID: uuid, identifier: name)
        region.notifyEntryStateOnDisplay = true
        region.notifyOnEntry = true
        region.notifyOnExit = true
        self.init(region: region, manager: manager)
    }
    
    @objc required convenience public init?(coder decoder: NSCoder) {
        guard let name = decoder.decodeObject(forKey: BeaconRegion.nameKey) as? String,
            let uuid = decoder.decodeObject(forKey: BeaconRegion.uuidKey) as? UUID,
            let manager = BeaconRegion.locationManager
            else { return nil }
        
        self.init(name: name, uuid: uuid, manager: manager)
    }

    @objc open func encode(with coder: NSCoder) {
        coder.encode(name, forKey: BeaconRegion.nameKey)
        coder.encode(uuid, forKey: BeaconRegion.uuidKey)
    }
    
    fileprivate func addOrUpdateBeacon(_ clBeacon: CLBeacon) {
        let id = (clBeacon.major.intValue, clBeacon.minor.intValue)
        let key = Beacon.makeKey(id)
        
        if let beacon = beacons[key] {
            beacon.currentProximity = clBeacon.proximity
        }
        else {
            let beacon = Beacon(beacon: clBeacon, identifier: id, region: self)
            beacons[key] = beacon
            fireEvent(.addedBeacon, beacon: beacon)
        }
    }

    // The returned value can be used to remove the listener
    open func addListener(_ listener: @escaping Listener) -> Int {
        return lockObject(self) {
            let key = self.nextListenerKey; self.nextListenerKey += 1
            self.listeners[key] = listener
            return key
        } as! Int
    }
    
    open func removeListener(_ key: Int) -> Bool {
        return lockObject(self) {
            self.listeners.removeValue(forKey: key) != nil ? true : false
        } as! Bool
    }
    
    open func beaconAtIndex(_ index: Int) -> BeaconRegion.Beacon? {
        return index < numberOfBeacons ? beacons.filter() { $0.1.index == index }[0].1 : nil
    }

    open var name: String {
        get {
            return clRegion.identifier
        }
    }

    open var uuid: UUID {
        get {
            return clRegion.proximityUUID
        }
    }
    
    open var numberOfBeacons: Int {
        get {
            return beacons.count
        }
    }

    open var isMonitoring: Bool {
        get {
            return manager.monitoredRegions.contains(clRegion)
        }
    }
    
    open var isRanging: Bool {
        get {
            return manager.rangedRegions.contains(clRegion)
        }
    }
    
    open fileprivate(set) var locatedInside = false {
        didSet {
            if locatedInside != oldValue {
                if !locatedInside {
                    beacons.removeAll()
                }
                fireEvent(locatedInside ? .enteredRegion : .exitedRegion, beacon: nil)
            }
        }
    }

    open func startMonitoring() {
        manager.startMonitoring(for: clRegion)
        fireEvent(.startedMonitoring, beacon: nil)
    }
    
    open func stopMonitoring() {
        manager.stopMonitoring(for: clRegion)
        fireEvent(.stoppedMonitoring, beacon: nil)
    }

    open func startRanging() {
        manager.startRangingBeacons(in: clRegion)
        fireEvent(.startedRanging, beacon: nil)
    }
    
    open func stopRanging() {
        // Should I remove all beacons. What does iOS do with the beacons that it is tracking
        manager.stopRangingBeacons(in: clRegion)
        fireEvent(.stoppedRanging, beacon: nil)
    }

    fileprivate func fireEvent(_ event: Event, beacon: Beacon?) {
        print(event.describeEvent(self, beacon: beacon))

        _ = lockObject(BeaconRegion.self) {
            for (_, listener) in BeaconRegion.listeners {
                listener(self, event, beacon)
            }
            return nil
        }

        _ = lockObject(self) {
            for (_, listener) in self.listeners {
                listener(self, event, beacon)
            }
            return nil
        }
    }
}
