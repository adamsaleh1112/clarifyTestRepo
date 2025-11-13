import SwiftUI
import UIKit
import Foundation

struct SelectableTextView: UIViewRepresentable {
    let text: String
    let font: UIFont
    let textColor: UIColor
    let lineSpacing: CGFloat
    @Binding var selectedText: String
    @Binding var selectedRange: NSRange
    var onTextSelected: (() -> Void)? = nil
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.isEditable = false
        textView.isSelectable = true
        textView.isScrollEnabled = false
        textView.backgroundColor = UIColor.clear
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainerInset = UIEdgeInsets.zero
        
        // Configure text with attributes
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing
        
        let attributedString = NSAttributedString(
            string: text,
            attributes: [
                .font: font,
                .foregroundColor: textColor,
                .paragraphStyle: paragraphStyle
            ]
        )
        
        textView.attributedText = attributedString
        
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        // Update text color and font if needed
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing
        
        let attributedString = NSAttributedString(
            string: text,
            attributes: [
                .font: font,
                .foregroundColor: textColor,
                .paragraphStyle: paragraphStyle
            ]
        )
        
        uiView.attributedText = attributedString
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        let parent: SelectableTextView
        
        init(_ parent: SelectableTextView) {
            self.parent = parent
        }
        
        func textViewDidChangeSelection(_ textView: UITextView) {
            let selectedRange = textView.selectedRange
            if selectedRange.length > 0 {
                let selectedText = (textView.text as NSString).substring(with: selectedRange)
                DispatchQueue.main.async {
                    self.parent.selectedText = selectedText
                    self.parent.selectedRange = selectedRange
                    self.parent.onTextSelected?()
                }
            }
        }
    }
}
