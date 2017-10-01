//
//  TestSpec.swift
//  NetworkTestSuite
//
//  Created by Andrew J Wagner on 11/10/16.
//
//

import Foundation

public class TestSpec: Test {
    enum GetDictResult {
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
    public let queryParameters: [String:QueryValue]
    public let headers: [String:HeaderValue]
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
        queryParameters: [String:QueryValue] = [:],
        headers: [String:HeaderValue] = [:],
        test: @escaping (Response) throws -> ()
        )
    {
        self.name = name
        self.endpoint = .string(endpoint)
        self.method = method
        self.data = data
        self.test = test
        self.queryParameters = queryParameters
        self.headers = headers
    }

    public init(
        name: String,
        endpoint: ParsedResponseValue,
        method: Method,
        data: Data? = nil,
        queryParameters: [String:QueryValue] = [:],
        headers: [String:HeaderValue] = [:],
        test: @escaping (Response) throws -> ()
        )
    {
        self.name = name
        self.endpoint = .parsed(endpoint)
        self.method = method
        self.data = data
        self.test = test
        self.queryParameters = queryParameters
        self.headers = headers
    }

    public init(
        name: String,
        endpoint: String,
        method: Method,
        queryParameters: [String:QueryValue] = [:],
        headers: [String:HeaderValue] = [:],
        json: [String:Any],
        test: @escaping (Response) throws -> ()
        )
    {
        self.name = name
        self.endpoint = .string(endpoint)
        self.method = method
        self.data = try! JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
        self.test = test
        self.queryParameters = queryParameters
        self.headers = headers
    }

