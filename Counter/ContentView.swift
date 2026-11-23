import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: CounterStore
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var volume = VolumeButtonObserver()

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            VStack(spacing: 8) {
                OdometerView(count: store.rollingValue)
                    .frame(height: h * 0.12)

                // Big add button: fires on touch-DOWN for the lowest latency,
                // so fast tapping never waits for a finger lift.
                Rectangle()
                    .fill(Color.green)
                    .overlay(Image(systemName: "plus")
                        .font(.system(size: 120, weight: .bold))
                        .foregroundStyle(.white))
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .frame(height: h * 0.70)
                    .contentShape(Rectangle())
                    .gesture(DragGesture(minimumDistance: 0)
                        .onChanged { _ in if !plusDown { plusDown = true; store.increment() } }
                        .onEnded { _ in plusDown = false })

                HStack(spacing: 8) {
                    // Small reset button, bottom-LEFT.
                    Button { store.inputLocked = true } label: {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(white: 0.12))
                            .overlay(Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(.red.opacity(0.8)))
                    }
                    .frame(width: geo.size.width * 0.22)

                    Button { store.decrement() } label: {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(white: 0.2))
                            .overlay(Image(systemName: "minus")
                                .font(.system(size: 30, weight: .bold))
                                .foregroundStyle(.white))
                    }
                }
                .frame(maxHeight: .infinity)
            }
            .padding(12)
            .frame(width: geo.size.width, height: h)
        }
        .background(Color.black.ignoresSafeArea())
        .overlay(alignment: .topLeading) {
            VolumeViewHost(view: volume.volumeView)
                .frame(width: 1, height: 1)
                .opacity(0.01)
                .allowsHitTesting(false)
        }
        .overlay {
            if store.inputLocked { resetConfirmation }
        }
        .onAppear {
            volume.onUp = { store.increment() }
            volume.onDown = { store.decrement() }
            UIApplication.shared.isIdleTimerDisabled = true
            volume.start()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { volume.start() } else { volume.stop() }
        }
        .preferredColorScheme(.dark)
    }

    @State private var plusDown = false

    /// Cancel sits where the reset button was (bottom-left); the destructive
    /// confirm is bottom-RIGHT, so a double-tap on reset can't confirm it.
    private var resetConfirmation: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()
            VStack(spacing: 8) {
                Spacer()
                Text("Reset counter to 0?")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                Spacer()
                HStack(spacing: 8) {
                    Button { store.inputLocked = false } label: {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(white: 0.25))
                            .overlay(Text("Cancel").font(.headline).foregroundStyle(.white))
                    }
                    Button { store.reset() } label: {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.red)
                            .overlay(Text("Reset").font(.headline).foregroundStyle(.white))
                    }
                }
                .frame(height: 80)
            }
            .padding(12)
        }
    }
}
