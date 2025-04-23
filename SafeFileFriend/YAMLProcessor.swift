//
//  YAMLProcessor.swift
//  SafeFileFriend
//
//  Created by Dinu Mapara on 23.04.25.
//

import Foundation

struct YAMLProcessor: FileProcessor {
    func process(fileURL: URL) throws -> URL {
        let yamlText = try String(contentsOf: fileURL, encoding: .utf8)
        // TODO: implement YAML parsing/modification
        let outURL = fileURL
            .deletingLastPathComponent()
            .appendingPathComponent("processed_" + fileURL.lastPathComponent)
        try yamlText.write(to: outURL, atomically: true, encoding: .utf8)
        return outURL
    }
}
