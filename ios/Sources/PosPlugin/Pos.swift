import Foundation

@objc public class Pos: NSObject {
    
    var connection: NWConnection?
    var browser: NWBrowser?

    @objc public func sendData(ip: String, port: UInt16, data: Data, resolve: @escaping (UInt8) -> Void, reject: @escaping (String, String, Error?) -> Void) {
        let endpoint = NWEndpoint.hostPort(host: NWEndpoint.Host(ip), port: NWEndpoint.Port(rawValue: port)!)
        connection = NWConnection(to: endpoint, using: .tcp)

        connection?.stateUpdateHandler = { state in
            switch state {
            case .ready:
                self.connection?.send(content: data, completion: .contentProcessed({ error in
                    if let error = error {
                        reject("Send Failed", "Failed to send data to printer", error)
                    }
                }))
                
                self.connection?.receive(minimumIncompleteLength: 1, maximumLength: 640000) { receivedData, _, _, error in
                    if let receivedData = receivedData?.first {
                        resolve(receivedData)
                    } else if let error = error {
                        reject("Receive Failed", "Failed to receive data from printer", error)
                    } else {
                        reject("Receive Failed", "Failed to receive data from printer", nil)
                    }
                    self.connection?.cancel()
                }
                
            case .failed(let error):
                reject("Connection Failed", "Failed to connect to printer", error)
            default:
                break
            }
        }

        connection?.start(queue: .global())
    }

    @objc public func scanNetwork(ip: String, port: UInt16, resolve: @escaping ([String]) -> Void) {
        var devices: [String] = []
        let dispatchGroup = DispatchGroup()
        let queue = DispatchQueue.global(qos: .background)

        for i in 1...254 {
            let ip = "\(ip).\(i)"
            dispatchGroup.enter()

            queue.async {
                let endpoint = NWEndpoint.hostPort(host: NWEndpoint.Host(ip), port: NWEndpoint.Port(rawValue: port)!)
                let connection = NWConnection(to: endpoint, using: .tcp)

                var hasLeftGroup = false

                connection.stateUpdateHandler = { state in
                    switch state {
                    case .ready:
                        devices.append(ip)
                        connection.cancel()
                        if !hasLeftGroup {
                            hasLeftGroup = true
                            dispatchGroup.leave()
                        }
                    case .failed, .cancelled:
                        connection.cancel()
                        if !hasLeftGroup {
                            hasLeftGroup = true
                            dispatchGroup.leave()
                        }
                    default:
                        break
                    }
                }

                connection.start(queue: queue)

                queue.asyncAfter(deadline: .now() + 3) {
                    connection.cancel()
                    if !hasLeftGroup {
                        hasLeftGroup = true
                        dispatchGroup.leave()
                    }
                }
            }
        }

        dispatchGroup.notify(queue: .main) {
            resolve(devices)
        }
    }

    @objc public func getPrivateIP() -> String? {
        var address: String?

        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                defer { ptr = ptr?.pointee.ifa_next }

                let interface = ptr?.pointee
                let addrFamily = interface?.ifa_addr.pointee.sa_family

                if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
                    let name = String(cString: (interface?.ifa_name)!)
                    if name == "en0" {
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        getnameinfo(interface?.ifa_addr, socklen_t((interface?.ifa_addr.pointee.sa_len)!),
                                    &hostname, socklen_t(hostname.count),
                                    nil, socklen_t(0), NI_NUMERICHOST)
                        address = String(cString: hostname)
                    }
                }
            }
            freeifaddrs(ifaddr)
        }

        return address
    }
}
