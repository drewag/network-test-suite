//
//  ParsedResponseKey.swift
//  IntegrationTestSuite
//
//  Created by Andrew J Wagner on 11/11/16.
//
//

public protocol ParsableResponse {
    init()
    var asObject: Any { get }
}
extension String: ParsableResponse { public var asObject: Any { return self as Any } }
extension Bool: ParsableResponse { public var asObject: Any { return self as Any } }
extension Int: ParsableResponse { public var asObject: Any { return self as Any } }
extension Double: ParsableResponse { public var asObject: Any { return self as Any } }
extension Float: ParsableResponse { public var asObject: Any { return self as Any } }

open class ParsedResponseKey<Value: ParsableResponse> {}

extension ParsedResponseKey {
    static var rawKey: String {
        return String(describing: Mirror(reflecting: self).subjectType).components(separatedBy: ".").first!
    }
}
