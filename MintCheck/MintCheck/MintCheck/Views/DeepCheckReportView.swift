//
//  DeepCheckReportView.swift
//  MintCheck
//
//  In-app WebView for a single Deep Vehicle Check report (no Safari).
//

import SwiftUI
import WebKit

struct DeepCheckReportView: View {
    let url: URL
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(
                title: "Deep Vehicle Check",
                showBackButton: false,
                backAction: nil,
                trailingContent: AnyView(
                    Button("Done") {
                        onDone()
                    }
                    .font(.system(size: FontSize.bodyRegular, weight: .semibold))
                    .foregroundColor(.mintGreen)
                )
            )
            WebViewRepresentable(url: url)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.deepBackground)
        }
        .background(Color.deepBackground)
    }
}

// MARK: - WKWebView wrapper
private struct WebViewRepresentable: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

#Preview {
    DeepCheckReportView(
        url: URL(string: "https://mintcheckapp.com/deep-check/report/test")!,
        onDone: {}
    )
}
