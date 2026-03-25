//
//  OnboardingView.swift
//  MintCheck
//
//  3-slide onboarding: engine health, Local Network access, trusted results.
//

import SwiftUI
import AVKit
import AVFoundation

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
            
            // Scrollable content – align to top
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    slideContent
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding(.horizontal, 32)
                .padding(.top, 24)
                .padding(.bottom, 40)
            }
            
            Spacer(minLength: 0)
            
            // Sticky bottom buttons
            VStack(spacing: 10) {
                PrimaryButton(
                    title: currentPage == totalSlides - 1 ? "Get Started" : "Next",
                    action: handleNext
                )
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
    
    // MARK: - Slide Content (top-aligned)
    
    @ViewBuilder
    private var slideContent: some View {
        switch currentPage {
        case 0:
            // Screen 1: Know before you buy
            Image("engine-health")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.borderRadius))
                .padding(.bottom, 32)
            
            Text("Know before you buy.")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.leading)
                .tracking(-0.3)
                .padding(.bottom, 12)
            
            Text("MintCheck does a quick check on the car you're looking at, so you know the health before you buy.")
                .font(.system(size: FontSize.bodyLarge))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.leading)
                .lineSpacing(4)
            
        case 1:
            // Screen 2: Allow Local Network – video then text
            LoopingVideoPlayerView(filename: "local-network", fileExtension: "mp4")
                .aspectRatio(16/9, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.borderRadius))
                .padding(.bottom, 32)
            
            Text("When prompted, allow Local Network Access.")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.leading)
                .tracking(-0.3)
                .padding(.bottom, 12)
            
            localNetworkBody
            
        case 2:
            // Screen 3: Get trusted results – no icon, title on top
            Text("Get trusted results.")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.leading)
                .tracking(-0.3)
            
            Spacer().frame(height: 12)
            
            Text("In just a few minutes, MintCheck gives you the recommendation you need to buy—or walk away—with full confidence.")
                .font(.system(size: FontSize.bodyLarge))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.leading)
                .lineSpacing(4)
                .padding(.bottom, 32)
            
            recommendationBadges
                .padding(.bottom, 40)
            
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "info.circle")
                    .font(.system(size: 14))
                    .foregroundColor(.textSecondary)
                
                Text("MintCheck helps you decide. It doesn't replace a professional mechanic inspection.")
                    .font(.system(size: FontSize.bodySmall))
                    .foregroundColor(.textSecondary)
                    .lineSpacing(4)
            }
            
        default:
            EmptyView()
        }
    }
    
    private var localNetworkBody: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("MintCheck works with select Wi-Fi car scanners that plug into the car. When you connect one, iOS may ask for Local Network access—allow it so the app can reach your device.")
                .font(.system(size: FontSize.bodyLarge))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.leading)
                .lineSpacing(4)
            
            Spacer().frame(height: 12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Don't have a car scanner yet? ")
                    .font(.system(size: FontSize.bodyLarge, weight: .semibold))
                    .foregroundColor(.textPrimary)
                Text("We'll help you find one for less than $15.")
                    .font(.system(size: FontSize.bodyLarge))
                    .foregroundColor(.textSecondary)
            }
            .lineSpacing(4)
        }
    }
    
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

// MARK: - Looping Video Player

struct LoopingVideoPlayerView: View {
    let filename: String
    let fileExtension: String
    
    var body: some View {
        Group {
            if Bundle.main.url(forResource: filename, withExtension: fileExtension) != nil {
                LoopingVideoPlayerRepresentable(filename: filename, fileExtension: fileExtension)
            } else {
                // Fallback when e.g. local-network.mp4 is not in the app bundle
                ZStack {
                    RoundedRectangle(cornerRadius: LayoutConstants.borderRadius)
                        .fill(Color.borderColor.opacity(0.3))
                    Image(systemName: "wifi")
                        .font(.system(size: 64, weight: .light))
                        .foregroundColor(.textSecondary)
                }
                .aspectRatio(16/9, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.borderRadius))
            }
        }
    }
}

private struct LoopingVideoPlayerRepresentable: UIViewControllerRepresentable {
    let filename: String
    let fileExtension: String
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.showsPlaybackControls = false
        controller.videoGravity = .resizeAspect
        
        guard let url = Bundle.main.url(forResource: filename, withExtension: fileExtension) else {
            return controller
        }
        
        let player = AVPlayer(url: url)
        context.coordinator.player = player
        controller.player = player
        player.play()
        
        // Zoom in 5% so the view is clipped and hides a thin black line at the top of the asset
        controller.view.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var player: AVPlayer?
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
