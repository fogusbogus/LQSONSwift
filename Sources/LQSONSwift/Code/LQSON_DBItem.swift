//
//  LQSON_DBItem.swift
//  LQSON
//
//  Created by Matt Hogg on 23/06/2024.
//

import Foundation

import StringFunctions


public class LQSON_DBItem: Codable {
	public init(pk: String, sk: String = "", meta: [String:String] = [:], data: Data? = nil) {
		self.pk = pk
		self.sk = sk
		self.meta = meta
		self.data = data
	}
	public required init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.pk = try container.decode(String.self, forKey: .pk)
		self.sk = try container.decode(String.self, forKey: .sk)
		self.meta = try container.decode([String:String].self, forKey: .meta)
		self.data = try container.decodeIfPresent(Data.self, forKey: .data)
	}
	enum CodingKeys: CodingKey {
		case pk
		case sk
		case meta
		case data
	}
	
	public func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(self.pk, forKey: .pk)
		try container.encode(self.sk, forKey: .sk)
		try container.encode(self.meta, forKey: .meta)
		try container.encodeIfPresent(self.data, forKey: .data)
	}
	public var pk: String
	public var sk: String
	public var meta: [String:String]
	public var data: Data?
	
	public func setMeta(meta: [String:String]) {
		meta.forEach { kv in
			self.meta[kv.key] = kv.value
		}
	}
	
	public func getData<T>(defaultValue: T) -> T? {
		return self.data as? T
	}
}
