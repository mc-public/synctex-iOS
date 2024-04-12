//
//  Error.swift
//
//
//  Created by mengchao on 2023/7/19.
//

#if os(iOS)

import Foundation

extension SyncTeXScanner {
    /// The errors that may occur during SyncTeX execution.
    public enum SyncTeXError: Error {
        case scannerCreationFailed
    }
    
}

#endif /* os(iOS) */
