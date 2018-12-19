//
//  Descriptor.swift
//  MoBetterBluetooth
//
//  Created by Robert Vaessen on 10/31/18.
//  Copyright © 2018 Verticon. All rights reserved.
//

import Foundation
import CoreBluetooth
import VerticonsToolbox

extension CentralManager {
    // TODO: Get descriptors squared away
    open class Descriptor : Attribute, CustomStringConvertible {
        
        public internal(set) weak var cbDescriptor : CBDescriptor?
        public let parent: Characteristic
        
        public init(cbDescriptor: CBDescriptor, id: Identifier, parent: Characteristic) {
            self.cbDescriptor = cbDescriptor
            self.parent = parent
            super.init(id: id)
        }
        
        public var name: String { return id.name ?? id.uuid.uuidString }
        
        public var description: String { return cbDescriptor == nil ? "\(name)<cbDescriptor is nil?>" : "\(cbDescriptor!)" }
        
        // ************************** Reading ******************************
        
        public enum ReadResult {
            case success(Any)
            case failure(PeripheralError)
        }
        
        public typealias ReadCompletionHandler = (ReadResult) -> Void
        private var readCompletionHandlers = [ReadCompletionHandler]()
        private var readInProgress : Bool { return readCompletionHandlers.count > 0 }

        public func read(_ completionHandler: @escaping ReadCompletionHandler) -> PeripheralStatus {

            guard Thread.isMainThread else { return .failure(.notMainThread) }

            guard let descriptor = cbDescriptor else { return .failure(.cbAttributeIsNil) }

            if readInProgress {
                readCompletionHandlers.append(completionHandler)
            } else {
                readCompletionHandlers.append(completionHandler)
                parent.parent.parent.cbPeripheral.readValue(for: descriptor)
            }
            
            return .success
        }
        
        // The Central Manager will call this method when an asynchronous read has completed.
        // It is called on the main thread (is this bcause read was called on the main thread?).
        func readCompleted(_ value: Any?, cbError: Error?) {
            guard readInProgress else { fatalError("Read completed method invoked but there is not a read in progress") }
            
            let result: ReadResult
            if let error = cbError { result = .failure(.descriptorReadError(self, cbError: error)) }
            else { result = .success(value!) }
            
            let handlers = readCompletionHandlers
            readCompletionHandlers.removeAll()
            for handler in handlers { handler(result) } // TODO: The handler could call read. Would CB be okay with this?
        }
        
        // ************************** Writing ******************************
        
        public typealias WriteCompletionHandler = (PeripheralStatus) -> Void
        private var writeCompletionHandler: WriteCompletionHandler? = nil
        private var writeInProgress : Bool { return writeCompletionHandler != nil }

        public func write(_ value: Data, completionHandler: @escaping WriteCompletionHandler) -> PeripheralStatus {
            
            guard Thread.isMainThread else { return .failure(.notMainThread) }

            guard !writeInProgress else { return .failure(.writeInProgress) }

            guard let descriptor = cbDescriptor else { return .failure(.cbAttributeIsNil) }
            
            writeCompletionHandler = completionHandler

            parent.parent.parent.cbPeripheral.writeValue(value, for: descriptor)

            return .success
        }
        
        // The Central Manager will call this method when the asynchronous write has completed.
        func writeCompleted(cbError: Error?) {
            guard let handler = writeCompletionHandler else { fatalError("Write completed method invoked but there is not a write in progress") }
            
            writeCompletionHandler = nil // Do this first so that the handler can initiate a new write if desired.
            
            let status: PeripheralStatus
            if let error = cbError { status = .failure(.descriptorWriteError(self, cbError: error)) }
            else { status = .success}

            handler(status)
        }
    }
}
