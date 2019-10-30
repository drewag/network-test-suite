//
//  NetworkService.swift
//  IntegrationTestSuite
//
//  Created by Andrew J Wagner on 4/19/17.
//
//

import Foundation

class NetworkService: NSObject {
    static let singleton = NetworkService()

    var session: Foundation.URLSession!

    override init() {
        super.init()

        let config = URLSessionConfiguration.default
        self.session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }
}

extension NetworkService: URLSessionDelegate {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        let serverTrust = challenge.protectionSpace.serverTrust
        let credential = URLCredential(trust: serverTrust!)
        completionHandler(.useCredential, credential)
    }
}
