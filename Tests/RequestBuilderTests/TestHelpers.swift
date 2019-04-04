import Foundation

enum NetworkClientTestsError: Error {
    case fourohfour
}

func response(to request: URLRequest, data: Data? = nil) -> (Data?, HTTPURLResponse?, Error?)  {
    let response = HTTPURLResponse(url: request.url!,
                                   statusCode: 200,
                                   httpVersion: nil,
                                   headerFields: [:])
    return (data, response, nil)
}

func response(to request: URLRequest, error: Error, statusCode: Int?) -> (Data?, HTTPURLResponse?, Error?)  {
    guard let statusCode = statusCode else {
        return (nil, nil, error)
    }

    let response = HTTPURLResponse(url: request.url!,
                                   statusCode: statusCode,
                                   httpVersion: nil,
                                   headerFields: [:])
    return (nil, response, error)
}

