@testable import RequestBuilder
import KhanlouPromise

struct MockURLSessionError: Error {}

struct MockURLSession {
    
    let data: Data?
    let response: HTTPURLResponse?
    let error: Error?
    
}

extension MockURLSession: URLSessionProtocol {
    
    func data(with request: URLRequest) -> Promise<(Data, HTTPURLResponse)> {
        
        if let error = error {
            return Promise<(Data, HTTPURLResponse)>(error: error)
        }
        
        if let data = data, let response = response {
            return Promise<(Data, HTTPURLResponse)>(value: (data, response))
        }
        
        return Promise<(Data, HTTPURLResponse)>(error: MockURLSessionError())
    }
}

struct VerifyingURLSession: URLSessionProtocol {
    
    typealias Verification = ((URLRequest) -> (Data?, HTTPURLResponse?, Error?))
    let verificationBlock: Verification
    
    init( _ block: @escaping Verification) {
        verificationBlock = block
    }
    
    func data(with request: URLRequest) -> Promise<(Data, HTTPURLResponse)> {
        let (data, response, error) = verificationBlock(request)
        
        if let error = error {
            return Promise<(Data, HTTPURLResponse)>(error: error)
        }
        
        if let data = data, let response = response {
            return Promise<(Data, HTTPURLResponse)>(value: (data, response))
        }
        
        return Promise<(Data, HTTPURLResponse)>(error: MockURLSessionError())

    }
}

class VerifyingBehavior: RequestBehavior {
    var calledBeforeSend   = false
    var calledAfterSuccess = false
    var calledAfterFailure = false
    
    func beforeSend(request: URLRequest) {
        calledBeforeSend = true
    }
    func afterSuccess(request: URLRequest, response: HTTPURLResponse, result: Any?) {
        calledAfterSuccess = true
    }
    
    func afterFailure(request: URLRequest, response: HTTPURLResponse?, error: Error) {
        calledAfterFailure = true
    }
}

