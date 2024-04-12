//
//  OutputInfo.swift
//  
//
//  Created by mengchao on 2023/7/19.
//


#if os(iOS)

import Foundation

extension SyncTeXScanner {
    
    /// Display information corresponding to a certain source code location.
    ///
    /// You can use this information to uniquely determine the corresponding location of the output file.
    public struct NodeDisplayInfo: CustomStringConvertible {
        /// A textual representation of this instance.
        public var description: String {
            let mirror = Mirror(reflecting: self)
            var result = "---[NodeDisplayInfo]---\n"
            for case let (property?, value) in mirror.children {
                result.append("|--\(property): \(value)\n")
            }
            result.append("-------[End]-------")
            return result
        }
        /// The `URL` corresponding to the source file.
        public let fileURL: URL
        /// The line in the source file where the query position is located.
        public let line: Int
        /// The column in the source file where the query position is located.
        public let column: Int
        /// The horizontal location of node.
        ///
        /// The point is in the page coordinates.
        public let h: CGFloat
        /// The vertical location of node.
        ///
        /// The point is in the page coordinates.
        public let v: CGFloat
        /// The width of the node.
        ///
        /// The width is in the page coordinates.
        public let width: CGFloat
        /// The height of the node.
        ///
        /// The height is in the page coordinates.
        public let height: CGFloat
        /// The depth of the node.
        ///
        /// The value is not useful for node display.
        public let d: CGFloat
        /// The horizontal location of the first box enclosing node.
        ///
        /// The value is in the page coordinates.
        public let boxh: CGFloat
        /// The vertical location of the first box enclosing node.
        ///
        /// The value is in the page coordinates.
        public let boxv: CGFloat
        /// The width of the first box enclosing node.
        ///
        /// The value is in the page coordinates.
        public let boxwidth: CGFloat
        /// The height of the first box enclosing node.
        ///
        /// The value is in the page coordinates.
        public let boxheight: CGFloat
        /// The depth of the first box enclosing node.
        ///
        /// The value is in the page coordinates.
        public let boxd: CGFloat
        
        internal init(fileURL: URL, line: Int, column: Int, boxh: CGFloat, boxv: CGFloat, boxwidth: CGFloat, boxheight: CGFloat, boxd: CGFloat, h: CGFloat, v: CGFloat, width: CGFloat, height: CGFloat, d: CGFloat) {
            self.fileURL = fileURL
            self.column = column
            self.line = line
            self.boxh = boxh
            self.boxv = boxv
            self.boxwidth = boxwidth
            self.boxheight = boxheight
            self.boxd = boxd
            self.h = h
            self.v = v
            self.width = width
            self.height = height
            self.d = d
        }
    }
    
    /// Source file information corresponding to a certain output display location.
    ///
    /// You can use this information to uniquely determine the corresponding location of the source file.
    public struct NodeEditInfo: CustomStringConvertible {
        public var description: String {
            let mirror = Mirror(reflecting: self)
            var result = "---[NodeEditorInfo]---\n"
            for case let (property?, value) in mirror.children {
                result.append(" -\(property): \(value)\n")
            }
            result.append("-------[End]-------")
            return result
        }
        /// The page number where the display position is located, starting from `1`.
        public let page: Int
        /// The horizontal coordinate of the position in the page coordinate system (with the upper-left corner of the page as the origin and `72` dpi as the unit).
        public let h: CGFloat
        /// The vertical coordinate of the position in the page coordinate system (with the upper-left corner of the page as the origin and `72` dpi as the unit).
        public let v: CGFloat
        /// URL of the source code file.
        public let fileURL: URL
        /// The corresponding line number of the source code file.
        public let line: Int
        /// The corresponding column number of the source code file.
        ///
        /// If the value is `nil`, it means the entire line.
        public let column: Int?
        
        internal init(page: Int, h: CGFloat, v: CGFloat, path: UnsafePointer<Int8>, line: Int, column: Int) {
            self.page = page
            self.h = h
            self.v = v
            self.fileURL = URL(fileURLWithFileSystemRepresentation: path, isDirectory: false, relativeTo: nil)
                            .standardizedFileURL
            self.line = line
            if column <= 0 {
                self.column = nil
            } else {
                self.column = column
            }
        }
    }
}


#endif /* os(iOS) */
