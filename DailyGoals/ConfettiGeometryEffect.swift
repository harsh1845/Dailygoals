import SwiftUI

// A physics-based modifier for particles
struct ConfettiGeometryEffect: GeometryEffect {
    var time: Double
    var speed: Double = Double.random(in: 50...200)
    var direction: Double = Double.random(in: -Double.pi...Double.pi)
    
    var animatableData: Double {
        get { time }
        set { time = newValue }
    }
    
    func effectValue(size: CGSize) -> ProjectionTransform {
        // Simple Physics: Velocity + Gravity
        let xTranslation = speed * cos(direction) * time
        let yTranslation = speed * sin(direction) * time + (200 * time * time) 
        return ProjectionTransform(CGAffineTransform(translationX: xTranslation, y: yTranslation))
    }
}

struct ConfettiView: View {
    @State private var time = 0.0
    @State private var opacity = 1.0
    
    var body: some View {
        ZStack {
            // Create 30 random particles
            ForEach(0..<30) { _ in
                Circle()
                    .fill(GoalColors.all.randomElement() ?? .pink)
                    .frame(width: CGFloat.random(in: 5...10))
                    .modifier(ConfettiGeometryEffect(time: time))
                    .opacity(opacity)
            }
        }
        .allowsHitTesting(false) // Let clicks pass through
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) {
                time = 1.5
                opacity = 0
            }
        }
    }
}