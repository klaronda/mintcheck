//
//  OnboardingView.swift
//  MintCheck
//
//  3-slide onboarding carousel
//

import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void
    let onBack: () -> Void
    
    @State private var currentPage = 0
    
    private let slides: [OnboardingSlide] = [
        OnboardingSlide(
            icon: "waveform.path.ecg",
            title: "Scan Vehicle Systems",
            description: "Connect to your car's computer to check engine health, emissions, and more"
        ),
        OnboardingSlide(
            icon: "checkmark.seal.fill",
            title: "Get Instant Analysis",
            description: "Receive a detailed report on the vehicle's condition in minutes"
        ),
        OnboardingSlide(
            icon: "lightbulb.fill",
            title: "Make Smart Decisions",
            description: "Know what you're buying with confidence and transparency"
        )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Back/Skip header
            HStack {
                Button(action: onBack) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.textSecondary)
                        .frame(width: 44, height: 44)
                }
                
                Spacer()
                
                if currentPage < slides.count - 1 {
                    Button(action: onComplete) {
                        Text("Skip")
                            .font(.system(size: FontSize.bodyLarge, weight: .semibold))
                            .foregroundColor(.textSecondary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            
            // Content
            TabView(selection: $currentPage) {
                ForEach(0..<slides.count, id: \.self) { index in
                    OnboardingSlideView(slide: slides[index])
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            
            // Page dots
            HStack(spacing: 8) {
                ForEach(0..<slides.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentPage ? Color.mintGreen : Color.borderColor)
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut(duration: 0.2), value: currentPage)
                }
            }
            .padding(.bottom, 32)
            
            // Action button
            PrimaryButton(
                title: currentPage == slides.count - 1 ? "Get Started" : "Next",
                action: {
                    if currentPage < slides.count - 1 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        onComplete()
                    }
                }
            )
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
        .background(Color.white)
    }
}

struct OnboardingSlide {
    let icon: String
    let title: String
    let description: String
}

struct OnboardingSlideView: View {
    let slide: OnboardingSlide
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.statusSafeBg)
                    .frame(width: 80, height: 80)
                
                Image(systemName: slide.icon)
                    .font(.system(size: 32))
                    .foregroundColor(.mintGreen)
            }
            
            // Text
            VStack(spacing: 12) {
                Text(slide.title)
                    .font(.system(size: FontSize.h2, weight: .semibold))
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text(slide.description)
                    .font(.system(size: FontSize.bodyLarge))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 40)
            
            Spacer()
            Spacer()
        }
    }
}

#Preview {
    OnboardingView(onComplete: {}, onBack: {})
}
