//
//  Extensions.swift
//  LQSON
//
//  Created by Matt Hogg on 25/06/2024.
//

import Foundation
import StringFunctions

@available(macOS 13.0, *)
extension FileManager {
	func isDirectory(path: String) -> Bool {
		return URL(filePath: path, directoryHint: .isDirectory).isDirectory
	}
	
	var temporaryFile : URL {
		get {
			let folder = FileManager.default.temporaryDirectory
			var fn = UUID().uuidString
			while FileManager.default.fileExists(atPath: folder.appending(path: fn).relativePath) {
				fn = UUID().uuidString
			}
			return folder.appending(path: fn)
		}
	}
	
	func deleteAll(_ path: String) {
		if let filesAndFolders = try? contentsOfDirectory(atPath: path) {
			filesAndFolders.forEach { cand in
				let cand = path.appending("/\(cand)")
				if isDirectory(path: cand) {
					deleteAll(cand)
				}
				else {
					try? removeItem(atPath: cand)
				}
			}
		}
		try? removeItem(atPath: path)
	}
}

extension URL {
	var isDirectory: Bool {
		(try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
	}
	
	var validPath : Bool {
		let invalidCharsets = CharacterSet(charactersIn: ":/\\")
			.union(.illegalCharacters)
			.union(.controlCharacters)
			.union(.symbols)
			.union(.newlines)
		var components = self.pathComponents
		components.removeFirst()
		return !components.contains(where: {$0.components(separatedBy: invalidCharsets).count > 1})
	}
}

extension Array where Element: Hashable {
	func unique() -> Self {
		return Array(Set(self))
	}
}

extension URL {
	var absoluteStringNoType: String {
		if absoluteString.contains(":") {
			return absoluteString.after("//", options: [.allIfMissing])
		}
		return absoluteString
	}
}
