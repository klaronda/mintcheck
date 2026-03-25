//
//  SupportView.swift
//  MintCheck
//
//  Help and support articles
//

import SwiftUI

struct SupportView: View {
    @State private var selectedArticle: SupportArticle? = nil
    @State private var showOBDHelp = false
    let onMenuTap: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Support")
                        .font(.system(size: FontSize.h2, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    
                    Text("Find answers to common questions")
                        .font(.system(size: FontSize.bodyRegular))
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                Button(action: onMenuTap) {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.mintGreen)
                        .padding(8)
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background(Color.white)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.borderColor),
                alignment: .bottom
            )
            
            // Content
            ScrollView {
                VStack(spacing: 16) {
                    // OBD-II Port article (uses shared OBDHelpSheet)
                    SupportArticleCard(
                        article: SupportArticle(
                            id: "obd-port",
                            title: "Finding your OBD-II port",
                            content: ""
                        ),
                        onViewArticle: {
                            showOBDHelp = true
                        }
                    )
                    
                    // Other articles
                    ForEach(supportArticles) { article in
                        SupportArticleCard(
                            article: article,
                            onViewArticle: {
                                selectedArticle = article
                            }
                        )
                    }
                    
                    // Contact support
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Need more help?")
                            .font(.system(size: FontSize.h4, weight: .semibold))
                            .foregroundColor(.textPrimary)
                        
                        Text("Contact us at support@mintcheckapp.com and we'll get back to you within 24 hours.")
                            .font(.system(size: FontSize.bodyRegular))
                            .foregroundColor(.textSecondary)
                            .lineSpacing(4)
                        
                        // Email button
                        if let emailURL = URL(string: "mailto:support@mintcheckapp.com") {
                            Link(destination: emailURL) {
                                HStack {
                                    Image(systemName: "envelope")
                                        .font(.system(size: 14))
                                    Text("Email Support")
                                        .font(.system(size: FontSize.bodyRegular, weight: .medium))
                                }
                                .foregroundColor(.mintGreen)
                            }
                        }
                    }
                    .padding(LayoutConstants.padding6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white)
                    .cornerRadius(LayoutConstants.borderRadiusLarge)
                    .overlay(
                        RoundedRectangle(cornerRadius: LayoutConstants.borderRadiusLarge)
                            .stroke(Color.borderColor, lineWidth: 1)
                    )
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 120)
            }
        }
        .background(Color.deepBackground)
        .sheet(isPresented: $showOBDHelp) {
            // Reuse the exact same OBDHelpSheet from DeviceConnectionView
            OBDHelpSheet()
        }
        .sheet(item: $selectedArticle) { article in
            SupportArticleDetailView(
                article: article,
                onDone: {
                    selectedArticle = nil
                }
            )
        }
    }
    
    // MARK: - Support Articles Data
    
    private var supportArticles: [SupportArticle] {
        [
            SupportArticle(
                id: "where-to-get-scanner",
                title: "Where to get an OBD-II WiFi Scanner",
                content: """
                To use MintCheck, you need an OBD-II WiFi scanner. It's a small device that plugs into your car's diagnostic port and sends data to your phone over WiFi.

                **MintCheck Starter Kit (recommended)**

                Get our tested Wi-Fi scanner plus a 60-day Buyer Pass in one bundle. [Shop the Starter Kit](https://mintcheckapp.com/starter-kit).

                **Our MintCheck-Tested Pick (scanner only)**

                WiFi ELM327 Generic Scanner — about $20 on Amazon.

                This is the scanner we test with and recommend. It's affordable, reliable, and works great with MintCheck. [Buy it here](https://www.amazon.com/dp/B0BRKJ38ZQ?tag=mintcheck-20).

                **Will other scanners work?**

                Yes. Any ELM327-compatible WiFi OBD-II scanner should work with MintCheck. Just make sure it connects via WiFi (not Bluetooth). You can find them online for $15–30.
                """
            ),
            SupportArticle(
                id: "connect-scanner",
                title: "How to connect your OBD-II scanner",
                content: """
                Follow these steps to connect your OBD-II scanner and start a vehicle scan:
                
                **Step 1: Locate the OBD-II port**
                Find the port under the dashboard on the driver's side. See our "Finding your OBD-II port" article for detailed instructions.
                
                **Step 2: Plug in the scanner**
                Insert your OBD-II scanner firmly into the port. It should click into place.
                
                **Step 3: Turn on the ignition**
                Turn your vehicle's ignition to the "ON" position. The engine does not need to be running for most scans.
                
                **Step 4: Connect to the scanner**
                
                For WiFi scanners:
                - Open your phone's Settings
                - Go to WiFi settings
                - Connect to the scanner's network (usually named "OBDII", "WiFi_OBD", or similar)
                - Return to MintCheck
                
                For Bluetooth scanners:
                - Bluetooth car scanners are not currently supported by the MintCheck app.
                
                **Step 5: Start the scan**
                Tap "Start Scan" in MintCheck to begin the diagnostic check. The scan typically takes 30-60 seconds.
                
                **Troubleshooting:**
                - Make sure the scanner is fully inserted
                - Ensure the ignition is on (not just accessories)
                - Try reconnecting to the scanner's Wi-Fi
                - If MintCheck can't reach your scanner, open **Settings** → **MintCheck**, turn on **Local Network**, or tap **Allow** when iOS asks during a scan
                - Restart the scanner by unplugging and re-plugging it
                """
            ),
            SupportArticle(
                id: "understanding-results",
                title: "Understanding your scan results",
                content: """
                After scanning a vehicle, MintCheck provides a comprehensive health report. Here's how to interpret your results:
                
                **Overall Recommendation**
                
                [[RECOMMENDATION_BADGES]]
                
                Safe (Green): No significant issues detected. The vehicle's systems appear to be in good working order.
                
                Caution (Yellow): Some concerns were found that warrant attention. Review the details carefully before making a decision.
                
                Walk Away (Red): Significant issues detected. We recommend not purchasing this vehicle without a professional inspection or further investigation.
                
                **What We Found**
                This section summarizes the key findings from the scan, including:
                - Diagnostic trouble codes (DTCs) if any
                - Whether codes were recently cleared
                - Estimated repair costs for any issues
                
                **System Details**
                Detailed information about each vehicle system:
                - Engine: RPM, load, temperatures
                - Fuel System: Fuel trims, fuel system status
                - Emissions: Readiness monitors, oxygen sensors
                - Electrical: Battery voltage, system status
                
                **Vehicle Details**
                Information about the vehicle including:
                - Make, model, and year
                - VIN (if provided)
                - Fuel type and engine specifications
                
                **More Model Details**
                Free safety information from NHTSA including:
                - Active recalls for this vehicle
                - Crash test safety ratings
                """
            ),
            SupportArticle(
                id: "trouble-codes",
                title: "What are trouble codes (DTCs)?",
                content: """
                Diagnostic Trouble Codes (DTCs) are standardized codes stored by your vehicle's computer when it detects a malfunction.
                
                **Understanding code prefixes:**
                
                P-codes (Powertrain): Engine, transmission, and drivetrain issues. These are the most common codes.
                
                B-codes (Body): Issues with body systems like airbags, seat belts, and interior electronics.
                
                C-codes (Chassis): Problems with ABS, traction control, and suspension systems.
                
                U-codes (Network): Communication issues between the vehicle's computer modules.
                
                **Code severity:**
                
                Not all codes are equally serious:
                - Some indicate minor issues that don't affect drivability
                - Others point to significant problems requiring immediate attention
                - Multiple related codes may indicate a single underlying issue
                
                **What MintCheck provides:**
                
                When we find trouble codes, we show:
                - The code number and description
                - Estimated repair cost range
                - Severity level (how urgent the repair is)
                
                **Important note:**
                
                A code indicates a system malfunction was detected, but doesn't always pinpoint the exact failed component. Professional diagnosis may be needed for complex issues.
                """
            ),
            SupportArticle(
                id: "recently-cleared",
                title: "Why does it say 'codes recently cleared'?",
                content: """
                When MintCheck detects that diagnostic codes were recently cleared, it means someone reset the vehicle's onboard computer memory.
                
                **Why this matters:**
                
                Clearing codes erases the vehicle's diagnostic history, which could hide:
                - Previous warning lights or problems
                - Recurring issues that keep coming back
                - Problems the seller may not have disclosed
                
                **Legitimate reasons for clearing codes:**
                
                - After completing a repair (normal practice)
                - After disconnecting the battery
                - Following a recent service appointment
                
                **Potentially concerning reasons:**
                
                - Hiding problems before a sale
                - Temporarily turning off the check engine light
                - Avoiding disclosure of known issues
                
                **What to do:**
                
                1. Ask the seller directly why codes were cleared
                2. Request service records showing recent repairs
                3. Consider having the vehicle inspected by a mechanic
                4. Drive the vehicle for a few days if possible - problems often resurface
                
                **Our recommendation:**
                
                We flag "recently cleared codes" as a caution because you can't see the full diagnostic history. It's not automatically a red flag, but it warrants additional questions before purchasing.
                """
            ),
            SupportArticle(
                id: "faq",
                title: "Frequently Asked Questions",
                content: """
                **Do I need a special scanner?**
                Any ELM327-compatible OBD-II scanner will work with MintCheck. We recommend WiFi scanners for the easiest connection experience. You can find compatible scanners for $15-30 online.
                
                **Will this work on any car?**
                MintCheck works with all vehicles from 1996 and newer sold in the United States. All these vehicles are required by law to have standardized OBD-II ports.
                
                **How accurate are the scan results?**
                The diagnostic data comes directly from the vehicle's computer, so it's as accurate as what a mechanic would see. The information reflects the current state of the vehicle's systems.
                
                **Can I scan my own car?**
                Absolutely! MintCheck is great for monitoring your own vehicle's health, not just for buying used cars. Regular scans can help you catch issues early.
                
                **How long does a scan take?**
                A typical scan takes 30-60 seconds. Some vehicles may take slightly longer depending on how many systems need to be checked.
                
                **What if the scan finds problems?**
                Review the details carefully. For minor issues, you may choose to proceed with the purchase and address them later. For significant problems, consider negotiating the price or walking away.
                
                **Do scans expire?**
                Scan results are kept for 180 days. After that, they're automatically deleted. You can always run a new scan on a vehicle.
                
                **Can I share my scan results?**
                Yes. From your results screen, tap **Share Report** once the scan has finished saving. You can email the report to yourself or anyone else (with an optional message) and optionally create a **shareable link** to a web page at mintcheckapp.com—recipients don't need the MintCheck app to view it. The page shows how fresh the scan is; for sharing with a seller or lender, it's best while the scan is still **current** (about two weeks from the scan date). If sending fails right after a scan, wait a moment and try again. You can manage shared links from **Settings** while signed in.
                
                **What is Buyer Pass?**
                Buyer Pass is a **60-day** subscription for shopping multiple used cars: up to **10 full scans per calendar day** (resets each day) and you can scan **different vehicles**—not limited to one car like the free tier. **$14.99** via secure checkout in the app. When your pass activates, your daily scan count typically starts fresh for that day.
                
                **What is a one-time scan?**
                If you've used your **free scans** and only need **one more** engine health check without a pass, you can buy a **single scan** for **$3.99** (In-App Purchase) from the dashboard. The credit applies the next time you start a scan.
                
                **What is Deep Check?**
                Deep Check is an **add-on** (separate from the OBD scan): you enter a **VIN** and get a **vehicle history–style report** in the browser—things like title signals, accident history, and recalls where data is available. **$9.99.** It complements your MintCheck scan; it doesn't replace a hands-on mechanical inspection.
                """
            )
        ]
    }
}

