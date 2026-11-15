import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: CounterStore
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var volume = VolumeButtonObserver()

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            VStack(spacing: 8) {
                OdometerView(count: store.count)
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

                Button { store.decrement() } label: {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(white: 0.2))
                        .overlay(Image(systemName: "minus")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundStyle(.white))
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
}
