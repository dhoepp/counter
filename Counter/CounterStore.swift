import Foundation
import UIKit

/// Single source of truth. Everything runs on the main thread, so no locks are
/// needed and no press can be dropped: each call mutates the value synchronously.
@MainActor
final class CounterStore: ObservableObject {
    static let maxValue = 9999

    @Published private(set) var count: Int
    /// Number of times we've wrapped 9999 -> 0 this session. Only used so the
    /// wheels keep rolling forward through the wrap instead of rewinding.
    @Published private(set) var lap = 0
    /// True while the reset confirmation is showing; blocks all counting
    /// (including volume buttons) so nothing changes under the dialog.
    @Published var inputLocked = false
    var rollingValue: Int { count + lap * (Self.maxValue + 1) }
    private let defaults = UserDefaults.standard
    private let key = "count"
    private let impact = UIImpactFeedbackGenerator(style: .rigid)

    init() {
        count = min(max(defaults.integer(forKey: key), 0), Self.maxValue)
        impact.prepare()
    }

    func increment() {
        guard !inputLocked else { return }
        if count == Self.maxValue {
            lap += 1
            commit(0)
        } else {
            commit(count + 1)
        }
    }
    /// Minus stops at 0 (no wrap downward).
    func decrement() {
        guard !inputLocked, count > 0 else { return }
        commit(count - 1)
    }

    func reset() {
        lap = 0
        commit(0)
        inputLocked = false
    }

    private func commit(_ new: Int) {
        count = new
        defaults.set(new, forKey: key)
        impact.impactOccurred()
        impact.prepare()
    }
}
