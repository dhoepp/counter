import Foundation
import UIKit

/// Single source of truth. Everything runs on the main thread, so no locks are
/// needed and no press can be dropped: each call mutates the value synchronously.
@MainActor
final class CounterStore: ObservableObject {
    static let maxValue = 9999

    @Published private(set) var count: Int
    private let defaults = UserDefaults.standard
    private let key = "count"
    private let impact = UIImpactFeedbackGenerator(style: .rigid)

    init() {
        count = min(max(defaults.integer(forKey: key), 0), Self.maxValue)
        impact.prepare()
    }

    func increment() { set(count + 1) }
    func decrement() { set(count - 1) }

    private func set(_ new: Int) {
        let clamped = min(max(new, 0), Self.maxValue)
        guard clamped != count else { return }
        count = clamped
        defaults.set(clamped, forKey: key)
        impact.impactOccurred()
        impact.prepare()
    }
}
