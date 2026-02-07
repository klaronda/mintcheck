//
//  HomeView.swift
//  MintCheck
//
//  Welcome screen with hero image and CTAs
//

import SwiftUI

struct HomeView: View {
    let onStartCheck: () -> Void
    let onSignIn: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background image
                Image("hero-car")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                
                // Gradient overlay
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black.opacity(0.4),
                        Color.black.opacity(0.2),
                        Color.black.opacity(0.7)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // Content
                VStack {
                    // Logo at top
                    HStack(spacing: 10) {
                        Image("logo-white")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 36)
                        
                        Text("MintCheck")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .tracking(-0.2)
                    }
                    .padding(.top, 32)
                    
                    Spacer()
                    
                    // Bottom content
                    VStack(spacing: 12) {
                        // Headline
                        VStack(spacing: 8) {
                            Text("Know Before You Buy")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundColor(.white)
                                .tracking(-0.3)
                            
                            Text("Check used car vitals and real value in minutes")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.75))
                        }
                        .padding(.bottom, 20)
                        
                        // Primary CTA
                        Button(action: onStartCheck) {
                            Text("Start a Vehicle Check")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(Color.mintGreen)
                                .cornerRadius(LayoutConstants.borderRadius)
                        }
                        
                        // Secondary CTA
                        Button(action: onSignIn) {
                            Text("Create Account")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.textPrimary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(Color.white.opacity(0.95))
                                .cornerRadius(LayoutConstants.borderRadius)
                        }
                        
                        // Testimonial
                        Text("Like bringing my own mechanic to buy a used car")
                            .font(.system(size: 14))
                            .italic()
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.top, 12)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 48)
                }
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    HomeView(onStartCheck: {}, onSignIn: {})
}
