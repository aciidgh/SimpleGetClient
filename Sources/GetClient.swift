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

	public func fetch(urlString: String) -> String {

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
		
		return String.fromCString(buf)!
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