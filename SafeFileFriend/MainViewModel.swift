//
//  MainViewModel.swift
//  SafeFileFriend
//
//  Created by Dinu Mapara on 23.04.25.
//

//
//  MainViewModel.swift
//  SafeFileFriend
//
//  Created by Dinu Mapara on 24.04.25. // Assuming creation date update might be desired
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers // Ensure this is imported

@MainActor // Ensures UI updates happen on the main thread
class MainViewModel: ObservableObject {

    // MARK: — Published state
    @Published var selectedFileType: FileType = .txt
    @Published var currentFile: URL? // The file/folder currently being processed
    @Published var progress: Double = 0
    @Published var messages: [String] = []

    // MARK: — Internals
    private let handler = FileHandler() // Assuming FileHandler exists and is defined elsewhere
    private var pickedFileBookmark: Data? // Stores the security-scoped bookmark

    // MARK: — Public API

    /// Shows an NSOpenPanel to allow the user to select a file or folder.
    /// Creates a security-scoped bookmark for the selection and initiates processing.
    func openFile() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = (selectedFileType != .pdfFolder)
        panel.canChooseDirectories = (selectedFileType == .pdfFolder)
        panel.allowsMultipleSelection = false

        // Set allowed content types based on the selected file type
        if let types = allowedContentTypes(for: selectedFileType) {
            panel.allowedContentTypes = types
        }

