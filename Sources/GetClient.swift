import Foundation

#if os(Linux)
import Glibc
#else
import Darwin
#endif

class URL: CustomStringConvertible {
    let host: String
    let port: UInt16 = 80
    let query: String
    
    init(string: String) {
        let explodedStrings = string.characters.split("/", maxSplit: 2, allowEmptySlices: false).map(String.init)
        
        if string.hasPrefix("http://") {
            host = explodedStrings[1]
            query = explodedStrings.count > 2 ? "/" + explodedStrings[2] : ""
        } else {
            host = explodedStrings[0]
            query = explodedStrings.count > 1 ? "/" + explodedStrings[1] : ""
        }
    }
    
    internal var description: String {
        return "host: \(host) Query: \(query) Port: \(port)"
    }
}

public class GetClient {

	let bufferSize = 10240
	var sock: Int32

	public init() {
		#if os(Linux)
		sock = socket(AF_INET, Int32(SOCK_STREAM.rawValue), 0)
		#else
		sock = socket(AF_INET, Int32(SOCK_STREAM), 0)
		#endif
	}

	public func fetch(urlString: String) -> (responseCode: String, headers: [String : String], response: String) {
		let url = URL(string: urlString)

		let ipAddress = self.getIPFromHost(url.host)

		//Connect
		var remote = sockaddr_in()
		remote.sin_family = sa_family_t(AF_INET);
		inet_pton(AF_INET, ipAddress, &remote.sin_addr.s_addr)
		remote.sin_port = htons(url.port)
		connect(sock, sockaddr_cast(&remote) , socklen_t(sizeof(sockaddr)))

		//Build query
		let getRequest = "GET \(url.query) HTTP/1.1\r\nHost: \(url.host)\r\n\r\n";

		//Send request
		getRequest.withCString { (bytes) in
			send(sock, bytes, Int(strlen(bytes)), 0)
		}

		//Receive Data
		var buf = [CChar](count:Int(bufferSize), repeatedValue: 0)
		recv(sock, &buf, bufferSize, 0)
		
    let response = String.fromCString(buf)!
    let exploded = response.componentsSeparatedByString("\r\n\r\n")
    
    let headers = exploded[0].componentsSeparatedByString("\r\n")
    
    let responseCode = headers[0].componentsSeparatedByString(" ")[1]
    
    var headersDictionary = [String : String]()
    for header in headers.dropFirst() {
      let headerExploded = header.componentsSeparatedByString(": ")
      headersDictionary[headerExploded[0]] = headerExploded[1]
    }
      
    return (responseCode, headersDictionary, exploded.count > 1 ? exploded[1] : "")
	}

	private func getIPFromHost(hostName: String) -> String {
		let host = gethostbyname(hostName) 
		var ipAddressString = [CChar](count:Int(INET_ADDRSTRLEN), repeatedValue: 0)
		inet_ntop(AF_INET, host.memory.h_addr_list[0], &ipAddressString, socklen_t(INET_ADDRSTRLEN))
		return String.fromCString(ipAddressString)!
	}

	private func sockaddr_cast(p: UnsafeMutablePointer<Void>) -> UnsafeMutablePointer<sockaddr> {
		return UnsafeMutablePointer<sockaddr>(p)
	}

	private func htons(value: UInt16) -> UInt16 {
		return (value << 8) + (value >> 8);
	}
}

///Shamelessly copied from https://github.com/erica/SwiftString/blob/master/Sources/String.swift
public extension String {

    /// Range of first match to string
    ///
    /// Performance note: "not very". This is a stop-gap for light
    /// use and not a fast solution
    ///
    public func rangeOfString(searchString: String) -> Range<Index>? {

        // If equality, return full range
        if searchString == self { return startIndex..<endIndex }

        // Basic sanity checks
        let (count, stringCount) = (characters.count, searchString.characters.count)
        guard !isEmpty && !searchString.isEmpty && stringCount < count else { return nil }

        // Moving search offset. Thanks Josh W
        let stringCharacters = characters
        let searchCharacters = searchString.characters
        var searchOffset = stringCharacters.startIndex
        let searchLimit = stringCharacters.endIndex.advancedBy(-stringCount, limit:  stringCharacters.startIndex)
        var failedMatch = true

        // March character checks through string
        while searchOffset <= searchLimit {
            failedMatch = false

            // Enumerate through characters
            for (idx, c) in searchCharacters.enumerate() {
                if c != stringCharacters[searchOffset.advancedBy(idx, limit: stringCharacters.endIndex)] {
                    failedMatch = true; break
                }
            }

            // Test for success
            guard failedMatch else { break }

            // Offset search by one character
            searchOffset = searchOffset.successor()
        }

        return failedMatch ? nil : searchOffset..<searchOffset.advancedBy(stringCount, limit:searchString.endIndex)
    }

    /// Mimic NSString's version
    ///
    /// Performance note: "not very". This is a stop-gap for light
    /// use and not a fast solution
    ///
    public func componentsSeparatedByString(separator:  String) -> [String] {
        var components: [String] = []
        var searchString = self

        // Find a match
        while let range = searchString.rangeOfString(separator) {

            // Break off first item (thanks Josh W)
            let searchStringCharacters = searchString.characters
            let first = String(searchStringCharacters.prefixUpTo(range.startIndex))
            if !first.isEmpty { components.append(first) }

            // Anything left to find?
            if range.endIndex == searchString.endIndex {
                return components.isEmpty ? [self] : components
            }

            // Move past the separator and continue
            searchString = String(searchStringCharacters.suffixFrom(range.endIndex))
        }

        if !searchString.isEmpty { components.append(searchString) }
        return components
    }
}