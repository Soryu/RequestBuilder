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
        
    // commented out, do not make live requests in tests. also that web service does not exist :p
    /*
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
                
                secrets.compactMap { secretDict -> String? in
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
 */
    
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
