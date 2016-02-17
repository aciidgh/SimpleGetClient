@testable import SimpleGetClient
import XCTest
import Foundation

class SimpleGetTests: XCTestCase {

    let client = GetClient()

#if os(Linux)
    func testGetRequestWithOneArg() {
        let result = client.fetch("http://httpbin.org/get?a=b")
        guard case let json as Dictionary<String, Any> = try? NSJSONSerialization.JSONObjectWithData(NSString(string: result.response).dataUsingEncoding(NSUTF8StringEncoding)!, options: NSJSONReadingOptions.AllowFragments) else {
            XCTFail("Couldn't parse data")
            return
        }
        guard case let args as Dictionary<String, Any> = json["args"],
                  case let argA as String = args["a"]  else {
            XCTFail("Couldn't parse data")
            return
        } 
        
        XCTAssertEqual(argA, "b", "Incorrect value received from server")
    }
#else 
func testGetRequestWithOneArg() {   
    let result = client.fetch("http://httpbin.org/get?a=b")
    guard case let json as NSDictionary = try? NSJSONSerialization.JSONObjectWithData((result.response as NSString).dataUsingEncoding(NSUTF8StringEncoding)!, options: NSJSONReadingOptions.AllowFragments) else {
        XCTFail("Couldn't parse data")
        return
    }
    
    XCTAssertEqual(json["args"]?["a"], "b", "Incorrect value received from server")
}
#endif
    
    func testGetRequestStatusCode() {
        let result = client.fetch("http://httpbin.org/status/419")
        XCTAssertEqual(result.responseCode, "419", "Incorrect value received from server")
    }
}

#if os(Linux)
extension SimpleGetTests: XCTestCaseProvider {
    var allTests : [(String, () throws -> Void)] {
        return [
            ("testGetRequestWithOneArg", testGetRequestWithOneArg),
            ("testGetRequestStatusCode", testGetRequestStatusCode),
        ]
    }
}
#endif