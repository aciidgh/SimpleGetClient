# SimpleGetClient

[![Build Status](https://travis-ci.org/aciidb0mb3r/SimpleGetClient.svg?branch=master)](https://travis-ci.org/aciidb0mb3r/SimpleGetClient)

A super simple GET client in swift to try out Swift Package Manager.

* Create client
```swift
let client = GetClient()
```

* Fetch an URL
```swift
let result = client.fetch("http://httpbin.org/get?a=b")
```

result is a tuple `(responseCode: String, headers: [String : String], response: String)`


More : 

http://ankit.im/swift/2016/02/17/swift-package-manager-testing-preview/

http://ankit.im/swift/2015/12/06/developing-and-debugging-swift-packages-using-swift-package-manager/