    public init(
        name: String,
        endpoint: ParsedResponseValue,
        method: Method,
        queryParameters: [String:QueryValue] = [:],
        headers: [String:HeaderValue] = [:],
        json: [String:Any],
        test: @escaping (Response) throws -> ()
        )
    {
        self.name = name
        self.endpoint = .parsed(endpoint)
        self.method = method
        self.data = try! JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
        self.test = test
        self.queryParameters = queryParameters
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
                self.perform(onURL: URL, endpoint: endpoint, inQueue: queue, reportingResultsTo: resultCollection, onComplete: onComplete)
            }
        }
    }

    func getEndpoint(onComplete: @escaping (GetEndpointResult) -> ()) {
        switch self.endpoint {
        case .string(let string):
            onComplete(.success(string))
        case .parsed(let parsedValue):
            parsedValue.status.addNewValueObserver(self, options: [.onlyOnce, .initial]) { status in
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

    func getAllHeaders(onComplete: @escaping (GetDictResult) -> ()) {
        var pendingValuesCount = 0
        var allHeaders = [String:HeaderValue]()

        var retrievedCount = 0
        func checkDone() {
            if retrievedCount == pendingValuesCount {
                for (key, value) in allHeaders {
                    if let parsedValue = value as? ParsedResponseValue {
                        do {
                            let string = try parsedValue.string()
                            allHeaders[key] = string
                        }
                        catch {
                            onComplete(.failed(failedKey: key))
                            return
                        }
                    }
                }

                var finalHeades = [String:String]()
                for (key, value) in allHeaders {
                    do {
                        finalHeades[key] = try value.string()
                    }
                    catch {
                        onComplete(.failed(failedKey: key))
                        return
                    }

                }
                onComplete(.success(finalHeades))
            }
        }

        var test: Test = self
        while let parent = test.parent {
            for (key, value) in test.headers {
                if allHeaders[key] == nil {
                    allHeaders[key] = value
                    if let parsedValue = value as? ParsedResponseValue {
                        pendingValuesCount += 1
                        parsedValue.status.addNewValueObserver(self, options: [.onlyOnce, .initial]) { status in
                            switch status {
                            case .waiting:
                                return
                            case .parsed, .failed:
                                retrievedCount += 1
                                checkDone()
                            }
                        }
                    }
                }
            }

            test = parent
        }

        if pendingValuesCount == 0 {
            checkDone()
        }
    }

    func getAllQueryParameters(onComplete: @escaping (GetDictResult) -> ()) {
        var pendingValuesCount = 0
        var allQueryParameters = [String:QueryValue]()

        var retrievedCount = 0
        func checkDone() {
            if retrievedCount == pendingValuesCount {
                for (key, value) in allQueryParameters {
                    if let parsedValue = value as? ParsedResponseValue {
                        do {
                            let string = try parsedValue.string()
                            allQueryParameters[key] = string
                        }
                        catch {
                            onComplete(.failed(failedKey: key))
                            return
                        }
                    }
                }

                var finalHeades = [String:String]()
                for (key, value) in allQueryParameters {
                    do {
                        finalHeades[key] = try value.string()
                    }
                    catch {
                        onComplete(.failed(failedKey: key))
                        return
                    }

                }
                onComplete(.success(finalHeades))
            }
        }

        var test: Test = self
        while let parent = test.parent {
            for (key, value) in test.queryParameters {
                if allQueryParameters[key] == nil {
                    allQueryParameters[key] = value
                    if let parsedValue = value as? ParsedResponseValue {
                        pendingValuesCount += 1
                        parsedValue.status.addNewValueObserver(self, options:  [.onlyOnce, .initial]) { status in
                            switch status {
                            case .waiting:
                                return
                            case .parsed, .failed:
                                retrievedCount += 1
                                checkDone()
                            }
                        }
                    }
                }
            }

            test = parent
        }

        if pendingValuesCount == 0 {
            checkDone()
        }
    }

    public func report(_ error: Error, request: URLRequest?, response: HTTPURLResponse?, data: Data?, to resultCollection: ResultCollection) {
        resultCollection.fail(spec: self, withError: error, request: request, response: response, data: data)
    }
}

private extension TestSpec {
    func perform(onURL URL: URL, endpoint: String, inQueue queue: OperationQueue, reportingResultsTo resultCollection: ResultCollection, onComplete: @escaping () -> ()) {
         self.getAllHeaders { result in
            switch result {
            case .failed(failedKey: let key):
                let error = TestError(description: "Dependent parsed response value \(key) failed")
                self.report(error, request: nil, response: nil, data: nil, to: resultCollection)
                onComplete()
            case .success(let headers):
                self.perform(onURL: URL, endpoint: endpoint, headers: headers, inQueue: queue, reportingResultsTo: resultCollection, onComplete: onComplete)
            }
        }
    }

    func perform(onURL URL: URL, endpoint: String, headers: [String:String], inQueue queue: OperationQueue, reportingResultsTo resultCollection: ResultCollection, onComplete: @escaping () -> ()) {
        self.getAllQueryParameters { result in
            switch result {
            case .failed(failedKey: let key):
                let error = TestError(description: "Dependent parsed response value \(key) failed")
                self.report(error, request: nil, response: nil, data: nil, to: resultCollection)
                onComplete()
            case .success(let queryParameters):
                self.perform(onURL: URL, endpoint: endpoint, headers: headers, queryParameters: queryParameters, inQueue: queue, reportingResultsTo: resultCollection, onComplete: onComplete)
            }
        }
    }

    func perform(onURL URL: URL, endpoint: String, headers: [String:String], queryParameters: [String:String], inQueue queue: OperationQueue, reportingResultsTo resultCollection: ResultCollection, onComplete: @escaping () -> ()) {
        let URL = URL.appendingPathComponent(endpoint)
        var urlComponents = URLComponents(url: URL, resolvingAgainstBaseURL: true)!
        if !queryParameters.isEmpty {
            var queryItems = [URLQueryItem]()
            for (key, value) in queryParameters {
                queryItems.append(URLQueryItem(name: key, value: value))
            }
            urlComponents.queryItems = queryItems
        }
        var request = URLRequest(url: urlComponents.url!)
        request.httpBody = self.data
        request.httpMethod = self.method.rawValue
        request.allHTTPHeaderFields = headers
        let task = NetworkService.singleton.session.dataTask(with: request) { data, rawResponse, error in
            queue.addOperation {
                if let error = error {
                    self.report(error, request: request, response: rawResponse as? HTTPURLResponse, data: data, to: resultCollection)
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
        task.resume()
    }
}
