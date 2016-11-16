//
//  Response.swift
//  NetworkTestSuite
//
//  Created by Andrew Wagner on 11/10/16.
//
//

import Foundation

public struct Response {
    enum JSONPath {
        case key(String)
        case index(Int)
    }

    let coordinator = ParsedResponseCoordinator.singleton
    let rawResponse: HTTPURLResponse
    let data: Data?
    let jsonPath: [JSONPath]

    var path: String {
        var path = ""
        for element in self.jsonPath {
            if !path.isEmpty {
                path += "."
            }

            switch element {
            case .index(let index):
                path += "\(index)"
            case .key(let key):
                path += key
            }
        }
        return path
    }

    init(rawResponse: HTTPURLResponse, data: Data?, jsonPath: [JSONPath] = []) {
        self.rawResponse = rawResponse
        self.data = data
        self.jsonPath = jsonPath
    }

    public func expect(status: Status) throws {
        guard status.rawValue == rawResponse.statusCode else {
            throw TestError(description: "Expected status to be \(status.rawValue) but got \(rawResponse.statusCode)")
        }
    }

    public subscript(key: String) -> Response {
        return Response(rawResponse: self.rawResponse, data: data, jsonPath: self.jsonPath + [.key(key)])
    }

    public subscript(index: Int) -> Response {
        return Response(rawResponse: self.rawResponse, data: data, jsonPath: self.jsonPath + [.index(index)])
    }

    public func expect(_ string: String) throws {
        guard let actual = try self.objectForJSONPath() as? String else {
            throw TestError(description: "Expected string at \(self.path)")
        }

        guard string == actual else {
            throw TestError(description: "Expected '\(actual)' to be \(string)")
        }
    }

    public func expect(_ int: Int) throws {
        guard let actual = try self.objectForJSONPath() as? Int else {
            throw TestError(description: "Expected int at \(self.path)")
        }

        guard int == actual else {
            throw TestError(description: "Expected '\(actual)' to be \(int)")
        }    }

    public func expect(_ double: Double) throws {
        guard let actual = try self.objectForJSONPath() as? Double else {
            throw TestError(description: "Expected double at \(self.path)")
        }

        guard double == actual else {
            throw TestError(description: "Expected \(actual) to be \(double)")
        }
    }

    public func expect(_ bool: Bool) throws {
        guard let actual = try self.objectForJSONPath() as? Bool else {
            throw TestError(description: "Expected bool at \(self.path)")
        }

        guard bool == actual else {
            throw TestError(description: "Expected \(actual) to be \(bool)")
        }
    }

    public func expectExists() throws {
        let _ = try self.objectForJSONPath()
    }

    public func parse<Value: ParsableResponse>(for key: ParsedResponseKey<Value>.Type) throws {
        try self.coordinator.parse(responseObject: try self.objectForJSONPath(), for: key)
    }

    public func expect(arrayCount count: Int) throws {
        switch try self.objectForJSONPath() {
        case let actual as [Any]:
            guard actual.count == count else {
                throw TestError(description: "Expected array count \(actual.count) to be \(count)")
            }
        case let actual as String where actual == "[]":
            break
        default:
            throw TestError(description: "Expected array at \(self.path)")

        }
    }
}

private extension Response {
    func objectForJSONPath() throws -> Any {
        guard let data = self.data else {
            throw TestError(description: "No data returned with response")
        }

        guard !self.jsonPath.isEmpty else {
            guard let string = String(data: data, encoding: .utf8) else {
                throw TestError(description: "Invalid string response")
            }
            return string
        }

        var object: Any!
        do {
            object = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions())
        }
        catch {
            throw TestError(description: "Invalid JSON response")
        }

        var path = ""
        for element in self.jsonPath {
            if !path.isEmpty {
                path += "."
            }

            switch element {
            case .index(let index):
                path += "\(index)"
                guard let array = object as? [Any] else {
                    throw TestError(description: "Expected array at \(path)")
                }
                guard index < array.count else {
                    throw TestError(description: "Index is out of bounds at \(path)")
                }
                object = array[index]
            case .key(let key):
                path += key
                guard let dict = object as? [String:Any] else {
                    throw TestError(description: "Expected dictionary at \(path)")
                }
                guard let dictObject = dict[key] else {
                    throw TestError(description: "Expected object at \(path) but it does not exist")
                }
                object = dictObject
            }
        }
        return object
    }
}
