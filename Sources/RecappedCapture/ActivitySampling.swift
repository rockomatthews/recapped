import Foundation
import RecappedCore

public protocol ActivitySampling: Sendable {
    func sample() -> ActivitySample
}
