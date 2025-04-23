//
//  TXTProcessor.swift
//  SafeFileFriend
//
//  Created by Dinu Mapara on 23.04.25.
//

import Foundation

struct TXTProcessor: FileProcessor {
    func process(fileURL: URL) throws -> URL {
        let text = try String(contentsOf: fileURL, encoding: .utf8)
        let transformed = text.uppercased()
        let outURL = fileURL
            .deletingLastPathComponent()
            .appendingPathComponent("processed_" + fileURL.lastPathComponent)
        try transformed.write(to: outURL, atomically: true, encoding: .utf8)
        return outURL
    }
}
