import Foundation

// behaviors are for
// * content type (header)
// * auth token (header)
// * user agent (header)
// * logging

// NOT for:
// * JSON parsing (cannot change result of response)
// * Error transformation (same)

public protocol RequestBehavior {
    
    var additionalHeaders: [String: String] { get }
    
    func beforeSend(request: URLRequest)
    
    func afterSuccess(request: URLRequest, response: HTTPURLResponse, result: Any?)
    
    func afterFailure(request: URLRequest, response: HTTPURLResponse?, error: Error)
    
}

public extension RequestBehavior {
    
    var additionalHeaders: [String: String] {
        return [:]
    }
    
    func beforeSend(request: URLRequest) {}
    func afterSuccess(request: URLRequest, response: HTTPURLResponse, result: Any?) {}
    func afterFailure(request: URLRequest, response: HTTPURLResponse?, error: Error) {}
    
}

public struct EmptyRequestBehavior: RequestBehavior { }

public struct CombinedRequestBehavior: RequestBehavior {
    
    var behaviors = [RequestBehavior]()

    public init(behaviors: [RequestBehavior]) {
        self.behaviors = behaviors
    }

    public init(behavior: RequestBehavior? = nil) {
        if let behavior = behavior {
            self.behaviors = [ behavior ]
        }
    }
    
    public mutating func addBehaviour(_ newBehaviour: RequestBehavior) {
        behaviors.append(newBehaviour)
    }
    
    public var additionalHeaders: [String : String] {
        return behaviors.reduce([String: String](), { sum, behavior in
            // return sum.merged(with: behavior.additionalHeaders)
            var newSum = sum
            behavior.additionalHeaders.forEach { k, v in
                newSum[k] = v
            }
            return newSum
        })
    }
    
    public func beforeSend(request: URLRequest) {
        behaviors.forEach({ $0.beforeSend(request: request) })
    }
    
    public func afterSuccess(request: URLRequest, response: HTTPURLResponse, result: Any?) {
        behaviors.forEach({ $0.afterSuccess(request: request, response: response, result: result) })
    }
    
    public func afterFailure(request: URLRequest, response: HTTPURLResponse?, error: Error) {
        behaviors.forEach({ $0.afterFailure(request: request, response: response, error: error) })
    }
}

public struct AuthenticatingRequestBehavior: RequestBehavior {
    
    let headerName: String
    let value: String
    
    public init(headerName: String, value: String) {
        self.headerName = headerName
        self.value = value
    }
    
    public var additionalHeaders: [String : String] {
        return [headerName: value]
    }
    
}

public struct JSONRequestBehavior: RequestBehavior {
    
    public var additionalHeaders: [String : String] {
        return ["Content-Type": "application/json"]
    }
    
    public init() {}
}

