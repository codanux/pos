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
        CAPPluginMethod(name: "send", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "scan", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "privateIp", returnType: CAPPluginReturnPromise)
    ]
    private let implementation = Pos()

    @objc func send(_ call: CAPPluginCall) {
        guard let ip = call.getString("ip"),
              let port = call.getInt("port"),
              let data = call.getArray("data", UInt8.self) else {
            call.reject("Missing parameters")
            return
        }
        
        implementation.sendData(ip: ip, port: UInt16(port), data: Data(data), resolve: { (result) in
              call.resolve(["result": result])
          }, reject: { (code, message, error) in
              call.reject(message, code, error)
          })
        
    }

    @objc func scan(_ call: CAPPluginCall) {
        guard let ip = call.getString("ip"),
              let port = call.getInt("port") else {
            call.reject("Missing parameters")
            return
        }

        implementation.scanNetwork(ip: ip, port: UInt16(port), resolve: { (devices) in
            call.resolve(["devices": devices])
        })
    }

    @objc func privateIp(_ call: CAPPluginCall) {
        call.resolve(["ip": implementation.getPrivateIP()])
    }
    
}
