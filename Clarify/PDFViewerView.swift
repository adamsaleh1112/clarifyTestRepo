import SwiftUI
import PDFKit

struct PDFViewerView: View {
    let pdfURL: URL
    let fileName: String
    let pdfTextContent: String?
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode
    @State private var showAIChat = false
    
    var body: some View {
        ZStack {
            // Background
            (colorScheme == .dark ? Color.themeBackgroundDark : Color.themeBackground)
                .ignoresSafeArea()
            
            // PDF Content
            PDFKitView(url: pdfURL)
                .ignoresSafeArea(.container, edges: .bottom)
            
            // Floating Navigation Buttons
            VStack {
                HStack {
                    // Back Button (Left)
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(colorScheme == .dark ? Color.themeWhiteDark : Color.themeBlack)
                            .frame(width: 44, height: 44)
                            .background(colorScheme == .dark ? Color.themeRaisedDark : Color.themeRaised)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(colorScheme == .dark ? Color.themeStrokeDark : Color.themeStroke, lineWidth: 0.5)
                            )
                            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                    }
                    
                    Spacer()
                }
                
                Spacer()
                
                // AI Companion Button (Bottom Right)
                HStack {
                    Spacer()
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showAIChat = true
                        }
                    } label: {
                        Image("clarify-logo")
                            .renderingMode(.template)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 32, height: 32)
                            .foregroundColor(colorScheme == .dark ? Color.themeBlack : Color.themeWhiteDark)
                            .frame(width: 70, height: 70)
                            .background(colorScheme == .dark ? Color.themeWhiteDark : Color.themeBlack)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 6)
                    }
                }
                .padding(.bottom, 35)
            }
            .padding(.horizontal, 26)
            .padding(.top, 20)
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showAIChat) {
            AIChatView(
                articleTitle: fileName,
                articleContent: pdfTextContent ?? "PDF Document: \(fileName)"
            )
        }
    }
}

struct PDFKitView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = PDFDocument(url: url)
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
        // Update if needed
    }
}

struct PDFViewerView_Previews: PreviewProvider {
    static var previews: some View {
        if let sampleURL = Bundle.main.url(forResource: "sample", withExtension: "pdf") {
            PDFViewerView(pdfURL: sampleURL, fileName: "Sample PDF", pdfTextContent: "Sample PDF content for preview")
        } else {
            Text("No sample PDF found")
        }
    }
}
