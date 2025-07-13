//
//  Item.swift
//  FoundationWriting
//
//  Created by Hans Axelsson on 7/13/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
