//
//  ContentView.swift
//  SafeFileFriend
//
//  Created by Dinu Mapara on 23.04.25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: MainViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("File Processor")
                .font(.largeTitle)

            if let file = viewModel.currentFile {
                Text("Processing: \(file.lastPathComponent)")
            }

            ProgressView(value: viewModel.progress)
                .progressViewStyle(.linear)
                .frame(width: 320)

            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(viewModel.messages, id: \.self) { msg in
                        Text(msg)
                            .foregroundColor(viewModel.color(for: msg))
                    }
                }
            }
            .frame(height: 120)

            Button("Open File…") {
                viewModel.openFile()
            }
            .keyboardShortcut("O", modifiers: [.command])
        }
        .padding(20)
        .frame(minWidth: 400, minHeight: 300)
    }
}

#Preview {
    ContentView()
        .environmentObject(MainViewModel())
}
