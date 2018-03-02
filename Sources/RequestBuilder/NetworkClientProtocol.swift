import Foundation
import Dispatch
import Promise

public protocol NetworkClientProtocol {
    
    var baseURL: URL { get }
    var dispatchQueue: DispatchQueue { get }
    
    init(baseURL: URL, session: URLSessionProtocol, defaultRequestBehavior: RequestBehavior?, dispatchQueue: DispatchQueue)
    
    func send(requestBuilder: RequestBuilder) -> Promise<(Data, HTTPURLResponse)>
    func parseJSONReponse(_ response: HTTPURLResponse, data: Data) throws -> Promise<JSONType>
    func JSONData(for dict: Dictionary<String, Any>) throws -> Data?
    
}
