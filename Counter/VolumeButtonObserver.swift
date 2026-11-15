import AVFoundation
import MediaPlayer
import SwiftUI

/// Turns the hardware volume buttons into up/down events without changing the
/// user's volume.
///
/// How it works (iOS has no official API for this):
///  1. Observe AVAudioSession.outputVolume (KVO). Every press changes it by 1/16.
///  2. Park the system volume mid-range so presses never hit the 0 / 1 limits,
///     where no change event would fire. We only re-center when the volume drifts
///     outside a window, so rapid presses are never interrupted by our own resets.
///  3. A hidden MPVolumeView on screen suppresses the system volume HUD and gives
///     us the slider used to set the volume programmatically.
///  4. The user's original volume is restored when the app leaves the foreground.
@MainActor
final class VolumeButtonObserver: ObservableObject {
    var onUp: (() -> Void)?
    var onDown: (() -> Void)?

    let volumeView = MPVolumeView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))

    private let session = AVAudioSession.sharedInstance()
    private var observation: NSKeyValueObservation?
    private var originalVolume: Float?
    private var lastVolume: Float = 0.5
    private var resetTarget: Float?
    private let anchor: Float = 0.5
    private let window: ClosedRange<Float> = 0.25...0.75

    private var slider: UISlider? {
        volumeView.subviews.compactMap { $0 as? UISlider }.first
    }

    func start() {
        guard observation == nil else { return }
        // .ambient + mixWithOthers: don't interrupt the user's music.
        try? session.setCategory(.ambient, options: [.mixWithOthers])
        try? session.setActive(true)

        originalVolume = session.outputVolume
        observation = session.observe(\.outputVolume, options: [.new]) { [weak self] _, change in
            guard let v = change.newValue else { return }
            Task { @MainActor in self?.handle(v) }
        }
        // The slider needs a tick to exist after the view is in a window.
        DispatchQueue.main.async { [weak self] in self?.recenter() }
    }

    func stop() {
        observation = nil
        if let original = originalVolume { setSystemVolume(original) }
        originalVolume = nil
        resetTarget = nil
        try? session.setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func handle(_ v: Float) {
        if let target = resetTarget, abs(v - target) < 0.001 {
            // Landing of our own reset, not a button press.
            resetTarget = nil
            lastVolume = v
            return
        }
        if v > lastVolume { onUp?() } else if v < lastVolume { onDown?() }
        lastVolume = v
        if !window.contains(v) { recenter() }
    }

    private func recenter() {
        resetTarget = anchor
        lastVolume = anchor
        setSystemVolume(anchor)
    }

    private func setSystemVolume(_ value: Float) {
        slider?.setValue(value, animated: false)
        slider?.sendActions(for: .touchUpInside)
    }
}

/// Embeds the MPVolumeView (practically invisible, 1x1) in the SwiftUI tree.
struct VolumeViewHost: UIViewRepresentable {
    let view: MPVolumeView
    func makeUIView(context: Context) -> MPVolumeView { view }
    func updateUIView(_ uiView: MPVolumeView, context: Context) {}
}
