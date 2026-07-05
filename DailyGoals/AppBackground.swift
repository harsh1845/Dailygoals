import SwiftUI

struct AppBackground: View {
    var body: some View {
        ZStack {
            // 1. Deep Base Color (Not pure black, slightly tinted)
            Color(red: 0.10, green: 0.10, blue: 0.12)
                .ignoresSafeArea()
            
            // 2. Top Left Glow (Lilac)
            GeometryReader { proxy in
                Circle()
                    .fill(GoalColors.all[0].opacity(0.25)) // Lilac
                    .blur(radius: 120)
                    .offset(x: -proxy.size.width * 0.2, y: -proxy.size.height * 0.2)
                    .frame(width: 600, height: 600)
                
                // 3. Bottom Right Glow (Teal/Mint)
                Circle()
                    .fill(GoalColors.all[7].opacity(0.20)) // Sky Teal
                    .blur(radius: 100)
                    .offset(x: proxy.size.width * 0.4, y: proxy.size.height * 0.4)
                    .frame(width: 500, height: 500)
                
                // 4. Center-Left Hint (Peach)
                Circle()
                    .fill(GoalColors.all[3].opacity(0.15)) // Peach
                    .blur(radius: 90)
                    .offset(x: -proxy.size.width * 0.1, y: proxy.size.height * 0.1)
                    .frame(width: 300, height: 300)
            }
        }
        .drawingGroup() // Optimizes rendering performance
        .ignoresSafeArea()
    }
}

#Preview {
    AppBackground()
}