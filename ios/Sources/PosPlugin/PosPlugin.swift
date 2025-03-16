import Foundation
import Capacitor

/**
 * Please read the Capacitor iOS Plugin Development Guide
 * here: https://capacitorjs.com/docs/plugins/ios
 */
@objc(PosPlugin)
public class PosPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "PosPlugin"
    public let jsName = "Pos"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "connect", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "disconnect", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "send", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "scan", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "privateIp", returnType: CAPPluginReturnPromise)
    ]
    private let implementation = Pos()
    
    @objc func connect(_ call: CAPPluginCall) {
        guard let host = call.getString("host"),
              let port = call.getInt("port") else {
            call.reject("host, port required")
            return
        }

        implementation.connect(host: host, port: UInt16(port)) { result in
            switch result {
            case .success:
                call.resolve(["status": "connected"])
            case .failure(let error):
                call.reject("Bağlantı hatası: \(error)")
            }
        }
    }

    @objc func disconnect(_ call: CAPPluginCall) {
        guard let host = call.getString("host"),
              let port = call.getInt("port") else {
            call.reject("host, port required")
            return
        }

        implementation.disconnect(host: host, port: UInt16(port))
        call.resolve(["status": "disconnected"])
    }

    @objc func send(_ call: CAPPluginCall) {
        guard let host = call.getString("host"),
              let port = call.getInt("port"),
              let data = call.getArray("data", UInt8.self) else {
              call.reject("host, port, data required")
           return
       }

        implementation.send(host: host, port: UInt16(port), data: Data(data)) { result in
           switch result {
           case .success:
               let byteArray = [UInt8](data)
               call.resolve(["result": byteArray])
           case .failure(let error):
               call.reject("Veri gönderme hatası: \(error)")
           }
       }
    }

    @objc func scan(_ call: CAPPluginCall) {
        guard let host = call.getString("host"),
              let port = call.getInt("port") else {
            call.reject("Missing parameters")
            return
        }

        implementation.scanNetwork(host: host, port: UInt16(port), resolve: { (devices) in
            call.resolve(["devices": devices])
        })
    }

    @objc func privateIp(_ call: CAPPluginCall) {
        call.resolve(["ip": implementation.getPrivateIP()])
    }
    
}
