//
//  SafeFileFriendApp.swift
//  SafeFileFriend
//
//  Created by Dinu Mapara on 23.04.25.
//

// ─────────────────────────────────────────────────────────────────────────────
// SafeFileFriendApp.swift
// ─────────────────────────────────────────────────────────────────────────────
import SwiftUI

@main
struct SafeFileFriendApp: App {
    @StateObject private var viewModel = MainViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
        .commands {
            FileTypeCommands(viewModel: viewModel)
        }
    }
}
