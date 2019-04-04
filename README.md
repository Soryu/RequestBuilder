# RequestBuilder

Originally inspired by http://khanlou.com/2017/01/request-behaviors/  
Depends on Soroush Khanlou’s lovely little Promise library, see https://github.com/khanlou/Promise


## Setup

This project uses swift package manager. You can generate an Xcode project on the command line by running

```
swift package generate-xcodeproj 
```


## Usage example

This simple example sends a GET request to https://github.com/foo?foo=bar with `Accept` and `Content-Type` headers for JSON, parses the response into a `MyObject` class, and lets you deal with the object or potential errors in a chainable fashion.

```swift
let client = NetworkClient(baseURL: URL(string: "https://github.com")!, defaultRequestBehavior: JSONRequestBehavior())

client.GET("/foo")
  .withQuery(["foo" : "bar"])
  .sendRequest()
  .then({ result in
      return try JSONDecoder().decode(MyObject.self, from: result.data)
  }).then({ object in
    // do something with object
  }).catch { error in
      print("error: \(error)")
  }
```
