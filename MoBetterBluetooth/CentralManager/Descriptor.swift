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
        
        public var description: String {
            return cbDescriptor == nil ? "\(name)<cbDescriptor is nil?>" : "\(cbDescriptor!)"
        }
        
        // ************************** Reading ******************************
        
        public enum ReadResult {
            case success(Any)
            case failure(PeripheralError)
        }
        
        public typealias ReadCompletionHandler = (ReadResult) -> Void
        private var readCompletionHandler: ReadCompletionHandler?
        
        public func read(_ completionHandler: @escaping ReadCompletionHandler) -> PeripheralStatus {
            
            guard readCompletionHandler == nil else { return .failure(.readInProgress) }
            
            guard let descriptor = cbDescriptor else { return .failure(.cbAttributeIsNil) }
            
            readCompletionHandler = completionHandler
            
            parent.parent.parent.cbPeripheral.readValue(for: descriptor)
            
            return .success
        }
        
        // The Central Manager will call this method when an asynchronous read has completed.
        // It is called on the main thread (is this bcause read was called on the main thread?).
        func readCompleted(_ value : Any?, cbError: Error?) {
            guard readCompletionHandler != nil else {
                fatalError("Read completed method invoked but completion handler is nil???")
            }
            
            let result: ReadResult
            if let error = cbError {
                result = .failure(.descriptorReadError(self, cbError: error))
            } else {
                result = .success(value!)
            }
            
            if let handler = readCompletionHandler {
                readCompletionHandler = nil // Do this first so that the handler can initiate a new read if desired.
                handler(result)
            }
        }
        
        // ************************** Writing ******************************
        
        public typealias WriteCompletionHandler = (PeripheralStatus) -> Void
        private var writeCompletionHandler: WriteCompletionHandler?
        
        public func write(_ value: Data, completionHandler: @escaping WriteCompletionHandler) -> PeripheralStatus {
            
            guard writeCompletionHandler == nil else { return .failure(.writeInProgress) }
            
            guard let descriptor = cbDescriptor else { return .failure(.cbAttributeIsNil) }
            
            writeCompletionHandler = completionHandler
            
            parent.parent.parent.cbPeripheral.writeValue(value, for: descriptor)
            
            return .success
        }
        
        // The Central Manager will call this method when the asynchronous write has completed.
        func writeCompleted(cbError: Error?) {
            guard let handler = writeCompletionHandler else {
                fatalError("Write completed method invoked but completion handler is nil???")
            }
            
            writeCompletionHandler = nil // Do this first so that the handler can initiate a new write if desired.
            
            if let error = cbError {
                handler(.failure(.descriptorWriteError(self, cbError: error)))
            }
            else {
                handler(.success)
            }
        }
    }
}
