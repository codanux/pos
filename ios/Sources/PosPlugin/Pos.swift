import Foundation
import Network

@objc public class Pos: NSObject {
    
    private var connections: [String: NWConnection] = [:]

    func connect(host: String, port: UInt16, completion: @escaping (Result<Void, Error>) -> Void) {
        let nwHost = NWEndpoint.Host(host)
        guard let nwPort = NWEndpoint.Port(rawValue: port) else {
            completion(.failure(NSError(domain: "TCPConnectionManager", code: 400 )))
            return
        }

       let connection = NWConnection(host: nwHost, port: nwPort, using: .tcp)
       connection.stateUpdateHandler = { state in
           switch state {
           case .ready:
               completion(.success(()))
           case .failed(let error):
               completion(.failure(error))
           default:
               break
           }
       }
       connection.start(queue: .global())
       let id = "\(host):\(port)"
       connections[id] = connection
    }

    func send(host: String, port: UInt16, data: Data, completion: @escaping (Result<Data, Error>) -> Void) {
        let id = "\(host):\(port)"
        
        guard let connection = connections[id] else {
            return connect(host: host, port: port) { result in
                switch result {
                case .success:
                    self.send(host: host, port: port, data: data, completion: completion)
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }

        connection.send(content: data, completion: .contentProcessed { error in
            if let error = error {
                completion(.failure(error))
            }
        })
        
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { data, cData, isComplete, error in
            if let data = data {
                completion(.success(data))
            } else if let error = error {
                completion(.failure(error))
            } 
        }
    }

    func disconnect(host: String, port: UInt16) {
        let id = "\(host):\(port)"
        connections[id]?.cancel()
        connections.removeValue(forKey: id)
    }

    @objc public func scanNetwork(host: String, port: UInt16, resolve: @escaping ([String]) -> Void) {
        var devices: [String] = []
        let dispatchGroup = DispatchGroup()
        let queue = DispatchQueue.global(qos: .background)

        for i in 1...254 {
            let ip = "\(host).\(i)"
            dispatchGroup.enter()

            queue.async {
                let endpoint = NWEndpoint.hostPort(host: NWEndpoint.Host(host), port: NWEndpoint.Port(rawValue: port)!)
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
