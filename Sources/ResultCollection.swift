//
//  ResultCollection.swift
//  NetworkTestSuite
//
//  Created by Andrew J Wagner on 11/10/16.
//
//

public class ResultCollection: CustomStringConvertible {
    enum Result {
        case suite([String:Result])
        case specPassed
        case specFailed(Error)
    }

    var rootResult = Result.suite([:])

    func fail(spec: TestSpec, withError error: Error) {
        self.rootResult = self.rootResult.adding(result: .specFailed(error), atPath: spec.namePath)
    }

    func pass(spec: TestSpec) {
        self.rootResult = self.rootResult.adding(result: .specPassed, atPath: spec.namePath)
    }

    public var description: String {
        var output = ""

        output += self.rootResult.allDescription(atLevel: 0)

        output += "\n============================\n"

        if let fail = self.rootResult.failDescription(atLevel: 0) {
            output += fail
        }
        else {
            output += "All Tests Passed"
        }

        output += "\n"

        return output
    }
}

private extension ResultCollection.Result {
    func allDescription(atLevel level: Int) -> String {
        var output = ""
        for _ in 0 ..< level {
            output += "  "
        }
        switch self {
        case .specPassed:
            output += "PASS"
        case .specFailed(let error):
            output += "FAIL: "
            switch error {
            case let testError as TestError:
                output += testError.description
            default:
                output += error.localizedDescription
            }
        case .suite(let results):
            for name in results.keys.sorted() {
                output += "\n\(results[name]?.allDescription(atLevel: level + 1))"
            }
        }
        return output
    }

    func failDescription(atLevel level: Int) -> String? {
        var output = ""
        for _ in 0 ..< level {
            output += "  "
        }
        switch self {
        case .specPassed:
            return nil
        case .specFailed(let error):
            output += "FAIL: "
            switch error {
            case let testError as TestError:
                output += testError.description
            default:
                output += error.localizedDescription
            }
        case .suite(let results):
            for name in results.keys.sorted() {
                if let fail = results[name]?.failDescription(atLevel: level + 1) {
                    output += "\n\(fail)"
                }
            }
        }
        return output
    }

    func adding(result: ResultCollection.Result, atPath path: [String]) -> ResultCollection.Result {
        guard path.count > 0 else {
            return result
        }

        var remainingPath = path
        let last = remainingPath.removeLast()

        switch self {
        case .suite(var existing):
            existing[last] = self.adding(result: result, atPath: remainingPath)
            return .suite(existing)
        case .specFailed, .specPassed:
            fatalError("Duplicate name found")
        }
    }
}
