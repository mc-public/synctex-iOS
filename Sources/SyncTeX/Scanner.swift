//
//  Scanner.swift
//  
//
//  Created by mengchao on 2023/7/18.
//

#if os(iOS)

import Foundation
@_implementationOnly import __Internal_SyncTeX_C

/// A Swift wrapper for the SyncTeX C API used for synchronizing input and output of TeX source files.
///
/// - Note: The class is thread safe.
///
/// The typical usage of this class is to create a new instance of this class and then call the corresponding query methods on the instance.
@available(iOS 13.0, *)
public final class SyncTeXScanner {
    /// The current working directory of the SyncTeX scanner.
    ///
    /// This value may be `nil`. If you want to reset this value, you can call the ``resetURL(file:directory:)`` method of this class.
    public var outputDirectory: URL? {
        get async {
            await withUnsafeContinuation { (cont: UnsafeContinuation<URL?, Never>) -> Void in
                queue.async {
                    cont.resume(returning: self._outputDirectory)
                }
            }
        }
    }
    
    public private(set) var _outputDirectory: URL?
    /// The current document file output by the `TeX` engine has an extension of either `pdf`, `dvi`, or `xdv`.
    ///
    /// If you want to reset this value, you can call the ``resetURL(file:directory:)`` method of this class.
    public var outputFile: URL {
        get async {
            await withUnsafeContinuation { (cont: UnsafeContinuation<URL, Never>) -> Void in
                queue.async {
                    cont.resume(returning: self._outputFile)
                }
            }
        }
    }
    public private(set) var _outputFile: URL
    private var scanner: synctex_scanner_p!
    private var isScannerAvailable: Bool {
        scanner != nil
    }
    private var queue: DispatchQueue = .init(label: "\(SyncTeXError.Type.self)_SerialQueue_\(UUID().uuidString)")
    
    /// Initialize a SyncTeX scanner instance.
    ///
    /// During the initialization process, attempts will be made to find the necessary dependencies for `SyncTeX`. If these files cannot be found or if an internal error occurs, the initialization method will throw an error. You can refer to the `SyncTeXError` enum in this class to see all the possible errors that can be thrown.
    ///
    /// - Parameters:
    ///     - outputFile: The document file output by the `TeX` engine has an extension of either `pdf`, `dvi`, or `xdv`.
    ///     - outputDirectory: The working directory of the `TeX` engine. This parameter can be empty. If specifying this value, the actual directory corresponding to it must contain a `SyncTeX` file with the same name as `outputFile`, with an extension of either `synctex.gz` or `synctex`. You can refer to the SyncTeXError enum in this class to see all the possible errors that can be thrown.
    public init(outputFile: URL, outputDirectory: URL? = nil) async throws {
        self._outputDirectory = outputDirectory
        self._outputFile = outputFile
        try await self.updateScannerByAsync()
    }
    
    
    /// Reload the SyncTeX file and regenerate the tree.
    ///
    /// This will release the original tree and reload the `SyncTeX` file based on the relevant information of the current properties in this class, and generate a new tree. This method will be automatically called during initialization. You can refer to the ``SyncTeXError`` enum in this class to see all the possible errors that can be thrown.
    public func updateNodeTree() async throws {
        try await self.updateScannerByAsync()
    }
    
    /// Reset the working directory.
    ///
    /// This will reset the working directory of the current scanner, reload the corresponding `SyncTeX` file, and regenerate the tree.
    ///
    /// You can refer to the `SyncTeXError` enum in this class to see all the possible errors that can be thrown.
    ///
    ///  - Parameters:
    ///     - outputFile: The document file output by the `TeX` engine has an extension of either `pdf`, `dvi`, or `xdv`.
    ///     - outputDirectory: The working directory of the `TeX` engine. This parameter can be empty. If specifying this value, the actual directory corresponding to it must contain a `SyncTeX` file with the same name as `outputFile`, with an extension of either `synctex.gz` or `synctex`.
    public func resetURL(file outputFile: URL, directory outputDirectory: URL?) async throws {
        try await withUnsafeThrowingContinuation { (cont: UnsafeContinuation<Void, any Error>) -> Void in
            queue.async {
                self._outputFile = outputFile
                self._outputDirectory = outputDirectory
                do {
                    try self.updateScanner()
                } catch {
                    cont.resume(throwing: error)
                    return
                }
                cont.resume()
            }
        }
        
    }
    
    private func updateScannerByAsync() async throws {
        try await withUnsafeThrowingContinuation { (cont: UnsafeContinuation<Void, any Error>) -> Void in
            queue.async {
                do {
                    try self.updateScanner()
                } catch {
                    cont.resume(throwing: error)
                    return
                }
                cont.resume()
            }
        }
    }
    
