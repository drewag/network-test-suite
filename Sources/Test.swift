//
//  Test.swift
//  NetworkTestSuite
//
//  Created by Andrew Wagner on 11/10/16.
//
//

import Foundation

public protocol Test: AnyObject {
    var name: String {get}
    var parent: Test? {get set}

    func perform(onURL URL: URL, reportingResultsTo resultCollection: ResultCollection, onComplete: @escaping () -> ())
}

extension Test {
    public func execute(onURL URL: URL) {
        let resultCollection = ResultCollection()
        let semaphore = DispatchSemaphore(value: 0)
        self.perform(onURL: URL, reportingResultsTo: resultCollection, onComplete: {
            semaphore.signal()
        })
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
