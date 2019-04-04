import Foundation
import Promise

public typealias DataResponsePromise = Promise<(data: Data, response: HTTPURLResponse)>

protocol NetworkClientSendProtocol {

    func send(requestBuilder: RequestBuilder) -> DataResponsePromise
    
}