    private func updateScanner() throws {
        if self.isScannerAvailable {
            synctex_scanner_free(self.scanner)
            self.scanner = nil
        }
        if let _outputDirectory = self._outputDirectory {
            _outputDirectory.withUnsafeFileSystemRepresentation { outputDirPointer in
                self._outputFile.withUnsafeFileSystemRepresentation { outputFilePointer in
                    self.scanner = synctex_scanner_new_with_output_file(outputFilePointer, outputDirPointer, 1)
                }
            }
        } else {
            self._outputFile.withUnsafeFileSystemRepresentation { outputFilePointer in
                self.scanner = synctex_scanner_new_with_output_file(outputFilePointer, nil, 1)
            }
        }
        if !isScannerAvailable {
            throw SyncTeXError.scannerCreationFailed
        }
    }
    
    
    deinit {
        let pointer = self.scanner
        let queue = self.queue
        self.scanner = nil
        queue.async {
            synctex_scanner_free(pointer)
        }
    }
    
    
    /// Find the corresponding position of the output file based on the relevant information of the source file.
    ///
    /// Based on the given relevant information of the source file, such as the file name, line number, column number, etc., search for the corresponding position in the output file (`pdf`, `dvi`, `xdv`). The resulting output can be used for implementing synchronization between the editor and the PDF viewer.
    ///
    /// - Parameters:
    ///     - fileURL: To find the `URL` corresponding to the source file you want to query, the path of that `URL` must exist in the "Input" line of the `SyncTeX` file. Otherwise, no results can be found.
    ///     - line: The line number corresponding to the position you want to query. Let's assume that line numbers start from `1`.
    ///     - column: The column number corresponding to the position you want to query. Let's assume that line numbers start from `0`.
    ///     - pageHint: The result closest to the page corresponding to this parameter will be placed at the first index in the output results. The default value is `0`.
    /// - Returns:
    ///     Return an Array representing all possible search results. If the Array is empty, it means that no results were found.
    public func displayQuery(fileURL: URL, line: Int, column: Int, pageHint: Int = 0) async -> [NodeDisplayInfo] {
        return await withUnsafeContinuation { (cont: UnsafeContinuation<[NodeDisplayInfo], Never>) -> Void in
            queue.async {
                synctex_scanner_reset_result(self.scanner)
                defer {
                    synctex_scanner_reset_result(self.scanner)
                }
                let fileURL = fileURL.standardizedFileURL
                var isFileNameFound = false
                var inputNode = synctex_scanner_input(self.scanner)
                var resultURL: URL?
                var resultName: String = .init()
                while (inputNode != nil) {
                    guard let name = synctex_scanner_get_name(self.scanner, synctex_node_tag(inputNode)), let nameString = String(cString: name, encoding: .utf8) else {
                        cont.resume(returning: [])
                        return
                    }
                    resultName = nameString /// Maybe contains `/./`
                    resultURL = URL(fileURLWithFileSystemRepresentation: name, isDirectory: false, relativeTo: nil)
                        .standardizedFileURL
                    if resultURL?.absoluteString == fileURL.absoluteString {
                        isFileNameFound = true
                        break
                    }
                    inputNode = synctex_node_sibling(inputNode)
                }
                guard isFileNameFound else {
                    #if DEBUG
                    print("[SyncTeXSanner] Cannot find file \(fileURL.absoluteString) in all input node.")
                    #endif
                    cont.resume(returning: [])
                    return
                }
                let queryResultCount = synctex_display_query(self.scanner, resultName, Int32(line), Int32(column), Int32(pageHint))
                guard queryResultCount > 0 else {
                    cont.resume(returning: [])
                    return
                }
                var node: synctex_node_p?
                var nodeResult = [synctex_node_p]()
                while(true) {
                    node = synctex_scanner_next_result(self.scanner)
                    if let node = node {
                        nodeResult.append(node)
                    } else {
                        break
                    }
                }
                cont.resume(returning: nodeResult.map { self.getDisplayInfo(for: $0, fileURL: fileURL, line: line, column: column) })
                return
            }
        }
    }
    
    
    /// Find the corresponding position of the output file based on the relevant information of the source file.
    ///
    /// Based on the given relevant information of the source file, such as the file name, line number, column number, etc., search for the corresponding position in the output file (`pdf`, `dvi`, `xdv`). The resulting output can be used for implementing synchronization between the editor and the PDF viewer.
    ///
    /// - Parameters:
    ///     - fileName: The desired filename corresponding to the source file you want to search for. If the file exists in the `outputDirectory`, you must use a relative path (`./123.tex`).
    ///     - line: The line number corresponding to the position you want to query. Let's assume that line numbers start from `1`.
    ///     - column: The column number corresponding to the position you want to query. Let's assume that line numbers start from `0`.
    ///     - pageHint: The result closest to the page corresponding to this parameter will be placed at the first index in the output results. The default value is `0`.
    /// - Returns:
    ///     Return an Array representing all possible search results. If the Array is empty, it means that no results were found.
    public func displayQuery(fileName: String, line: Int, column: Int, pageHint: Int = 0 ) async -> [NodeDisplayInfo] {
        return await withUnsafeContinuation { (cont: UnsafeContinuation<[NodeDisplayInfo], Never>) -> Void in
            queue.async {
                synctex_scanner_reset_result(self.scanner)
                defer {
                    synctex_scanner_reset_result(self.scanner)
                }
                var isFileNameFound = false
                var inputNode = synctex_scanner_input(self.scanner)
                var resultURL: URL?
                var resultName: String = .init()
                while (inputNode != nil) {
                    guard let name = synctex_scanner_get_name(self.scanner, synctex_node_tag(inputNode)), let nameString = String(cString: name, encoding: .utf8) else {
                        cont.resume(returning: [])
                        return
                    }
                    resultName = nameString /// Maybe contains `/./`
                    resultURL = URL(fileURLWithFileSystemRepresentation: name, isDirectory: false, relativeTo: nil)
                        .standardizedFileURL
                    if resultName.hasSuffix(fileName) {
                        isFileNameFound = true
                        break
                    }
                    inputNode = synctex_node_sibling(inputNode)
                }
                guard isFileNameFound, let resultURL = resultURL else {
#if DEBUG
                    print("[SyncTeXSanner] Cannot find file \(fileName) in all input node. ")
#endif
                    cont.resume(returning: [])
                    return
                }
                let queryResultCount = synctex_display_query(self.scanner, resultName, Int32(line), Int32(column), Int32(pageHint))
                guard queryResultCount > 0 else {
                    cont.resume(returning: [])
                    return
                }
                var node: synctex_node_p?
                var nodeResult = [synctex_node_p]()
                while(true) {
                    node = synctex_scanner_next_result(self.scanner)
                    if let node = node {
                        nodeResult.append(node)
                    } else {
                        break
                    }
                }
                cont.resume(returning: nodeResult.map { self.getDisplayInfo(for: $0, fileURL: resultURL, line: line, column: column) })
                return
            }
        }
    }
    
    
    
