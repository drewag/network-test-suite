//
//  Test.swift
//  NetworkTestSuite
//
//  Created by Andrew Wagner on 11/10/16.
//
//

import Foundation

public protocol Test: AnyObject, CustomStringConvertible {
    var name: String {get}
    var parent: Test? {get set}
    var queryParameters: [String:Any] {get}
    var headers: [String:Any] {get}

    func perform(onURL URL: URL, inQueue queue: OperationQueue, reportingResultsTo resultCollection: ResultCollection, onComplete: @escaping () -> ())
}

extension Test {
    public func execute(onURL URL: URL) {
        let resultCollection = ResultCollection()
        let queue = OperationQueue()
        let semaphore = DispatchSemaphore(value: 0)
        queue.addOperation {
            self.perform(onURL: URL, inQueue: queue, reportingResultsTo: resultCollection, onComplete: {
                semaphore.signal()
            })
        }
        semaphore.wait()
        print(resultCollection)
    }

    var namePath: [String] {
        var path = [self.name]

        var test: Test = self
        while let parent = test.parent {
            path.insert(parent.name, at: 0)
            test = parent
        }

        return path
    }
}
