//
//  ContentView.swift
//  TrackSpace
//
//  Created by IM Student on 2025-11-24.
//


import SwiftUI

struct ContentView: View {
    @State private var isLoading: Bool = true
    @State private var isLoggedIn: Bool = UserAccountStore.isLoggedIn

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Theme.primaryStart, Theme.primaryEnd]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            if isLoggedIn {
                TabView {
                    NavigationStack {
                        InventoryView()
                    }
                    .tabItem { Label("Inventory", systemImage: "list.bullet.rectangle") }

                    NavigationStack {
                        ScannerView()
                            .navigationTitle("Scan")
                            .navigationBarTitleDisplayMode(.inline)
                    }
                    .tabItem { Label("Scan", systemImage: "camera.viewfinder") }

                    NavigationStack {
                        ClassSettingsView()
                    }
                    .tabItem { Label("Customizations", systemImage: "slider.horizontal.3") }
                }
                .tint(Theme.primaryStart)
            } else {
                LoginView {
                    isLoggedIn = true
                }
            }

            if isLoading {
                LoadingView(message: "Starting TrackSpace...")
                    .transition(.opacity)
            }
        }
        .onAppear {
            // simulate a brief loading sequence while app initializes
            isLoading = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                isLoading = false
            }
            // listen for sign out notifications
            NotificationCenter.default.addObserver(forName: Notification.Name("UserSignedOut"), object: nil, queue: .main) { _ in
                isLoggedIn = false
            }
        }
    }
}