// MARK: - Support Article Model

struct SupportArticle: Identifiable {
    let id: String
    let title: String
    let content: String
}

// MARK: - Support Article Card

struct SupportArticleCard: View {
    let article: SupportArticle
    let onViewArticle: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(article.title)
                .font(.system(size: FontSize.bodyLarge, weight: .medium))
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.leading)
            
            Button(action: onViewArticle) {
                HStack(spacing: 4) {
                    Text("View Article")
                        .font(.system(size: FontSize.bodyRegular, weight: .medium))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(.mintGreen)
            }
        }
        .padding(LayoutConstants.padding6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(LayoutConstants.borderRadiusLarge)
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.borderRadiusLarge)
                .stroke(Color.borderColor, lineWidth: 1)
        )
    }
}

// MARK: - Content Block Model

enum ContentBlock: Identifiable {
    case heading(String)
    case paragraph(String)
    case bulletList([String])
    case numberedList([String])
    case recommendationBadges
    
    var id: String {
        switch self {
        case .heading(let text): return "heading-\(text)"
        case .paragraph(let text): return "paragraph-\(text.prefix(20))"
        case .bulletList(let items): return "bullet-\(items.count)"
        case .numberedList(let items): return "numbered-\(items.count)"
        case .recommendationBadges: return "recommendation-badges"
        }
    }
}

