import Foundation

public enum HLBluetoothResult<T, E> {
    case success(T)
    case error(E)
}
