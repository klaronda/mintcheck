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
    let onBuyStarterKit: () -> Void
    
    @EnvironmentObject var nav: NavigationManager
    @State private var showToast = false
    /// Bump key when the promo should show again for everyone who dismissed (e.g. new pricing).
    /// Old key `hideStarterKitHomePromo` is ignored after this change.
    @AppStorage("hideStarterKitHomePromo_v2") private var hideStarterKitHomePromo = false
    
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
                VStack(spacing: 0) {
                    // Logo lockup at top (moved down and increased 20%)
                    Image("lockup-white")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 48)
                        .padding(.top, 72)
                    
                    if !hideStarterKitHomePromo {
                        StarterKitPromoCard(
                            onDismiss: { hideStarterKitHomePromo = true },
                            onBuy: onBuyStarterKit
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                    
                    Spacer(minLength: 12)
                    
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
                            Text("Sign In")
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

// MARK: - Starter Kit promo (logged-out home)
private struct StarterKitPromoCard: View {
    let onDismiss: () -> Void
    let onBuy: () -> Void
    
    private let cardCorner: CGFloat = 16
    private let scannerThumbCorner: CGFloat = 12
    /// Matches the panel behind the product shot so feathered edges blend instead of a hard white box.
    private var scannerPanelFill: Color { Color.white.opacity(0.94) }
    
    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: scannerThumbCorner, style: .continuous)
                    .fill(scannerPanelFill)
                Image("starter-kit-scanner")
                    .resizable()
                    .scaledToFit()
                    .padding(8)
                    // Soften harsh studio-white edges into the panel
                    .mask {
                        RoundedRectangle(cornerRadius: scannerThumbCorner, style: .continuous)
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(stops: [
                                        .init(color: .white, location: 0),
                                        .init(color: .white, location: 0.42),
                                        .init(color: .white.opacity(0.45), location: 0.78),
                                        .init(color: .clear, location: 1)
                                    ]),
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 86
                                )
                            )
                    }
                // Extra edge blend so corners don’t show a bright rim
                RoundedRectangle(cornerRadius: scannerThumbCorner, style: .continuous)
                    .fill(
                        RadialGradient(
                            gradient: Gradient(stops: [
                                .init(color: .clear, location: 0),
                                .init(color: .clear, location: 0.62),
                                .init(color: scannerPanelFill.opacity(0.55), location: 0.92),
                                .init(color: scannerPanelFill.opacity(0.85), location: 1)
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 90
                        )
                    )
                    .allowsHitTesting(false)
            }
            // Landscape product shot: wider tile than the portrait scanner asset
            .frame(width: 128, height: 92)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.black.opacity(0.08), lineWidth: 1)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("MintCheck Starter Kit")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                
                Text("Wi-Fi scanner plus a 60-day pass—scan up to 10 vehicles per day.")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.88))
                    .lineSpacing(2)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)
                
                Text("$34.99")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.mintGreen)
                
                Button {
                    onBuy()
                } label: {
                    Text("Buy Starter Kit")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.mintGreen)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
                
                Text("You'll need a compatible Wi-Fi OBD2 scanner to use this app.")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.55))
                    .lineLimit(3)
                    .padding(.top, 2)
            }
        }
        .padding(14)
        .overlay(alignment: .topTrailing) {
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 22))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.white.opacity(0.55))
            }
            .buttonStyle(.plain)
            .padding(8)
            .accessibilityLabel("Dismiss")
        }
        .background {
            RoundedRectangle(cornerRadius: cardCorner, style: .continuous)
                .fill(.ultraThinMaterial)
        }
        .overlay {
            RoundedRectangle(cornerRadius: cardCorner, style: .continuous)
                .strokeBorder(Color.white.opacity(0.22), lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.35), radius: 18, x: 0, y: 10)
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
    HomeView(onStartCheck: {}, onSignIn: {}, onBuyStarterKit: {})
        .environmentObject(NavigationManager())
}
