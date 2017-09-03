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
    public let queryParameters: [String:QueryValue]
    public let headers: [String:HeaderValue]

    enum Endpoint {
        case string(String)
        case parsed(ParsedResponseValue)
    }

    enum GetEndpointResult {
        case success(String)
        case failed
    }

    let endpoint: Endpoint
    let tests: [Test]
    let synchronous: Bool

    public var parent: Test?

    public var description: String {
        var output = "{\"\(self.name)\":["

        output += self.tests.map({$0.description}).joined(separator: ",")

        output += "]}"
        return output
    }

    public init(
        name: String,
        endpoint: String,
        synchronous: Bool = true,
        queryParameters: [String:QueryValue] = [:],
        headers: [String:HeaderValue] = [:],
        tests: [Test]
        )
    {
        self.name = name
        self.endpoint = .string(endpoint)
        self.tests = tests
        self.synchronous = synchronous
        self.queryParameters = queryParameters
        self.headers = headers

        for test in self.tests {
            test.parent = self
        }
    }

    public init(
        name: String,
        endpoint: ParsedResponseValue,
        synchronous: Bool = true,
        queryParameters: [String:QueryValue] = [:],
        headers: [String:HeaderValue] = [:],
        tests: [Test]
        )
    {
        self.name = name
        self.endpoint = .parsed(endpoint)
        self.tests = tests
        self.synchronous = synchronous
        self.queryParameters = queryParameters
        self.headers = headers

        for test in self.tests {
            test.parent = self
        }
    }

    public func perform(
        onURL URL: URL,
        inQueue queue: OperationQueue,
        reportingResultsTo resultCollection: ResultCollection,
        onComplete: @escaping () -> ()
        )
    {
        self.getEndpoint { result in
            switch result {
            case .failed:
                let error = TestError(description: "Dependent parsed response value for endpoint failed")
                self.report(error, request: nil, response: nil, data: nil, to: resultCollection)
                onComplete()
            case .success(let string):
                let URL = URL.appendingPathComponent(string)
                if self.synchronous {
                    self.perform(tests: self.tests, synchronouslyOnURL: URL, inQueue: queue, reportingResultsTo: resultCollection, onComplete: onComplete)
                }
                else {
                    self.performAsynchronous(onURL: URL, inQueue: queue, reportingResultsTo: resultCollection, onComplete: onComplete)
                }
            }
        }
    }

    public func report(_ error: Error, request: URLRequest?, response: HTTPURLResponse?, data: Data?, to resultCollection: ResultCollection) {
        guard tests.count > 0 else {
            return
        }

        for test in self.tests {
            test.report(error, request: nil, response: nil, data: nil, to: resultCollection)
        }
    }
}

private extension TestSuite {
    func perform(
        tests: [Test],
        synchronouslyOnURL URL: URL,
        inQueue queue: OperationQueue,
        reportingResultsTo resultCollection: ResultCollection,
        onComplete: @escaping () -> ()
        )
    {
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

    func performAsynchronous(
        onURL URL: URL,
        inQueue queue: OperationQueue,
        reportingResultsTo resultCollection: ResultCollection,
        onComplete: @escaping () -> ()
        )
    {
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

    func getEndpoint(onComplete: @escaping (GetEndpointResult) -> ()) {
        switch self.endpoint {
        case .string(let string):
            onComplete(.success(string))
        case .parsed(let parsedValue):
            parsedValue.status.addNewObserver(self, options: .OnlyOnce | .Initial) { status in
                switch status {
                case .waiting:
                    return
                case .parsed, .failed:
                    do {
                        let string = try parsedValue.string()
                        onComplete(.success(string))
                    }
                    catch {
                        onComplete(.failed)
                    }
                }
            }
        }
    }
}
