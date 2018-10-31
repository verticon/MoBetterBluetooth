//
//  Attribute.swift
//  MoBetterBluetooth
//
//  Created by Robert Vaessen on 10/31/18.
//  Copyright © 2018 Verticon. All rights reserved.
//

import Foundation

extension CentralManager {
    open class Attribute {
        public let id: Identifier
        
        init(id: Identifier) {
            self.id = id
        }
    }
}
