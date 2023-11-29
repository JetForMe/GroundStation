//
//  GroundStationApp.swift
//  GroundStation
//
//  Created by Rick Mann on 2023-11-28.
//

import SwiftUI

@main
struct GroundStationApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: GroundStationDocument()) { file in
            ContentView(document: file.$document)
        }
    }
}
