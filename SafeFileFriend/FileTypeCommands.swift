//
//  FileTypeCommands.swift
//  SafeFileFriend
//
//  Created by Dinu Mapara on 23.04.25.
//

import SwiftUI

struct FileTypeCommands: Commands {
    @ObservedObject var viewModel: MainViewModel

    var body: some Commands {
        CommandMenu("File") {
            Button("Open File…") {
                viewModel.openFile()
            }
            .keyboardShortcut("O", modifiers: [.command])

            Divider()

            ForEach(FileType.allCases, id: \.self) { type in
                Button(type.menuTitle) {
                    viewModel.selectedFileType = type
                }
                .keyboardShortcut(type.shortcut, modifiers: [.command, .shift])
            }
        }
    }
}
