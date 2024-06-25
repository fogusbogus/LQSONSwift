//
//  DB.swift
//  LQSON
//
//  Created by Matt Hogg on 25/06/2024.
//

import Foundation
import StringFunctions

public class LQSON_DB {
	public static var shared = LQSON_DB()
	private init() {
		let url = FileManager.default.homeDirectoryForCurrentUser.appending(path: "SKWLSFB.db", directoryHint: .isDirectory)
		path = ""
		setDB(url: url)
	}
	
	var path: String {
		didSet {
			if path.starts(with: "file://") {
				path.removeFirst(7)
			}
		}
	}
	
	public func setDB(url: URL, removeDeadIndexes: Bool = false) {
		if url.isDirectory {
			path = url.absoluteString
		}
		else {
			if url.validPath {
				try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
				path = url.absoluteString
			}
		}
		try? Helper.dbIndexer.setIndexFile(filename: url.appending(path: "index.json").absoluteString, removeDead: removeDeadIndexes)
	}
	
	public typealias PKFilter = (_ pk: String) -> Bool
	public typealias PKSKFilter = (_ pk: String, _ sk: String) -> Bool
	
	public func getPKs(filter: PKFilter? = nil, limit: Int? = nil) -> [String] {
		if var files = try? FileManager.default.contentsOfDirectory(atPath: path).filter({$0.contains("#") && $0.contains(".json")}) {
			files = files.map {$0.after("#", options: [.allIfMissing]).before(".", options: [.allIfMissing])}.unique()
			
			var mapped = files.map {Helper.decode(pk: $0)}
			let limit = limit ?? Int.max
			if mapped.count <= limit { return mapped.sorted() }
			mapped.sort()
			mapped.removeLast(mapped.count - limit)
			return mapped
		}
		return []
	}
	
	public func getPKSKs(filter: PKSKFilter? = nil, limit: Int? = nil) -> [(pk: String, sk: String)] {
		if let files = try? FileManager.default.contentsOfDirectory(atPath: path).filter({$0.contains("#") && $0.contains(".json")}) {
			return files.map { file in
				return Helper.decodePKSK(file)
			}.sorted(by: {$0.pk < $1.pk && $0.sk < $1.sk})
		}
		return []
	}
	
	public func getPKSKCollection(filter: PKSKFilter? = nil, limit: Int? = nil) -> [String:[String]] {
		let all = getPKSKs(filter: filter, limit: limit)
		var ret: [String:[String]] = [:]
		all.forEach { item in
			if !ret.keys.contains(item.pk) {
				ret[item.pk] = []
			}
			ret[item.pk]!.append(item.sk)
		}
		
		return ret
	}
	
	public func getItem(pk: String, sk: String) -> LQSON_DBItem? {
		let fn = Helper.encodePKSK(pk: pk, sk: sk)
		if FileManager.default.fileExists(atPath: path.appending("\(fn).json")) {
			if let data = try? Data(contentsOf: URL(fileURLWithPath: path.appending("\(fn).json"))) {
				return try? JSONDecoder().decode(LQSON_DBItem.self, from: data)
			}
		}
		return nil
	}
	
	public func scanItems(pk: String) -> [LQSON_DBItem] {
		let fn = Helper.encodePKSK(pk: pk)
		var ret: [LQSON_DBItem] = []
		if let files = try? FileManager.default.contentsOfDirectory(atPath: path).filter({$0.hasSuffix(fn)}) {
			files.forEach { file in
				if let data = try? Data(contentsOf: URL(fileURLWithPath: path.appending("\(fn).json"))) {
					if let item = try? JSONDecoder().decode(LQSON_DBItem.self, from: data) {
						ret.append(item)
					}
				}
			}
		}
		return ret.sorted(by: {$0.sk < $1.sk})
	}
	
	public func setItem(pk: String, sk: String, data: [String:String] = [:], merge: Bool = false) {
		guard !pk.isEmpty else { return }
		if merge {
			let existing = getItem(pk: pk, sk: sk) ?? LQSON_DBItem(pk: pk, sk: sk)
			existing.setMeta(meta: data)
			let fn = fileNameFor(pk: pk, sk: sk)
			if let json = try? JSONEncoder().encode(existing) {
				try? json.write(to: URL(fileURLWithPath: fn))
			}
		}
		else {
			let fn = fileNameFor(pk: pk, sk: sk)
			let item = LQSON_DBItem(pk: pk, sk: sk)
			item.setMeta(meta: data)
			if let json = try? JSONEncoder().encode(item) {
				try? json.write(to: URL(fileURLWithPath: fn))
			}
		}
	}
	
	private func fileNameFor(pk: String, sk: String = "", usePath: Bool = true) -> String {
		if usePath {
			return path + Helper.encodePKSK(pk: pk, sk: sk)	+ ".json"
		}
		return Helper.encodePKSK(pk: pk, sk: sk) + ".json"
	}
	
	public func undeleteItem(pk: String, sk: String, overwrite: Bool = true) {
		let fn = fileNameFor(pk: pk, sk: sk)
		if !FileManager.default.fileExists(atPath: fn + ".deleted") { return }
		if FileManager.default.fileExists(atPath: fn) && overwrite {
			try? FileManager.default.removeItem(atPath: fn)
			try? FileManager.default.moveItem(atPath: fn + ".deleted", toPath: fn)
		}
	}
	
	public func deleteItem(pk: String, sk: String) {
		if getItem(pk: pk, sk: sk) != nil {
			let fn = fileNameFor(pk: pk, sk: sk)
			let delFn = fn + ".deleted"
			if FileManager.default.fileExists(atPath: delFn) {
				try? FileManager.default.removeItem(atPath: delFn)
			}
			if !FileManager.default.fileExists(atPath: delFn) {
				do {
					try FileManager.default.moveItem(atPath: fn, toPath: delFn)
				}
				catch {
					print(error)
				}
			}
		}
	}
	
	public func purgeDeleted(pk: String? = nil) {
		if let pk {
			let pkEnc = Helper.encodePKSK(pk: pk)
			if let candidates = try? FileManager.default.contentsOfDirectory(atPath: path).filter({$0.hasSuffix("\(pkEnc).json.deleted")}) {
				candidates.forEach {try? FileManager.default.removeItem(atPath: path + $0)}
			}
		}
		else {
			try? FileManager.default.contentsOfDirectory(atPath: path).filter {$0.hasSuffix(".deleted")}.forEach {try? FileManager.default.removeItem(atPath: path + $0)}
		}
	}
}
