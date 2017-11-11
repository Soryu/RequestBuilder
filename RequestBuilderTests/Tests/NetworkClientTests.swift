import XCTest
import RequestBuilder

class NetworkClientTests: XCTestCase {
    
    let testURL = URL(string: "https://api.soryu2.net")!
    
    func testSimple() {
        let exp = expectation(description: "")

        let session = VerifyingURLSession() { request in
            XCTAssert(request.allHTTPHeaderFields?.count == 0)
            return response(to: request, data: Data())
        }
        
        let client = NetworkClient(baseURL: testURL, session: session)
        
        client.GET("/foo").sendRequest()
            .then({ data, response in
                XCTAssert(data.count == 0)
                XCTAssert(response.statusCode == 200)
                exp.fulfill()
            })

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testSimpleInsideOut() {
        let exp = expectation(description: "")
        
        let baseURL = testURL
        
        let session = VerifyingURLSession() { request in
            XCTAssert(request.allHTTPHeaderFields?.count == 0)
            XCTAssert(request.url == URL(string: "https://api.soryu2.net/foo"))
            return response(to: request, data: Data())
        }
        
        let client = NetworkClient(baseURL: baseURL, session: session)
        let rb = RequestBuilder.GET("/foo", baseURL: baseURL)
        
        client.send(requestBuilder: rb)
            .then({ data, response in
                XCTAssert(data.count == 0)
                XCTAssert(response.statusCode == 200)
                exp.fulfill()
            })
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testJSONManual() {
        let exp = expectation(description: "")

        let expected = ["foo": "bar", "baz": "blubb"]
        
        let mockSession = VerifyingURLSession() { request in
            
            XCTAssert(request.allHTTPHeaderFields!.first!.key == "Content-Type")
            XCTAssert(request.allHTTPHeaderFields!.first!.value == "application/json")
            
            return jsonResponse(to: request, dict: expected)
        }
        
        let client = NetworkClient(baseURL: testURL, session: mockSession)

        client.GET("/foo")
            .withQuery(["foo" : "bar"])
            .withBehavior(JSONRequestBehavior())
            .sendRequest()
            .then({ data, response in
                return try client.parseJSONReponse(response, data: data)
            }).then({ json in
                guard let json = json as? Dictionary<String, String> else {
                    XCTFail()
                    throw NetworkClientError.InvalidJSON
                }
                XCTAssert(json == expected)
                exp.fulfill()
            }).catch { error in
                print("error: \(error)")
                exp.fulfill()
            }
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testJSONConvenience() {
        let exp = expectation(description: "")
        
        let expected = ["foo": "bar", "baz": "blubb"]
        
        let mockSession = VerifyingURLSession() { request in
            
            XCTAssert(request.allHTTPHeaderFields!.first!.key == "Content-Type")
            XCTAssert(request.allHTTPHeaderFields!.first!.value == "application/json")
            
            return jsonResponse(to: request, dict: expected)
        }
        
        let client = NetworkClient(baseURL: testURL, session: mockSession)
        
        client.GET("/foo")
            .withQuery(["foo" : "bar"])
            .sendJSONRequest()
            .then({ json in
                guard let json = json as? Dictionary<String, String> else {
                    XCTFail()
                    throw NetworkClientError.InvalidJSON
                }
                XCTAssert(json == expected)
                exp.fulfill()
            }).catch { error in
                print("error: \(error)")
                exp.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    // commented out, do not make live requests in tests. also that web service does not exist :p
    func _testLiveRequestChainWithLogin() {
        let exp = expectation(description: "")
        
        let client = NetworkClient(baseURL: testURL,
                                   session: URLSession(configuration: URLSessionConfiguration.ephemeral))
        
        let jsonIn = ["email": "requestbuilder@soryu2.net", "password": "secret"]
        
        client.POST("login")
            .sendJSONRequest(json: jsonIn)
            .then({ jsonOut -> String in
                guard
                    let dict = jsonOut as? Dictionary<String, Any?>,
                    let token = dict["token"] as? String
                else {
                    throw NetworkClientError.MalformedRequest
                }
                
                return token
            })
            .then({ token in
                return client
                    .GET("secrets")
                    .withBehavior(AuthenticatingRequestBehavior(headerName: "Access-Token", value: token))
                    .sendJSONRequest()
            })
            .then({ secretsJSON in
                guard let secrets = secretsJSON as? Array<Dictionary<String, Any>> else { throw NetworkClientError.InvalidJSON }
                
                print("secrets: \(secrets.count)")
                
                secrets.flatMap { secretDict -> String? in
                    return secretDict["title"] as? String
                }.forEach { title in
                    print("secret: \(title)")
                }
                
                exp.fulfill()
            }).catch { error in
                XCTFail(error.localizedDescription)
                exp.fulfill()
        }
        waitForExpectations(timeout: 8)
    }
    
    func testBehaviorsBeingCalledSuccess() {
        let exp1 = expectation(description: "async")

        let session = MockURLSession(data: Data(),
                                     response: HTTPURLResponse(url: testURL,
                                                               statusCode: 200, httpVersion: "1.1",
                                                               headerFields: nil),
                                     error: nil)
        
        let client = NetworkClient(baseURL: testURL, session: session)

        let verifyingBehavior = VerifyingBehavior()
        
        client.GET("/")
            .withBehavior(verifyingBehavior)
            .sendRequest()
            .always {
                exp1.fulfill()
        }
        
        waitForExpectations(timeout: 1)
        
        XCTAssertTrue(verifyingBehavior.calledBeforeSend)
        XCTAssertTrue(verifyingBehavior.calledAfterSuccess)
        XCTAssertFalse(verifyingBehavior.calledAfterFailure)
    }

    func testBehaviorsBeingCalledFailure() {
        let exp1 = expectation(description: "async")
        
        let session = MockURLSession(data: nil, response: nil, error: NSError(domain: "", code: 1, userInfo: nil))
        let client = NetworkClient(baseURL: testURL, session: session)
        let verifyingBehavior = VerifyingBehavior()
        
        
        client.GET("/")
            .withBehavior(verifyingBehavior)
            .sendRequest()
            .always {
                exp1.fulfill()
        }
        
        waitForExpectations(timeout: 1)
        
        XCTAssertTrue(verifyingBehavior.calledBeforeSend)
        XCTAssertFalse(verifyingBehavior.calledAfterSuccess)
        XCTAssertTrue(verifyingBehavior.calledAfterFailure)
    }
    
    func testErrorHandling() {
        let exp1 = expectation(description: "async")
        
        let response = HTTPURLResponse(url: testURL, statusCode: 404, httpVersion: "1.1", headerFields: nil)
        let session = MockURLSession(data: Data(), response: response, error: nil)
        
        var caughtError: Error?
        
        NetworkClient(baseURL: testURL, session: session)
            .GET("/")
            .withBehavior(ErrorHandlingRequestBehavior({ _, response, _ in
                if response.statusCode == 404 {
                    throw NetworkClientTestsError.fourohfour
                }
            }))
            .sendRequest()
            .catch({ (error) in
                caughtError = error
            })
            .always {
                exp1.fulfill()
        }

        waitForExpectations(timeout: 1)
        
        if
            let error = caughtError as? NetworkClientTestsError,
            case NetworkClientTestsError.fourohfour = error {
            XCTAssert(true)
        } else {
            XCTFail()
        }
    }

}

enum NetworkClientTestsError: Error {
    case fourohfour
}

fileprivate func response(to request: URLRequest, data: Data? = nil) -> (Data?, HTTPURLResponse?, Error?)  {
    let response = HTTPURLResponse(url: request.url!,
                                   statusCode: 200,
                                   httpVersion: nil,
                                   headerFields: [:])
    return (data, response, nil)
}

fileprivate func jsonResponse(to request: URLRequest, dict: Dictionary<String, Any?>) -> (Data?, HTTPURLResponse?, Error?)  {
    guard let data = try? JSONSerialization.data(withJSONObject: dict, options: []) else { fatalError() }
    return response(to: request, data: data)
}

fileprivate func response(to request: URLRequest, error: Error, statusCode: Int?) -> (Data?, HTTPURLResponse?, Error?)  {
    guard let statusCode = statusCode else {
        return (nil, nil, error)
    }
    
    let response = HTTPURLResponse(url: request.url!,
                                   statusCode: statusCode,
                                   httpVersion: nil,
                                   headerFields: [:])
    return (nil, response, error)
}

