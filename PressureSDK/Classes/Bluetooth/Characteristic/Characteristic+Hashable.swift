import Foundation
import RxBluetoothKit

extension Characteristic: Hashable {

    // DJB Hashing
//    public var hashValue: Int {
//        let scalarArray: [UInt32] = []
//        return scalarArray.reduce(5381) {
//            ($0 << 5) &+ $0 &+ Int($1)
//        }
//    }

    public func hash(into hasher: inout Hasher) {
        let scalarArray: [UInt32] = []
        let result = scalarArray.reduce(5381) {
            ($0 << 5) &+ $0 &+ Int($1)
        }
        hasher.combine(result)
    }
}
