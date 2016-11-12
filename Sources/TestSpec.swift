//
//  TestSpec.swift
//  NetworkTestSuite
//
//  Created by Andrew J Wagner on 11/10/16.
//
//

import Foundation

public class TestSpec: Test {
    enum GetHeadersResult {
        case success([String:String])
        case failed(failedKey: String)
    }

    enum Endpoint {
        case string(String)
        case parsed(ParsedResponseValue)
    }

    enum GetEndpointResult {
        case success(String)
        case failed
    }

    public let name: String
    public let headers: [String:Any]
    let endpoint: Endpoint
    let method: Method
    let data: Data?
    let test: (Response) throws -> ()

    public var parent: Test?

    public var description: String {
        return "\"\(self.name)\""
    }

    public init(
        name: String,
        endpoint: String,
        method: Method,
        data: Data? = nil,
        headers: [String:Any] = [:],
        test: @escaping (Response) throws -> ()
        )
    {
        self.name = name
        self.endpoint = .string(endpoint)
        self.method = method
        self.data = data
        self.test = test
        self.headers = headers
    }

    public init(
        name: String,
        endpoint: ParsedResponseValue,
        method: Method,
        data: Data? = nil,
        headers: [String:Any] = [:],
        test: @escaping (Response) throws -> ()
        )
    {
        self.name = name
        self.endpoint = .parsed(endpoint)
        self.method = method
        self.data = data
        self.test = test
        self.headers = headers
    }

    public init(
        name: String,
        endpoint: String,
        method: Method,
        headers: [String:Any] = [:],
        json: [String:Any],
        test: @escaping (Response) throws -> ()
        )
    {
        self.name = name
        self.endpoint = .string(endpoint)
        self.method = method
        self.data = try! JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
        self.test = test
        self.headers = headers
    }

    public init(
        name: String,
        endpoint: ParsedResponseValue,
        method: Method,
        headers: [String:Any] = [:],
        json: [String:Any],
        test: @escaping (Response) throws -> ()
        )
    {
        self.name = name
        self.endpoint = .parsed(endpoint)
        self.method = method
        self.data = try! JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
        self.test = test
        self.headers = headers
    }

    public func perform(onURL URL: URL, inQueue queue: OperationQueue, reportingResultsTo resultCollection: ResultCollection, onComplete: @escaping () -> ()) {
        self.getEndpoint { result in
            switch result {
            case .failed:
                let error = TestError(description: "Dependent parsed response value for endpoint failed")
                resultCollection.fail(spec: self, withError: error, request: nil, response: nil, data: nil)
                onComplete()
            case .success(let endpoint):
                self.getAllHeaders { result in
                    switch result {
                    case .failed(failedKey: let key):
                        let error = TestError(description: "Dependent parsed response value \(key) failed")
                        resultCollection.fail(spec: self, withError: error, request: nil, response: nil, data: nil)
                        onComplete()
                    case .success(let headers):
                        let URL = URL.appendingPathComponent(endpoint)
                        var request = URLRequest(url: URL)
                        request.httpBody = self.data
                        request.httpMethod = self.method.rawValue
                        request.allHTTPHeaderFields = headers
                        NSURLConnection.sendAsynchronousRequest(request, queue: queue) { rawResponse, data, error in
                            if let error = error {
                                resultCollection.fail(spec: self, withError: error, request: request, response: rawResponse as? HTTPURLResponse, data: data)
                                onComplete()
                                return
                            }

                            let response = Response(rawResponse: rawResponse as! HTTPURLResponse, data: data)
                            do {
                                try self.test(response)
                                resultCollection.pass(spec: self)
                            }
                            catch let error {
                                resultCollection.fail(spec: self, withError: error, request: request, response: rawResponse as? HTTPURLResponse, data: data)
                            }

                            onComplete()
                        }
                    }
                }
            }
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
                    if let string = parsedValue.value {
                        onComplete(.success(string))
                    }
                    else {
                        onComplete(.failed)
                    }
                }
            }
        }
    }

    func getAllHeaders(onComplete: @escaping (GetHeadersResult) -> ()) {
        var pendingValuesCount = 0
        var allHeaders = [String:Any]()

        var retrievedCount = 0
        func checkDone() {
            retrievedCount += 1
            if retrievedCount == pendingValuesCount {
                for (key, value) in allHeaders {
                    if let parsedValue = value as? ParsedResponseValue {
                        if let string = parsedValue.value {
                            allHeaders[key] = string
                        }
                        else {
                            onComplete(.failed(failedKey: key))
                            return
                        }
                    }
                }

                onComplete(.success(allHeaders as! [String:String]))
            }
        }

        var test: Test = self
        while let parent = test.parent {
            for (key, value) in test.headers {
                if allHeaders[key] == nil {
                    allHeaders[key] = value
                    if let parsedValue = value as? ParsedResponseValue {
                        pendingValuesCount += 1
                        parsedValue.status.addNewObserver(self, options: .OnlyOnce | .Initial) { status in
                            switch status {
                            case .waiting:
                                return
                            case .parsed, .failed:
                                checkDone()
                            }
                        }
                    }
                }
            }

            test = parent
        }

        if pendingValuesCount == 0 {
            onComplete(.success(allHeaders as! [String:String]))
        }
    }
}
