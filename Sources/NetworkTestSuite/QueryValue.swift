//
//  QueryValue.swift
//  IntegrationTestSuite
//
//  Created by Andrew J Wagner on 11/15/16.
//
//

public protocol QueryValue {
    func string() throws -> String
}

extension String: QueryValue {}
