//
//  ResultCollection.swift
//  NetworkTestSuite
//
//  Created by Andrew J Wagner on 11/10/16.
//
//

import Foundation

public class ResultCollection: CustomStringConvertible {
    var rootResult = SuiteResult(level: 0)

    func fail(spec: TestSpec, withError error: Error, request: URLRequest?, response: HTTPURLResponse?, data: Data?) {
        let newResult = self.rootResult.addResult(status: .failed(error, request, response, data), atPath: spec.namePath, atLevel: 0)
        print("\u{001B}[0;31m\(newResult.realTimeDescription(at: spec.namePath))\u{001B}[m")
    }

    func pass(spec: TestSpec) {
        let newResult = self.rootResult.addResult(status: .passed, atPath: spec.namePath, atLevel: 0)
        print(newResult.realTimeDescription(at: spec.namePath))
    }

    public var description: String {
        var output = ""

        output += "\n============================\n"

        if let fail = self.rootResult.failDescription {
            output += fail
        }
        else {
            output += "All Tests Passed"
        }

        output += "\n"

        return output
    }
}
