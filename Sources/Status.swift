//
//  Status.swift
//  NetworkTestSuite
//
//  Created by Andrew J Wagner on 11/10/16.
//
//

public enum Status: Int {
    // Successful
    case ok = 200
    case created = 201
    case accepted = 202
    case noContent = 204

    // Client Error
    case badRequest = 400
    case unauthorized = 401
    case forbidden = 403
    case notFound = 404
    case conflict = 409

    // Server Error
    case internalServerError = 500
    case notImplemented = 501
}

extension Status: CustomStringConvertible {
    public var description: String {
        switch self {
        case .ok:
            return "OK"
        case .created:
            return "CREATED"
        case .accepted:
            return "ACCEPTED"
        case .noContent:
            return "NO CONTENT"
        case .conflict:
            return "CONFLICT"

        case .badRequest:
            return "BAD REQUEST"
        case .unauthorized:
            return "UNAUTHORIZED"
        case .forbidden:
            return "FORBIDDEN"
        case .notFound:
            return "NOT FOUND"
        case .internalServerError:
            return "INTERNAL ERROR"
        case .notImplemented:
            return "NOT IMPLEMENTED"
        }
    }
}
