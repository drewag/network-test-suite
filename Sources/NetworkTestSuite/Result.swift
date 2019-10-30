//
//  Result.swift
//  IntegrationTestSuite
//
//  Created by Andrew J Wagner on 11/11/16.
//
//

import Foundation

protocol Result: AnyObject {
    var level: Int {get}
    var allDescription: String {get}
    var failDescription: String? {get}

    func addResult(status: SpecResult.Status, atPath path: [String], atLevel level: Int) -> SpecResult
}

class SuiteResult: Result {
    let level: Int

    init(level: Int) {
        self.level = level
    }

    var results = [String:Result]()

    var allDescription: String {
        var output = ""

        for name in self.results.keys.sorted() {
            for _ in 0 ..< level {
                output += "  "
            }
            output += "\(name)\n"

            let result = self.results[name]!
            output += result.allDescription
        }

        return output
    }

    var failDescription: String? {
        var output = ""

        var foundError = false
        for name in self.results.keys.sorted() {
            let result = self.results[name]!
            if let fail = result.failDescription {
                for _ in 0 ..< level {
                    output += "  "
                }
                output += "\(name)\n"
                output += fail
                foundError = true
            }
        }

        if !foundError {
            return nil
        }

        return output
    }

    func addResult(status: SpecResult.Status, atPath path: [String], atLevel level: Int) -> SpecResult {
        guard path.count > 1 else {
            if self.results[path.first!] != nil {
                fatalError("Result already exists")
            }
            let newResult = SpecResult(level: level + 1, status: status)
            self.results[path.first!] = newResult
            return newResult
        }

        let pathPart = path.first!

        var nextSuite: Result! = self.results[pathPart]
        if nextSuite == nil {
            nextSuite = SuiteResult(level: level + 1)
            self.results[pathPart] = nextSuite
        }
        var remaining = path
        remaining.removeFirst()
        return nextSuite.addResult(status: status, atPath: remaining, atLevel: level + 1)
    }
}

class SpecResult: Result {
    enum Status {
        case passed
        case failed(Error, URLRequest?, HTTPURLResponse?, Data?)
    }

    let status: Status

    let level: Int

    init(level: Int, status: Status) {
        self.level = level
        self.status = status
    }

    func realTimeDescription(at path: [String]) -> String {
        var output = ""

        for part in path {
            output += part
            output += " > "
        }

        switch self.status {
        case .failed(let error, _, _, _):
            output += "FAIL: "
            switch error {
            case let testError as TestError:
                output += testError.description
            default:
                output += error.localizedDescription
            }
        case .passed:
            output += "PASS"
        }

        return output
    }

    var allDescription: String {
        var output = ""
        for _ in 0 ..< level {
            output += "  "
        }

        switch self.status {
        case .failed(let error, _, _, _):
            output += "\u{001B}[0;31mFAIL: "
            switch error {
            case let testError as TestError:
                output += testError.description
            default:
                output += error.localizedDescription
            }
            output += "\u{001B}[m\n"
        case .passed:
            output += "PASS\n"
        }

        return output
    }

    var failDescription: String? {
        var output = ""

        switch self.status {
        case let .failed(_, request, response, data):
            output += self.allDescription
            if let request = request {
                output += "\n>>>>>>>>>>>>>>>>>>>>>>>>>\n"
                output += request.failDescription
            }
            if let response = response {
                output += "\n<<<<<<<<<<<<<<<<<<<<<<<<<\n"
                output += response.failDescription
                if let data = data {
                    if let jsonObject = try? JSONSerialization.jsonObject(with: data, options: .allowFragments)
                        , let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)
                        , let string = String(data: prettyData, encoding: .utf8)

                    {
                        output += string
                    }
                    else if let string = String(data: data, encoding: .utf8) {
                        output += string
                    }
                    else {
                        output += "BINARY DATA"
                    }
            }
            }
            output += "\n--------------------------\n"
        case .passed:
            return nil
        }

        return output
    }

    func addResult(status: SpecResult.Status, atPath path: [String], atLevel level: Int) -> SpecResult {
        fatalError("Spec exists at the same path as a suite")
    }
}

extension URLRequest {
    var failDescription: String {
        var output = ""

        if let method = self.httpMethod {
            output += "\(method) "
        }
        if let url = self.url {
            output += "\(url.absoluteString)\n"
        }
        else {
            output += "\n"
        }

        if let data = self.httpBody {
            if let string = String(data: data, encoding: .utf8) {
                output += "\(string)"
            }
            else {
                output += "BINARY DATA"
            }
        }

        return output
    }
}

extension HTTPURLResponse {
    var failDescription: String {
        var output = ""

        output += "\(self.statusCode)"
        if let description = Status(rawValue: self.statusCode)?.description {
            output += " \(description)"
        }
        output += "\n"

        return output
    }
}
