//
//  HeaderView.swift
//  MintCheck
//
//  Common header components for screens
//

import SwiftUI

struct ScreenHeader: View {
    let title: String
    var showBackButton: Bool = true
    var backAction: (() -> Void)? = nil
    var trailingContent: AnyView? = nil
    
    var body: some View {
        HStack {
            if showBackButton {
                Button(action: { backAction?() }) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.textSecondary)
                        .frame(width: 44, height: 44)
                }
            } else {
                Spacer().frame(width: 44)
            }
            
            Spacer()
            
            Text(title)
                .font(.system(size: FontSize.h4, weight: .semibold))
                .foregroundColor(.textPrimary)
            
            Spacer()
            
            if let trailing = trailingContent {
                trailing
            } else {
                Spacer().frame(width: 44)
            }
        }
        .padding(.horizontal, LayoutConstants.padding4)
        .padding(.vertical, LayoutConstants.padding3)
        .background(Color.white)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(.borderColor),
            alignment: .bottom
        )
    }
}

// MARK: - Dashboard Header with Logo
struct LogoHeader: View {
    var body: some View {
        HStack {
            HStack(spacing: 10) {
                Image("logo-mint") // Will need this asset
                    .resizable()
                    .scaledToFit()
                    .frame(height: 28)
                
                Text("MintCheck")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.textPrimary)
            }
            
            Spacer()
        }
        .padding(.horizontal, LayoutConstants.padding6)
        .padding(.vertical, LayoutConstants.padding4)
        .background(Color.white)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(.borderColor),
            alignment: .bottom
        )
    }
}

// MARK: - Results Header
struct ResultsHeader: View {
    let title: String
    let subtitle: String
    var onShare: (() -> Void)? = nil
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: FontSize.h3, weight: .semibold))
                    .foregroundColor(.textPrimary)
                
                Text(subtitle)
                    .font(.system(size: FontSize.bodyRegular))
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            if let share = onShare {
                Button(action: share) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18))
                        .foregroundColor(.textSecondary)
                        .frame(width: 44, height: 44)
                }
            }
        }
        .padding(.horizontal, LayoutConstants.padding6)
        .padding(.vertical, LayoutConstants.padding5)
        .background(Color.white)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(.borderColor),
            alignment: .bottom
        )
    }
}

// MARK: - Progress Header (for multi-step flows)
struct ProgressHeader: View {
    let title: String
    let step: Int
    let totalSteps: Int
    var backAction: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                if let back = backAction {
                    Button(action: back) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.textSecondary)
                            .frame(width: 44, height: 44)
                    }
                } else {
                    Spacer().frame(width: 44)
                }
                
                Spacer()
                
                Text(title)
                    .font(.system(size: FontSize.h4, weight: .semibold))
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                Spacer().frame(width: 44)
            }
            .padding(.horizontal, LayoutConstants.padding4)
            .padding(.vertical, LayoutConstants.padding3)
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.borderColor)
                        .frame(height: 2)
                    
                    Rectangle()
                        .fill(Color.mintGreen)
                        .frame(width: geometry.size.width * CGFloat(step) / CGFloat(totalSteps), height: 2)
                }
            }
            .frame(height: 2)
        }
        .background(Color.white)
    }
}

#Preview {
    VStack(spacing: 0) {
        ScreenHeader(title: "Connect Scanner", backAction: {})
        
        Spacer().frame(height: 20)
        
        LogoHeader()
        
        Spacer().frame(height: 20)
        
        ResultsHeader(title: "Vehicle Scan Report", subtitle: "2018 Honda Accord", onShare: {})
        
        Spacer().frame(height: 20)
        
        ProgressHeader(title: "Vehicle Details", step: 1, totalSteps: 3, backAction: {})
        
        Spacer()
    }
    .background(Color.deepBackground)
}