    /// Based on the relevant information about the output file, search for the corresponding location in the source code.
    ///
    /// - Parameter page: The location being searched for is on page numbers in the output file. Let's assume that the page numbers start from `1`.
    /// - Parameter h: The horizontal position of the queried location in the coordinate system of the page page in the output file, with `72` dpi as the unit, is assumed to be measured from the origin located at the top left corner of the page.
    /// - Parameter v: The vertical position of the queried location in the coordinate system of the page page in the output file, with `72` dpi as the unit, is assumed to be measured from the origin located at the top left corner of the page.
    public func editQuery(page: Int, h: CGFloat, v: CGFloat) async -> [NodeEditInfo] {
        return await withUnsafeContinuation { (cont: UnsafeContinuation<[NodeEditInfo], Never>) -> Void in
            queue.async {
                synctex_scanner_reset_result(self.scanner)
                let queryResultCount = synctex_edit_query(self.scanner, Int32(page), Float(h), Float(v))
                guard queryResultCount > 0 else {
                    cont.resume(returning: [])
                    return
                }
                var node: synctex_node_p?
                var nodeResult = [synctex_node_p]()
                while(true) {
                    node = synctex_scanner_next_result(self.scanner)
                    if let node = node {
                        nodeResult.append(node)
                    } else {
                        break
                    }
                }
                synctex_scanner_reset_result(self.scanner)
                cont.resume(returning: nodeResult.map { self.getEditInfo(for: $0, page: page, h: h, v: v) })
            }
        }
    }
    
    
    
    private func getEditInfo(for node: synctex_node_p, page: Int, h: CGFloat, v: CGFloat) -> NodeEditInfo {
        return .init(page: page, h: h, v: v, path: synctex_node_get_name(node), line: Int(synctex_node_line(node)), column: Int(synctex_node_column(node)))
    }
    
    
    private func getDisplayInfo(for node: synctex_node_p, fileURL: URL, line: Int, column: Int) -> NodeDisplayInfo {
        let boxh = CGFloat(synctex_node_box_visible_h(node))
        let boxv = CGFloat(synctex_node_box_visible_v(node))
        let boxwidth = CGFloat(synctex_node_box_visible_width(node))
        let boxheight = CGFloat(synctex_node_box_visible_height(node))
        let boxd = CGFloat(synctex_node_box_visible_depth(node))
        
        let h = CGFloat(synctex_node_visible_h(node))
        let v = CGFloat(synctex_node_visible_v(node))
        let width = CGFloat(synctex_node_visible_width(node))
        let height = CGFloat(synctex_node_visible_height(node))
        let d = CGFloat(synctex_node_visible_depth(node))
        
        return .init(fileURL: fileURL, line: line, column: column, boxh: boxh, boxv: boxv, boxwidth: boxwidth, boxheight: boxheight, boxd: boxd, h: h, v: v, width: width, height: height, d: d)
    }
    
}


#endif