// MARK: - Support Article Detail View

struct SupportArticleDetailView: View {
    let article: SupportArticle
    let onDone: () -> Void
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Render content with improved markdown parsing
                    ForEach(parseContent(article.content)) { block in
                        renderBlock(block)
                    }
                }
                .padding(24)
            }
            .background(Color.deepBackground)
            .navigationTitle(article.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: FontSize.bodyLarge, weight: .semibold))
                    .foregroundColor(.mintGreen)
                }
            }
        }
    }
    
    @ViewBuilder
    private func renderBlock(_ block: ContentBlock) -> some View {
        switch block {
        case .heading(let text):
            Text(text)
                .font(.system(size: FontSize.h5, weight: .semibold))
                .foregroundColor(.textPrimary)
                .padding(.top, 8)
        
        case .paragraph(let text):
            paragraphBlockView(text.trimmingCharacters(in: .whitespaces))
        
        case .bulletList(let items):
            VStack(alignment: .leading, spacing: 8) {
                ForEach(items, id: \.self) { item in
                    BulletPoint(text: item.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "- ", with: ""))
                }
            }
        
        case .numberedList(let items):
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    NumberedListItem(number: index + 1, text: item.trimmingCharacters(in: .whitespaces))
                }
            }
        
        case .recommendationBadges:
            VStack(alignment: .leading, spacing: 10) {
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
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private func parseContent(_ content: String) -> [ContentBlock] {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        var blocks: [ContentBlock] = []
        
        // Split by double newlines to get major sections
        let sections = trimmedContent.components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        for section in sections {
            if section == "[[RECOMMENDATION_BADGES]]" {
                blocks.append(.recommendationBadges)
                continue
            }
            
            let lines = section.components(separatedBy: "\n")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            
            if lines.isEmpty { continue }
            
            var currentIndex = 0
            
            while currentIndex < lines.count {
                let line = lines[currentIndex]
                
                // Check for heading (line starting and ending with **)
                if line.hasPrefix("**") && line.hasSuffix("**") && line.count > 4 {
                    let headingText = line.replacingOccurrences(of: "**", with: "")
                    blocks.append(.heading(headingText))
                    currentIndex += 1
                    // Continue processing remaining lines in this section
                    continue
                }
                
                // Check if we're starting a list
                let isNumberedList = line.range(of: #"^\d+\.\s"#, options: .regularExpression) != nil
                let isBulletList = line.hasPrefix("- ")
                
                if isNumberedList {
                    // Collect all consecutive numbered items
                    var numberedItems: [String] = []
                    while currentIndex < lines.count {
                        let currentLine = lines[currentIndex]
                        if let numberMatch = currentLine.range(of: #"^\d+\.\s"#, options: .regularExpression) {
                            let itemText = String(currentLine[numberMatch.upperBound...])
                            numberedItems.append(itemText)
                            currentIndex += 1
                        } else {
                            break
                        }
                    }
                    if !numberedItems.isEmpty {
                        blocks.append(.numberedList(numberedItems))
                    }
                } else if isBulletList {
                    // Collect all consecutive bullet items
                    var bulletItems: [String] = []
                    while currentIndex < lines.count {
                        let currentLine = lines[currentIndex]
                        if currentLine.hasPrefix("- ") {
                            bulletItems.append(currentLine)
                            currentIndex += 1
                        } else {
                            break
                        }
                    }
                    if !bulletItems.isEmpty {
                        blocks.append(.bulletList(bulletItems))
                    }
                } else {
                    // Collect consecutive paragraph lines
                    var paragraphLines: [String] = []
                    while currentIndex < lines.count {
                        let currentLine = lines[currentIndex]
                        let isNumbered = currentLine.range(of: #"^\d+\.\s"#, options: .regularExpression) != nil
                        let isBullet = currentLine.hasPrefix("- ")
                        let isHeading = currentLine.hasPrefix("**") && currentLine.hasSuffix("**")
                        
                        if isNumbered || isBullet || isHeading {
                            break
                        }
                        paragraphLines.append(currentLine)
                        currentIndex += 1
                    }
                    if !paragraphLines.isEmpty {
                        let paragraphText = paragraphLines.joined(separator: " ")
                        blocks.append(.paragraph(paragraphText))
                    }
                }
            }
        }
        
        return blocks
    }
    
    /// Renders markdown-style links and inline bold in paragraphs; falls back to plain text if parsing fails.
    @ViewBuilder
    private func paragraphBlockView(_ text: String) -> some View {
        if let attributed = try? AttributedString(
            markdown: text,
            options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        ) {
            Text(attributed)
                .font(.system(size: FontSize.bodyLarge))
                .foregroundColor(.textSecondary)
                .tint(.mintGreen)
                .lineSpacing(4)
        } else {
            Text(text.replacingOccurrences(of: "**", with: ""))
                .font(.system(size: FontSize.bodyLarge))
                .foregroundColor(.textSecondary)
                .lineSpacing(4)
        }
    }
}

// MARK: - Numbered List Item Component

struct NumberedListItem: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(number).")
                .font(.system(size: FontSize.bodyLarge, weight: .semibold))
                .foregroundColor(.textSecondary)
                .frame(width: 24, alignment: .trailing)
            
            Text(text)
                .font(.system(size: FontSize.bodyLarge))
                .foregroundColor(.textSecondary)
        }
    }
}

#Preview {
    SupportView(onMenuTap: {})
}
