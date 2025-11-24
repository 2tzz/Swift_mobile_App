//
//  TrackSpaceApp.swift
//  TrackSpace
//
//  Created by IM Student on 2025-11-24.
//

import SwiftUI
import CoreData

@main
struct TrackSpaceApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
