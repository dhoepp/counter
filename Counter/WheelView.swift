import SwiftUI

/// One odometer wheel. `position` is a continuous, ever-increasing step count
/// (not 0-9), so rolling 9 -> 0 keeps scrolling forward instead of rewinding.
/// Conforming to Animatable lets SwiftUI interpolate `position` every frame,
/// and rapid taps simply retarget the animation without queueing.
struct WheelView: View, Animatable {
    var position: Double

    var animatableData: Double {
        get { position }
        set { position = newValue }
    }

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            let base = Int(position.rounded(.down))
            ZStack {
                ForEach((base - 1)...(base + 2), id: \.self) { n in
                    Text("\(((n % 10) + 10) % 10)")
                        .font(.system(size: h * 0.78, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                        .frame(width: geo.size.width, height: h)
                        .offset(y: (Double(n) - position) * h)
                }
            }
            .frame(width: geo.size.width, height: h)
            .clipped()
        }
        .background(
            LinearGradient(colors: [.black, Color(white: 0.18), .black],
                           startPoint: .top, endPoint: .bottom)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(white: 0.3), lineWidth: 1))
    }
}

struct OdometerView: View {
    let count: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach((0..<4).reversed(), id: \.self) { i in
                // Number of times this wheel has been "ticked" so far.
                let steps = count / Int(pow(10, Double(i)))
                WheelView(position: Double(steps))
                    .animation(.easeOut(duration: 0.12), value: steps)
            }
        }
    }
}
