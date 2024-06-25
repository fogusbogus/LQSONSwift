//
//  Helper.swift
//  LQSON
//
//  Created by Matt Hogg on 23/06/2024.
//

import Foundation

import StringFunctions

class Helper {
	
	private static let hex = Array("0123456789abcdef")
	
	static var dbIndexer = DBIndex()
	
	static func encodePKSK(pk: String, sk: String = "") -> String {
		let key = dbIndexer.generate(pk: pk, sk: sk)
		return "\(key.sk)#\(key.pk)"
	}
	
	static func decodePKSK(_ pksk: String) -> (pk: String, sk: String) {
		let sk = pksk.before("#")
		let pk = pksk.after("#").before(".", options: [.allIfMissing])
		return (pk: dbIndexer.lookup(pk: String(pk)), sk: dbIndexer.lookup(sk: String(sk)))
	}
	static func decode(pk: String) -> String {
		let pk = pk.after("#", options: [.allIfMissing]).before(".", options: [.allIfMissing])
		return dbIndexer.lookup(pk: pk)
	}
	static func decode(sk: String) -> String {
		let sk = sk.before("#", options: [.allIfMissing])
		return dbIndexer.lookup(sk: sk)
	}
}

