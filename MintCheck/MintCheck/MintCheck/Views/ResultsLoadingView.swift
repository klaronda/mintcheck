//
//  ResultsLoadingView.swift
//  MintCheck
//
//  Loading screen shown while AI analyzes vehicle data
//

import SwiftUI

struct ResultsLoadingView: View {
    var body: some View {
        ZStack {
            // Mint green background
            Color.mintGreen
                .ignoresSafeArea()
            
            // Content
            VStack(spacing: 24) {
                // Logo lockup
                Image("lockup-white")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 60)
                
                // Progress indicator
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                    .padding(.top, 8)
                
                // Loading message
                Text("Analyzing vehicle data...")
                    .font(.system(size: FontSize.bodyLarge, weight: .medium))
                    .foregroundColor(.white)
            }
        }
    }
}

#Preview {
    ResultsLoadingView()
}
