//
//  OnboardingView.swift
//  MintCheck
//
//  3-slide onboarding carousel matching Figma design
//

import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void
    let onBack: () -> Void
    
    @State private var currentPage = 0
    
    private let totalSlides = 3
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with progress bar
            VStack(spacing: 0) {
                HStack {
                    Button(action: handleBack) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.textSecondary)
                            .frame(width: 44, height: 44)
                    }
                    
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.borderColor)
                                .frame(height: 4)
                            
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.mintGreen)
                                .frame(width: geometry.size.width * CGFloat(currentPage + 1) / CGFloat(totalSlides), height: 4)
                                .animation(.easeInOut(duration: 0.3), value: currentPage)
                        }
                    }
                    .frame(height: 4)
                    .padding(.trailing, 16)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .background(Color.white)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.borderColor),
                alignment: .bottom
            )
            
            // Scrollable content
            ScrollView {
                VStack(spacing: 0) {
                    // Icon
                    slideIcon
                        .padding(.top, 48)
                        .padding(.bottom, 32)
                    
                    // Title
                    Text(slideTitle)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.center)
                        .tracking(-0.3)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 12)
                    
                    // Description
                    Text(slideDescription)
                        .font(.system(size: FontSize.bodyLarge))
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 40)
                    
                    // Recommendation badges (only on last slide)
                    if currentPage == 2 {
                        recommendationBadges
                            .padding(.horizontal, 24)
                            .padding(.bottom, 40)
                        
                        // Disclaimer
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 14))
                                .foregroundColor(.textSecondary)
                            
                            Text("MintCheck helps you decide. It doesn’t replace a professional mechanic inspection.")
                                .font(.system(size: FontSize.bodySmall))
                                .foregroundColor(.textSecondary)
                                .lineSpacing(4)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                    }
                }
            }
            
            Spacer()
            
            // Fixed bottom buttons
            VStack(spacing: 10) {
                PrimaryButton(
                    title: currentPage == totalSlides - 1 ? "Get Started" : "Next",
                    action: handleNext
                )
                
                if currentPage < totalSlides - 1 {
                    Button(action: onComplete) {
                        Text("Skip")
                            .font(.system(size: FontSize.bodyLarge, weight: .semibold))
                            .foregroundColor(.textSecondary)
                    }
                    .frame(height: 48)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color.white)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.borderColor),
                alignment: .top
            )
        }
        .background(Color.deepBackground)
    }
    
    // MARK: - Slide Content
    
    private var slideIcon: some View {
        Group {
            switch currentPage {
            case 0:
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 64, weight: .light))
                    .foregroundColor(.textPrimary)
            case 1:
                Image(systemName: "wifi")
                    .font(.system(size: 64, weight: .light))
                    .foregroundColor(.textPrimary)
            case 2:
                Image(systemName: "doc.text")
                    .font(.system(size: 64, weight: .light))
                    .foregroundColor(.textPrimary)
            default:
                EmptyView()
            }
        }
    }
    
    private var slideTitle: String {
        switch currentPage {
        case 0:
            return "Buy a more reliable used car."
        case 1:
            return "Plug in and press start."
        case 2:
            return "Get trusted results."
        default:
            return ""
        }
    }
    
    private var slideDescription: String {
        switch currentPage {
        case 0:
            return "MintCheck does a quick check on the car you’re looking at, so you know the health before you buy.\n\nAnd once it’s yours, you can continue to scan your car regularly to keep it healthy."
        case 1:
            return "MintCheck works with a small Wi-Fi (OBD-II) scanner that plugs into the vehicle you’re checking.\n\nIf you don’t have a scanner yet, we’ll help you find a good one for less than $20."
        case 2:
            return "In just a few minutes, MintCheck gives you the recommendation you need to buy—or walk away—with full confidence."
        default:
            return ""
        }
    }
    
    // MARK: - Recommendation Badges
    
    private var recommendationBadges: some View {
        VStack(spacing: 10) {
            RecommendationPreviewBadge(
                icon: "checkmark.circle.fill",
                title: "Safe to Buy",
                color: .statusSafe
            )
            
            RecommendationPreviewBadge(
                icon: "exclamationmark.circle.fill",
                title: "Proceed with Caution",
                color: .statusCaution
            )
            
            RecommendationPreviewBadge(
                icon: "xmark.circle.fill",
                title: "Not Recommended",
                color: .statusDanger
            )
        }
    }
    
    // MARK: - Actions
    
    private func handleBack() {
        if currentPage > 0 {
            currentPage -= 1
        } else {
            onBack()
        }
    }
    
    private func handleNext() {
        if currentPage < totalSlides - 1 {
            currentPage += 1
        } else {
            onComplete()
        }
    }
}

// MARK: - Recommendation Preview Badge

struct RecommendationPreviewBadge: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: LayoutConstants.borderRadius)
                    .fill(color)
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.white)
            }
            
            Text(title)
                .font(.system(size: FontSize.bodyLarge, weight: .semibold))
                .foregroundColor(.textPrimary)
            
            Spacer()
        }
        .padding(LayoutConstants.padding4)
        .background(Color.white)
        .cornerRadius(LayoutConstants.borderRadius)
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.borderRadius)
                .stroke(Color.borderColor, lineWidth: 1)
        )
    }
}

#Preview {
    OnboardingView(onComplete: {}, onBack: {})
}
