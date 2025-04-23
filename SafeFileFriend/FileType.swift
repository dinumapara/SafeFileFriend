//
//  FileType.swift
//  SafeFileFriend
//
//  Created by Dinu Mapara on 23.04.25.
//

import SwiftUI

enum FileType: String, CaseIterable {
    case txt, pdf, yaml, pdfFolder

    var menuTitle: String {
        switch self {
        case .txt:       return "TXT Handling"
        case .pdf:       return "PDF Handling"
        case .yaml:      return "YAML Handling"
        case .pdfFolder: return "PDF Folder Handling"
        }
    }

    var shortcut: KeyEquivalent {
        switch self {
        case .txt:       return "T"
        case .pdf:       return "P"
        case .yaml:      return "Y"
        case .pdfFolder: return "F"
        }
    }
}
