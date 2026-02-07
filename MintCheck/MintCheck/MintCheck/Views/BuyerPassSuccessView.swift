//
//  BuyerPassSuccessView.swift
//  MintCheck
//
//  Shown when user returns from Stripe Buyer Pass payment (deep link).
//

import SwiftUI

struct BuyerPassSuccessView: View {
    @EnvironmentObject var authService: AuthService
    let onDone: () -> Void

    @State private var isLoading = true
    @State private var activated = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.4)
                        .tint(.mintGreen)

                    Text("Confirming your purchase...")
                        .font(.system(size: FontSize.bodyLarge, weight: .medium))
                        .foregroundColor(.textSecondary)
                } else {
                    ZStack {
                        Circle()
                            .fill(Color.mintGreen.opacity(0.15))
                            .frame(width: 100, height: 100)

                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 56))
                            .foregroundColor(.mintGreen)
                    }

                    Text("Buyer Pass Activated")
                        .font(.system(size: FontSize.h2, weight: .semibold))
                        .foregroundColor(.textPrimary)

                    Text("You have 60 days of unlimited scanning. Scan up to 10 vehicles per day.")
                        .font(.system(size: FontSize.bodyLarge))
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 24)
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            if !isLoading {
                VStack(spacing: 0) {
                    PrimaryButton(
                        title: "Go to Dashboard",
                        action: onDone
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
        }
        .background(Color.deepBackground)
        .task {
            await confirmActivation()
        }
    }

    private func confirmActivation() async {
        // Poll for up to ~15 seconds (webhook may take a moment)
        for _ in 0..<6 {
            let active = await BuyerPassService.shared.loadActiveBuyerPass()
            if active {
                await authService.refreshBuyerPassStatus()
                await MainActor.run {
                    activated = true
                    isLoading = false
                }
                return
            }
            try? await Task.sleep(nanoseconds: 2_500_000_000) // 2.5 seconds
        }

        // Even if we couldn't confirm yet, show success (webhook may still be processing)
        await authService.refreshBuyerPassStatus()
        await MainActor.run {
            isLoading = false
        }
    }
}
