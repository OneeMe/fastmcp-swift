import Foundation

extension NSLock {
    @inlinable
    func withLock<T>(_ body: () throws -> T) rethrows -> T {
        self.lock()
        defer { self.unlock() }
        return try body()
    }
}


