//
//  FileProcessor.swift
//  SafeFileFriend
//
//  Created by Dinu Mapara on 23.04.25.
//

import Foundation

protocol FileProcessor {
    /// Transform the file at `fileURL` and return a new URL.
    func process(fileURL: URL) throws -> URL
}

