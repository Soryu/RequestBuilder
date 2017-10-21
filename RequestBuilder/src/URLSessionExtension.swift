import Foundation
import KhanlouPromise

public protocol URLSessionProtocol {
    
    func data(with request: URLRequest) -> Promise<(Data, HTTPURLResponse)>
    
}

extension URLSession: URLSessionProtocol {
    
    public func data(with request: URLRequest) -> Promise<(Data, HTTPURLResponse)> {
        return Promise<(Data, HTTPURLResponse)>(work: { fulfill, reject in
            self.dataTask(with: request, completionHandler: { data, response, error in
                if let error = error {
                    reject(error)
                } else if let data = data, let response = response as? HTTPURLResponse {
                    fulfill((data, response))
                } else {
                    fatalError("Something has gone horribly wrong.")
                }
            }).resume()
        })
    }
    
}

