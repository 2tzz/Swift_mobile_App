//
//  ContentView.swift
//  TrackSpace
//  Created by IM Student on 2025-11-24.
//


import SwiftUI

struct ContentView: View {
    private enum Tab: Int { case inventory, customizations, scan }
    @State private var isLoading: Bool = true
    @State private var isLoggedIn: Bool = UserAccountStore.isLoggedIn
    @State private var selectedTab: Tab = .inventory
    @State private var showScanTransition = false

    var body: some View {
        ZStack {
            Theme.backgroundGradient
                .ignoresSafeArea()

            if isLoggedIn {
                TabView(selection: $selectedTab) {
                    NavigationStack {
                        InventoryView()
                    }
                    .tabItem { Label("Inventory", systemImage: "list.bullet.rectangle") }
                    .tag(Tab.inventory)
                    .toolbarColorScheme(.dark, for: .navigationBar)
                    .toolbarBackground(.visible, for: .navigationBar)
                    .toolbarBackground(Color.clear, for: .navigationBar)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            Text("Inventory")
                                .font(.headline.weight(.semibold))
                                .foregroundColor(.white)
                        }
                    }

                    NavigationStack {
                        ClassSettingsView()
                    }
                    .tabItem { Label("Customizations", systemImage: "slider.horizontal.3") }
                    .tag(Tab.customizations)
                    .toolbarColorScheme(.dark, for: .navigationBar)
                    .toolbarBackground(.visible, for: .navigationBar)
                    .toolbarBackground(Color.clear, for: .navigationBar)

                    NavigationStack {
                        ScannerView()
                            .navigationTitle("Scan")
                            .navigationBarTitleDisplayMode(.inline)
                    }
                    .tabItem {
                        Label("Scan", systemImage: "scope")
                    }
                    .tag(Tab.scan)
                    .toolbarColorScheme(.dark, for: .navigationBar)
                    .toolbarBackground(.visible, for: .navigationBar)
                    .toolbarBackground(Color.clear, for: .navigationBar)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            Text("Scan")
                                .font(.headline.weight(.semibold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .tint(Theme.primaryStart)
                .background(Color.clear)
            } else {
                LoginView {
                    isLoggedIn = true
                    selectedTab = .inventory
                }
            }

            if isLoading {
                LoadingView(message: "Starting TrackSpace...")
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 1.0), value: isLoading)
            }

            if showScanTransition {
                ScanTransitionOverlay()
                    .allowsHitTesting(false)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.6), value: showScanTransition)
            }
        }
        .onAppear {
            // simulate a brief loading sequence while app initializes
            isLoading = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                isLoading = false
            }
            // listen for sign out notifications
            NotificationCenter.default.addObserver(forName: Notification.Name("UserSignedOut"), object: nil, queue: .main) { _ in
                isLoggedIn = false
                selectedTab = .inventory
            }
        }
        .onChange(of: selectedTab) { tab in
            guard tab == .scan else { return }
            showScanTransition = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                showScanTransition = false
            }
        }
    }
}

private struct ScanTransitionOverlay: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            Theme.backgroundGradient
                .opacity(0.92)
                .ignoresSafeArea()

            Circle()
                .fill(Theme.headerGradient)
                .blur(radius: 90)
                .frame(width: animate ? 520 : 220, height: animate ? 520 : 220)
                .opacity(0.45)
                .animation(.easeInOut(duration: 2.8), value: animate)

            ZStack {
                Circle()
                    .strokeBorder(AngularGradient(gradient: Gradient(colors: [Theme.primaryStart, Theme.primaryEnd, Theme.accentStart]), center: .center), lineWidth: 4)
                    .frame(width: animate ? 240 : 150, height: animate ? 240 : 150)
                    .rotationEffect(.degrees(animate ? 360 : 0))
                    .animation(.linear(duration: 3.8).repeatForever(autoreverses: false), value: animate)

                Circle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: animate ? 190 : 100, height: animate ? 190 : 100)
                    .animation(.easeInOut(duration: 2.1), value: animate)

                Image(systemName: "scope")
                    .font(.system(size: 52, weight: .bold))
                    .foregroundStyle(.white)
                    .shadow(color: Theme.primaryEnd.opacity(0.6), radius: 18, x: 0, y: 6)

                Text("Preparing Scanner")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.85))
                    .offset(y: 120)
            }
            .shadow(color: Theme.primaryStart.opacity(0.5), radius: 30, x: 0, y: 20)
        }
        .onAppear {
            animate = true
        }
    }
}

