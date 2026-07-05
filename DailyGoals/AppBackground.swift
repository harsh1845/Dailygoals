//
//  AppBackground.swift
//  DailyGoals
//
//  Created by harsh selarka on 30/11/2025.
//


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
struct FocusBackground: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            // 1. Deep Base
            Color(red: 0.05, green: 0.05, blue: 0.08)
                .ignoresSafeArea()
            
            GeometryReader { proxy in
                // 2. The Orbs (Removed .blendMode, adjusted opacity for smoothness)
                
                // Top-Left: Hot Pink
                Circle()
                    .fill(GoalColors.all[4].opacity(0.5)) // slightly higher opacity
                    .frame(width: 600, height: 600)
                    .blur(radius: 120) // softer blur
                    .offset(x: animate ? -100 : -200, y: animate ? -100 : -200)
                
                // Bottom-Right: Teal
                Circle()
                    .fill(GoalColors.all[7].opacity(0.4))
                    .frame(width: 500, height: 500)
                    .blur(radius: 120)
                    .offset(x: proxy.size.width * 0.4, y: proxy.size.height * 0.4)
                
                // Center: Orange ("Focus Core")
                // FIX: Removed .blendMode(.overlay) which caused the box artifact
                Circle()
                    .fill(GoalColors.all[3].opacity(0.4))
                    .frame(width: 450, height: 450)
                    .blur(radius: 100)
                    .offset(x: animate ? 50 : -50, y: animate ? 50 : -50)
            }
        }
        .drawingGroup() // Keeps performance high
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 7).repeatForever(autoreverses: true)) {
                animate.toggle()
            }
        }
    }
}
