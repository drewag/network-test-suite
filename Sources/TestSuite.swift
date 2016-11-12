//
//  TestSuite.swift
//  NetworkTestSuite
//
//  Created by Andrew Wagner on 11/10/16.
//
//

import Foundation

open class TestSuite: Test {
    public let name: String
    public let headers: [String:Any]
    let endpoint: String
    let tests: [Test]
    let synchronous: Bool

    public var parent: Test?

    public var description: String {
        var output = "{\"\(self.name)\":["

        output += self.tests.map({$0.description}).joined(separator: ",")

        output += "]}"
        return output
    }

    public init(name: String, endpoint: String, synchronous: Bool = true, headers: [String:Any] = [:], tests: [Test]) {
        self.name = name
        self.endpoint = endpoint
        self.tests = tests
        self.synchronous = synchronous
        self.headers = headers

        for test in self.tests {
            test.parent = self
        }
    }

    public func perform(onURL URL: URL, inQueue queue: OperationQueue, reportingResultsTo resultCollection: ResultCollection, onComplete: @escaping () -> ()) {
        let URL = URL.appendingPathComponent(self.endpoint)
        if self.synchronous {
            self.perform(tests: self.tests, synchronouslyOnURL: URL, inQueue: queue, reportingResultsTo: resultCollection, onComplete: onComplete)
        }
        else {
            self.performAsynchronous(onURL: URL, inQueue: queue, reportingResultsTo: resultCollection, onComplete: onComplete)
        }
    }
}

private extension TestSuite {
    func perform(tests: [Test], synchronouslyOnURL URL: URL, inQueue queue: OperationQueue, reportingResultsTo resultCollection: ResultCollection, onComplete: @escaping () -> ()) {
        guard tests.count > 0 else {
            onComplete()
            return
        }

        var remainingTests = tests
        let test = remainingTests.removeFirst()
        test.perform(onURL: URL, inQueue: queue, reportingResultsTo: resultCollection) {
            self.perform(tests: remainingTests, synchronouslyOnURL: URL, inQueue: queue, reportingResultsTo: resultCollection, onComplete: onComplete)
        }
    }

    func performAsynchronous(onURL URL: URL, inQueue queue: OperationQueue, reportingResultsTo resultCollection: ResultCollection, onComplete: @escaping () -> ()) {
        let originalTestCount = self.tests.count
        var completedCount = 0
        func completion() {
            completedCount += 1
            if completedCount == originalTestCount {
                onComplete()
            }
        }

        for test in self.tests {
            test.perform(onURL: URL, inQueue: queue, reportingResultsTo: resultCollection, onComplete: completion)
        }
    }
}
