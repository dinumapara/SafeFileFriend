//
//  FileHandler.swift
//  SafeFileFriend
//
//  Created by Dinu Mapara on 23.04.25.
//

import Foundation // Needed for FileManager, URL, UUID etc.
import UniformTypeIdentifiers // If used elsewhere

// --- Assumed FileType enum is defined elsewhere ---
// enum FileType { ... }

struct FileHandler {

    // MARK: - Public API

    /// Handles processing the file, including creating a backup in App Support.
    func handle(fileURL: URL, fileType: FileType, progress: (Double) -> Void, message: (String) -> Void) async throws {
        message("FileHandler: Starting processing for \(fileURL.lastPathComponent)")
        progress(0.1) // Example progress

        // 1. Read the original file data (as before)
        print("FileHandler: Attempting to read data from \(fileURL.path)")
        let originalData: Data
        do {
            originalData = try Data(contentsOf: fileURL)
            message("FileHandler: Successfully read original file.")
            progress(0.3)
        } catch {
            message("❌ FileHandler: Failed to read original file: \(error.localizedDescription)")
            print("❌ FileHandler: Read error: \(error)")
            throw error // Re-throw the error to be caught by MainViewModel
        }

        // 2. Create the backup in Application Support
        do {
            // Get the App Support directory URL using the helper
            guard let appSupportDir = self.getAppSupportDirectory() else {
                message("❌ FileHandler: Could not determine Application Support directory.")
                // Decide if this is a fatal error or if you can continue without backup
                throw FileHandlerError.cannotAccessAppSupport // Define a custom error if needed
            }

            // Create a unique filename for the backup (e.g., using original name + timestamp/UUID)
            let timestamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-") // ISO8601 format is good for sorting
            let backupFilename = "\(fileURL.deletingPathExtension().lastPathComponent)_Backup_\(timestamp).\(fileURL.pathExtension)"
            // Or simpler: let backupFilename = "backup_\(UUID().uuidString).\(fileURL.pathExtension)"

            let backupURL = appSupportDir.appendingPathComponent(backupFilename)

            // Write the original data to the backup location
            print("FileHandler: Attempting to write backup to App Support: \(backupURL.path)")
            message("FileHandler: Writing backup to App Support...")
            try originalData.write(to: backupURL)
            message("FileHandler: Backup successfully written.")
            progress(0.5)

        } catch {
            message("❌ FileHandler: Failed to write backup: \(error.localizedDescription)")
            print("❌ FileHandler: Backup write error: \(error)")
            // Decide if this is fatal or if you can proceed carefully
            throw error // Re-throw
        }

        // 3. Perform your actual file processing on the original data or file
        message("FileHandler: Starting main processing...")
        // ... your core logic here ...
        // e.g., modify originalData, or write processed data back to fileURL
        try await Task.sleep(nanoseconds: 500_000_000) // Simulate work
        message("FileHandler: Main processing finished.")
        progress(0.8)

        // 4. Potentially replace original file (if needed and successful)
        // Be careful here! Use file coordination if necessary.
        // try processedData.write(to: fileURL, options: .atomic)
        message("FileHandler: File processing complete.")
        progress(1.0)
    }

    // MARK: - Private Helpers

    /// Gets the URL for the app-specific subdirectory within Application Support, creating it if necessary.
    private func getAppSupportDirectory() -> URL? {
        guard let appSupportBaseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            print("❌ FileHandler Helper: Could not find Application Support base directory.")
            return nil
        }

        // Append your app's bundle identifier to create a dedicated folder
        // Ensure your app has a Bundle Identifier set in the Target settings!
        guard let bundleId = Bundle.main.bundleIdentifier else {
            print("❌ FileHandler Helper: Could not get Bundle Identifier.")
            // Fallback to a generic name, but using Bundle ID is preferred
            // let appSupportURL = appSupportBaseURL.appendingPathComponent("YourAppNameSafeFileFriend")
             return nil // Or handle fallback more gracefully
        }
        let appSpecificURL = appSupportBaseURL.appendingPathComponent(bundleId)

        // Create directory if it doesn't exist
        if !FileManager.default.fileExists(atPath: appSpecificURL.path) {
            do {
                try FileManager.default.createDirectory(at: appSpecificURL, withIntermediateDirectories: true, attributes: nil)
                print("✅ FileHandler Helper: Created App Support directory at: \(appSpecificURL.path)")
            } catch {
                print("❌ FileHandler Helper: Error creating App Support directory: \(error)")
                return nil
            }
        }
        
        return appSpecificURL
    }
}

// Optional: Define custom errors if needed
enum FileHandlerError: Error {
    case cannotAccessAppSupport
    // Add other potential handler errors
}
