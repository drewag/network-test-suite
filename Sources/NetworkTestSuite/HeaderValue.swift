//
//  HeaderValueConvertible.swift
//  IntegrationTestSuite
//
//  Created by Andrew J Wagner on 11/15/16.
//
//

public protocol HeaderValue {
    func string() throws -> String
}

extension String: HeaderValue {
    public func string() throws -> String {
        return self
    }
}
