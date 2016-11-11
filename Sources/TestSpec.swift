//
//  TestSpec.swift
//  NetworkTestSuite
//
//  Created by Andrew J Wagner on 11/10/16.
//
//

import Foundation

public class TestSpec: Test {
    public let name: String
    let endpoint: String
    let method: Method
    let data: Data?
    let test: (Response) throws -> ()

    public var parent: Test?

    public init(
        name: String,
        endpoint: String,
        method: Method,
        data: Data?,
        test: @escaping (Response) throws -> ()
        )
    {
        self.name = name
        self.endpoint = endpoint
        self.method = method
        self.data = data
        self.test = test
    }

    public func perform(onURL URL: URL, reportingResultsTo resultCollection: ResultCollection, onComplete: @escaping () -> ()) {
        let URL = URL.appendingPathComponent(self.endpoint)
        var request = URLRequest(url: URL)
        request.httpBody = self.data

        let task = URLSession.shared.dataTask(with: URL) { data, rawResponse, error in
            DispatchQueue.main.async {
                if let error = error {
                    resultCollection.fail(spec: self, withError: error)
                    onComplete()
                    return
                }

                let response = Response(rawResponse: rawResponse as! HTTPURLResponse, data: data)
                do {
                    try self.test(response)
                    resultCollection.pass(spec: self)
                }
                catch let error {
                    resultCollection.fail(spec: self, withError: error)
                }

                onComplete()
            }
        }
        task.resume()
    }
}
