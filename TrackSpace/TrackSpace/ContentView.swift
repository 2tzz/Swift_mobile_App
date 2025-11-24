//
//  ContentView.swift
//  TrackSpace
//
//  Created by IM Student on 2025-11-24.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack {
                InventoryView()
            }
            .tabItem {
                Label("Inventory", systemImage: "list.bullet.rectangle")
            }

            NavigationStack {
                ScannerView()
                    .navigationTitle("Scan")
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem {
                Label("Scan", systemImage: "camera.viewfinder")
            }
        }
    }
}

#Preview {
    ContentView()
}
