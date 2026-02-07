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
    
    @EnvironmentObject var nav: NavigationManager
    @State private var showToast = false
    
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
                    // Logo lockup at top (moved down and increased 20%)
                    Image("lockup-white")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 48)
                        .padding(.top, 72)
                    
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
                        Text("Like bringing your own mechanic to buy a used car")
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
        .overlay(alignment: .top) {
            // Toast message for account deletion
            if showToast, let message = nav.accountDeletedMessage {
                ToastView(message: message)
                    .padding(.top, 60)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .onAppear {
            // Show toast if message is already set when view appears
            if nav.accountDeletedMessage != nil {
                withAnimation {
                    showToast = true
                }
                // Auto-dismiss after 4 seconds
                Task {
                    try? await Task.sleep(nanoseconds: 4_000_000_000)
                    await MainActor.run {
                        withAnimation {
                            showToast = false
                        }
                        // Clear message after animation
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            nav.accountDeletedMessage = nil
                        }
                    }
                }
            }
        }
        .onChange(of: nav.accountDeletedMessage) { _, newMessage in
            if newMessage != nil && !showToast {
                withAnimation {
                    showToast = true
                }
                // Auto-dismiss after 4 seconds
                Task {
                    try? await Task.sleep(nanoseconds: 4_000_000_000)
                    await MainActor.run {
                        withAnimation {
                            showToast = false
                        }
                        // Clear message after animation
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            nav.accountDeletedMessage = nil
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Toast View
struct ToastView: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(.statusSafe)
            
            Text(message)
                .font(.system(size: FontSize.bodyRegular))
                .foregroundColor(.textPrimary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color.white)
        .cornerRadius(LayoutConstants.borderRadiusLarge)
        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 24)
    }
}

#Preview {
    HomeView(onStartCheck: {}, onSignIn: {})
}
