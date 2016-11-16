//
//  ParsedResponseCoordinator.swift
//  IntegrationTestSuite
//
//  Created by Andrew J Wagner on 11/11/16.
//
//

import SwiftPlusPlus

public enum ParsedResponseValueStatus {
    case waiting
    case failed
    case parsed(Any)
}

public class ParsedResponseValue: HeaderValue {
    let translate: ((Any) -> String)?

    var status = Observable(ParsedResponseValueStatus.waiting)

    public func string() throws -> String {
        switch self.status.value {
        case .failed:
            throw LocalUserReportableError(source: "ParsedResponseCoordinator", operation: "retrieving value", message: "Parsing of value failed", reason: .internal)
        case .waiting:
            throw LocalUserReportableError(source: "ParsedResponseCoordinator", operation: "retrieving value", message: "Parsing of value has not occured yet", reason: .internal)
        case .parsed(let object):
            if let translate = self.translate {
                return translate(object)
            }
            return "\(object)"
        }
    }

    init(translate: ((Any) -> String)? = nil) {
        self.translate = translate
    }
}

public func ParsedResponse<Value: ParsableResponse>(for key: ParsedResponseKey<Value>.Type, translate: ((Any) -> String)? = nil) -> ParsedResponseValue {
    return ParsedResponseCoordinator.singleton.value(for: key, translate: translate)
}

public class ParsedResponseCoordinator {
    static public let singleton = ParsedResponseCoordinator()

    fileprivate var values = [String:Any]()

    private init() {}

    public func parse<Value: ParsableResponse>(responseObject object: Any, for key: ParsedResponseKey<Value>.Type) throws {
        let parsedResponse = self.parsedResponse(for: key)
        guard let value = object as? Value else {
            parsedResponse.status.value = .failed
            throw TestError(description: "Mismatched type for \(key.rawKey)")
        }

        parsedResponse.status.value = .parsed(value)
    }

    func value<Value: ParsableResponse>(for key: ParsedResponseKey<Value>.Type, translate: ((Any) -> String)? = nil) -> ParsedResponseValue {
        return self.parsedResponse(for: key, translate: translate)
    }
}

private extension ParsedResponseCoordinator {
    func parsedResponse<Value: ParsableResponse>(for key: ParsedResponseKey<Value>.Type, translate: ((Any) -> String)? = nil) -> ParsedResponseValue {
        if let parsedResponse = self.values[key.rawKey] as? ParsedResponseValue {
            return parsedResponse
        }

        let newResponse = ParsedResponseValue(translate: translate)
        newResponse.status.value = .waiting
        self.values[key.rawKey] = newResponse
        return newResponse
    }
}
