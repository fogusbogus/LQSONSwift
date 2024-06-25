//
//  Indexes.swift
//  LQSON
//
//  Created by Matt Hogg on 25/06/2024.
//

import Foundation
import StringFunctions

class DBIndex {
	private var filename: String = ""
	
	var indexes = DBIndexes()
	
	func ratifyIndexFile() {
		let file = URL(filePath: filename)
		let path = file.deletingLastPathComponent()
		if let allFiles = try? FileManager.default.contentsOfDirectory(atPath: path.absoluteStringNoType).filter({$0.contains("#") && $0.contains(".json")}) {
			let pks = allFiles.map {$0.after("#").before(".json")}.unique()
			let sks = allFiles.map {$0.before("#")}.unique()
			indexes.pk.rmap.keys.filter {!pks.contains($0)}.forEach { key in
				indexes.pk.removeMap(key: key)
			}
			indexes.sk.rmap.keys.filter {!sks.contains($0)}.forEach { key in
				indexes.sk.removeMap(key: key)
			}
		}
	}
	
	func setIndexFile(filename: String, removeDead: Bool = false) throws {
		guard !filename.implies(self.filename) else { return }
		if !filename.isWhitespaceOrEmpty {
			save()
		}
		var filename = filename
		if filename.starts(with: "file://") {
			filename.removeFirst(7)
		}
		if FileManager.default.fileExists(atPath: filename) {
			if let data = try? Data(contentsOf: URL(fileURLWithPath: filename)) {
				do {
					indexes = try JSONDecoder().decode(DBIndexes.self, from: data)
					self.filename = filename
				}
				catch {
					throw error
				}
			}
			if removeDead {
				ratifyIndexFile()
			}
		}
		else {
			self.filename = filename
		}
	}
	
	private func save() {
		if let json = try? JSONEncoder().encode(indexes) {
			try? json.write(to: URL(fileURLWithPath: filename))
		}
	}
	
	func generate(pk: String) -> String {
		let ret = indexes.pk.generate(name: pk)
		if ret.new { save() }
		return ret.key
	}
	func generate(sk: String) -> String {
		let ret = indexes.sk.generate(name: sk)
		if ret.new { save() }
		return ret.key
	}
	
	func generate(pk: String, sk: String) -> (pk: String, sk: String) {
		let retPK = indexes.pk.generate(name: pk)
		let retSK = indexes.sk.generate(name: sk)
		if retPK.new || retSK.new { save() }
		return (pk: retPK.key, sk: retSK.key)
	}
	
	func lookup(pk: String) -> String {
		return indexes.pk.lookup(key: pk)
	}
	
	func lookup(sk: String) -> String {
		return indexes.sk.lookup(key: sk)
	}
}

class DBIndexed: Codable {
	var map: [String:String] = [:]
	var rmap: [String:String] = [:]
	
	func generate(name: String) -> (key: String, new: Bool) {
		if map.keys.contains(name) { return (key: map[name]!, new: false) }
		var uuid = UUID().uuidString
		while map.values.contains(uuid) {
			uuid = UUID().uuidString
		}
		self.map[name] = uuid
		self.rmap[uuid] = name
		return (key: uuid, new: true)
	}
	
	func lookup(key: String) -> String {
		guard self.rmap.keys.contains(key) else { return "" }
		return self.rmap[key]!
	}
	
	func removeMap(key: String) {
		guard self.rmap.keys.contains(key) else { return }
		let rKey = rmap[key]!
		rmap.removeValue(forKey: key)
		map.removeValue(forKey: rKey)
	}
}

class DBIndexes: Codable {
	var pk = DBIndexed()
	var sk = DBIndexed()
}
