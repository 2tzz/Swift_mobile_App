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
    @State private var showImageSavedBanner: Bool = false
    @State private var imageSavedMessage: String = ""

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .overlay(alignment: .top) {
                    if showImageSavedBanner {
                        Text(imageSavedMessage)
                            .padding(10)
                            .background(.black.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .padding(.top, 44)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .imageSaved)) { note in
                    if let user = note.userInfo, let path = user["path"] as? String {
                        var label = "Image saved"
                        if let l = user["label"] as? String { label = "Saved: \(l)" }
                        if let ctx = user["context"] as? String { label = ctx == "profile" ? "Profile photo saved" : label }
                        imageSavedMessage = "\(label) — saved to \(path)"
                    } else {
                        imageSavedMessage = "Image saved"
                    }
                    withAnimation { showImageSavedBanner = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                        withAnimation { showImageSavedBanner = false }
                    }
                }
        }
    }
}
