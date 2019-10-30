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
    case created
    case accepted
    case nonAuthoritativeInformation
    case noContent
    case resetContent
    case partialContent

    // Redirection
    case multipleChoices = 300
    case movedPermanently
    case found
    case seeOther
    case notModified
    case useProxy
    case temporaryRedirect = 307

    // Client Error
    case badRequest = 400
    case unauthorized
    case paymentRequired
    case forbidden
    case notFound
    case methodNotAllowed
    case notAcceptable
    case proxyAuthenticationRequired
    case requestTimeout
    case conflict
    case gone
    case lengthRequired
    case preconditionFailed
    case requestEntityTooLarge
    case requestURITooLong
    case unsupportedMediaType
    case requestedRangeNotSatisfiable
    case expectationFailed

    // Server Error
    case internalServerError = 500
    case notImplemented
    case badGateway
    case serviceUnavailable
    case gatewayTimeout
    case httpVersionNotSupported
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
        case .nonAuthoritativeInformation:
            return "NON-AUTHORITATIVE INFORMATION"
        case .noContent:
            return "NO CONTENT"
        case .resetContent:
            return "RESET CONTENT"
        case .partialContent:
            return "PARTIAL CONTENT"

        case .multipleChoices:
            return "MULTIPLE CHOICES"
        case .movedPermanently:
            return "MOVED PERMANENTLY"
        case .found:
            return "FOUND"
        case .seeOther:
            return "SEE OTHER"
        case .notModified:
            return "NOT MODIFIED"
        case .useProxy:
            return "USE PROXY"
        case .temporaryRedirect:
            return "TEMPORARY REDIRECT"

        case .badRequest:
            return "BAD REQUEST"
        case .unauthorized:
            return "UNAUTHORIZED"
        case .paymentRequired:
            return "PAYMENT REQUIRED"
        case .forbidden:
            return "FORBIDDEN"
        case .notFound:
            return "NOT FOUND"
        case .methodNotAllowed:
            return "METHOD NOT ALLOWED"
        case .notAcceptable:
            return "NOT ACCEPTABLE"
        case .proxyAuthenticationRequired:
            return "PROXY AUTHENTICATION REQUIRED"
        case .requestTimeout:
            return "REQUEST TIMEOUT"
        case .conflict:
            return "CONFLICT"
        case .gone:
            return "GONE"
        case .lengthRequired:
            return "LENGTH REQUIRED"
        case .preconditionFailed:
            return "PRECONDITION FAILED"
        case .requestEntityTooLarge:
            return "REQUEST ENTITY TOO LARGE"
        case .requestURITooLong:
            return "REQUEST URI TOO LONG"
        case .unsupportedMediaType:
            return "UNSUPPORTED MEDIA TYPE"
        case .requestedRangeNotSatisfiable:
            return "REQUESTED RANGE NOT SATISFIABLE"
        case .expectationFailed:
            return "EXPECTATION FAILED"

        case .internalServerError:
            return "INTERNAL ERROR"
        case .notImplemented:
            return "NOT IMPLEMENTED"
        case .badGateway:
            return "BAD GATEWAY"
        case .serviceUnavailable:
            return "SERVICE UNAVAILABLE"
        case .gatewayTimeout:
            return "GATEWAY TIMEOUT"
        case .httpVersionNotSupported:
            return "HTTP VERSION NOT SUPPORTED"
        }
    }
}