        // Run the panel modally
        if panel.runModal() == .OK, let url = panel.url {
            // Attempt to create a security-scoped bookmark
            do {
                pickedFileBookmark = try url.bookmarkData(
                    options: .withSecurityScope,
                    includingResourceValuesForKeys: nil,
                    relativeTo: nil
                )
                // If bookmark creation is successful, proceed to resolve and process
                processFileUsingBookmark()
            } catch {
                // Handle failure to create the bookmark
                appendMessage("❌ Failed to create bookmark: \(error.localizedDescription)")
                pickedFileBookmark = nil // Ensure bookmark is nil if creation failed
            }
        }
    }

    // MARK: — Bookmark resolution and Access Management

    /// Resolves the stored security-scoped bookmark, starts access,
    /// initiates processing, and ensures access is stopped afterwards.
    // Inside processFileUsingBookmark()

        private func processFileUsingBookmark() {
            guard let bookmark = pickedFileBookmark else {
                appendMessage("❌ Cannot process: No valid bookmark available.")
                print("❌ Error: pickedFileBookmark is nil.") // Log
                return
            }
            print("ℹ️ Found bookmark data (\(bookmark.count) bytes). Attempting to resolve...") // Log

            var isStale = false
            do {
                let url = try URL(
                    resolvingBookmarkData: bookmark,
                    options: .withSecurityScope,
                    relativeTo: nil,
                    bookmarkDataIsStale: &isStale
                )
                print("✅ Bookmark resolved successfully to URL: \(url.path)") // Log
                print("ℹ️ Bookmark stale status: \(isStale)") // Log

                // --- CRITICAL: Log Start Access ---
                print("ℹ️ Attempting to call startAccessingSecurityScopedResource()...") // Log
                let accessGranted = url.startAccessingSecurityScopedResource()
                print("ℹ️ Result of startAccessingSecurityScopedResource(): \(accessGranted)") // Log
                // --- END CRITICAL LOG ---

                guard accessGranted else {
                    appendMessage("❌ Could not gain access permissions via startAccessingSecurityScopedResource.")
                    print("❌ Error: startAccessingSecurityScopedResource() returned false for URL: \(url.path)") // Log
                    // No need to stop access if it wasn't granted
                    return
                }

                // If access was granted, proceed...
                print("✅ Access granted via startAccessingSecurityScopedResource(). Proceeding to processFile.") // Log
                processFile(at: url) {
                    print("ℹ️ Calling stopAccessingSecurityScopedResource() in cleanup block.") // Log
                    url.stopAccessingSecurityScopedResource()
                }

            } catch {
                appendMessage("❌ Failed to resolve bookmark: \(error.localizedDescription)")
                // --- Log the full error ---
                print("❌ Error resolving bookmark: \(error)") // Log the detailed error object
                // --- End log ---
            }
        }
    
    // MARK: — File Processing

    /// Initiates the background file processing task.
    /// - Parameters:
    ///   - url: The URL of the file/folder to process (access should already be started).
    ///   - cleanup: A closure that MUST be called when processing is finished or fails,
    ///              typically containing `url.stopAccessingSecurityScopedResource()`.
    private func processFile(at url: URL, cleanup: @escaping () -> Void) {
        // Update UI state for the new operation
        currentFile = url
        progress = 0
        messages = ["🔄 Starting processing for: \(url.lastPathComponent)"]

        // --- Perform heavy lifting off the main thread ---
        // Use Task.detached for background execution.
        // Capture self weakly to avoid retain cycles if the ViewModel disappears
        // before the task finishes.
        Task.detached { [weak self, handler] in // Capture handler if it's needed by reference
            // --- CRITICAL: Ensure cleanup runs ---
            // defer guarantees this code runs when the Task block exits,
            // whether normally or through an error.
            defer {
                cleanup() // This calls url.stopAccessingSecurityScopedResource()
            }

            // --- Check if self (ViewModel) still exists ---
            guard let self else {
                // If ViewModel was deallocated, log and exit task. Cleanup runs due to defer.
                print("MainViewModel deallocated before processing task could complete.")
                return
            }

            // --- Perform the actual file handling ---
            do {
                try await handler.handle(
                    fileURL: url,
                    fileType: self.selectedFileType, // Access via self.
                    progress: { p in
                        // Dispatch progress updates back to the main actor
                        Task { @MainActor in self.updateProgress(p) }
                    },
                    message: { m in
                        // Dispatch messages back to the main actor
                        Task { @MainActor in self.appendMessage(m) }
                    }
                )
                // Report success on the main actor
                await self.appendMessage("✅ Processing complete.") // Use await for MainActor method
            } catch {
                // Report errors on the main actor
                await self.appendMessage("❌ Error: \(error.localizedDescription)") // Use await
            }
        }
    }

    // MARK: — Helpers (on MainActor)

    /// Updates the progress value. Must be called on the MainActor.
    func updateProgress(_ p: Double) {
        // Since the class is @MainActor, this is guaranteed
        progress = p
    }

    /// Appends a message to the message list. Must be called on the MainActor.
    func appendMessage(_ m: String) {
        // Since the class is @MainActor, this is guaranteed
        messages.append(m)
    }

    /// Determines the color for a given message string based on prefix.
    func color(for message: String) -> Color {
        if message.hasPrefix("❌") { return .red }
        if message.hasPrefix("✅") { return .green }
        return .primary // Default text color
    }

    // MARK: — Allowed Content Types Helper

    /// Provides the allowed UTTypes for the NSOpenPanel based on the FileType enum.
    private func allowedContentTypes(for type: FileType) -> [UTType]? {
        switch type {
        case .txt:
            return [.plainText]
        case .pdf:
            return [.pdf]
        case .yaml:
            // Use compactMap to safely create UTTypes and filter out nils
            // if an extension is somehow invalid.
            return ["yaml", "yml"].compactMap { UTType(filenameExtension: $0) }
        case .pdfFolder:
            // Return nil when selecting directories, as content types don't apply.
            return nil
        }
    }
}

// MARK: - Supporting Types (Assumed Definitions)

// You would need these defined elsewhere in your project:

// /// Represents the type of file/operation the user wants to perform.
// enum FileType: CaseIterable, Identifiable { // Example definition
//     case txt, pdf, yaml, pdfFolder
//     var id: Self { self }
//     // You might add display names etc. here
// }

// /// Placeholder for the class/struct that handles the actual file operations.
// struct FileHandler { // Example definition
//     func handle(fileURL: URL, fileType: FileType, progress: (Double) -> Void, message: (String) -> Void) async throws {
//         // Implement your file backup, processing, replacement logic here
//         message("Starting handle operation...")
//         try await Task.sleep(nanoseconds: 500_000_000) // Simulate work
//         progress(0.5)
//         message("Did half the work...")
//         try await Task.sleep(nanoseconds: 500_000_000) // Simulate more work
//         progress(1.0)
//         message("Finished handle operation.")
//         // Throw an error if something goes wrong
//     }
// }
