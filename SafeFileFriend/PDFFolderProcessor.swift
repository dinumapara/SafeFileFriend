//
//  PDFFolderProcessor.swift
//  SafeFileFriend
//
//  Created by Dinu Mapara on 23.04.25.
//

import Foundation

struct PDFFolderProcessor: FileProcessor {
    func process(fileURL: URL) throws -> URL {
        let fileManager = FileManager.default
        let items = try fileManager.contentsOfDirectory(at: fileURL, includingPropertiesForKeys: nil)
        for pdfURL in items.filter({ $0.pathExtension.lowercased() == "pdf" }) {
            // call PDFProcessor on each…
            _ = try PDFProcessor().process(fileURL: pdfURL)
        }
        return fileURL
    }
}
