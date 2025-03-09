import Foundation

@objc public class Pos: NSObject {
    @objc public func echo(_ value: String) -> String {
        print(value)
        return value
    }
}
