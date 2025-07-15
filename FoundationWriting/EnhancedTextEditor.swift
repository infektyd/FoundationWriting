//
//  EnhancedTextEditor.swift
//  FoundationWriting
//
//  Created by Hans Axelsson on 7/15/25.
//
import SwiftUI
import AppKit

/// Enhanced text editor with real-time highlighting and contextual feedback
struct EnhancedTextEditor: NSViewRepresentable {
    @Binding var text: String
    @Binding var highlights: [TextHighlight]
    
    let onTextChange: (String) -> Void
    let onHighlightHover: (TextHighlight?) -> Void
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        let textView = HighlightableTextView()
        
        textView.delegate = context.coordinator
        textView.isRichText = false
        textView.font = .systemFont(ofSize: 14)
        textView.textColor = .labelColor
        textView.backgroundColor = .clear
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isContinuousSpellCheckingEnabled = false
        
        // Configure scroll view
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.documentView = textView
        scrollView.backgroundColor = .clear
        
        // Set up text view constraints
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = CGSize(width: scrollView.contentSize.width, height: .greatestFiniteMagnitude)
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? HighlightableTextView else { return }
        
        // Update text if needed
        if textView.string != text {
            textView.string = text
        }
        
        // Update highlights
        textView.updateHighlights(highlights)
        context.coordinator.onHighlightHover = onHighlightHover
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        let parent: EnhancedTextEditor
        var onHighlightHover: (TextHighlight?) -> Void = { _ in }
        
        init(_ parent: EnhancedTextEditor) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            
            DispatchQueue.main.async {
                self.parent.text = textView.string
                self.parent.onTextChange(textView.string)
            }
        }
    }
}

/// Custom NSTextView that supports highlighting and hover interactions
class HighlightableTextView: NSTextView {
    private var highlights: [TextHighlight] = []
    private var highlightViews: [NSView] = []
    private var trackingArea: NSTrackingArea?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupTrackingArea()
    }
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        setupTrackingArea()
    }
    
    private func setupTrackingArea() {
        if let trackingArea = trackingArea {
            removeTrackingArea(trackingArea)
        }
        
        trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.activeInKeyWindow, .mouseMoved, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        
        if let trackingArea = trackingArea {
            addTrackingArea(trackingArea)
        }
    }
    
    func updateHighlights(_ newHighlights: [TextHighlight]) {
        highlights = newHighlights
        redrawHighlights()
    }
    
    private func redrawHighlights() {
        // Remove existing highlight views
        highlightViews.forEach { $0.removeFromSuperview() }
        highlightViews.removeAll()
        
        // Add new highlights
        for highlight in highlights {
            addHighlightView(for: highlight)
        }
    }
    
    private func addHighlightView(for highlight: TextHighlight) {
        guard let layoutManager = layoutManager,
              let textContainer = textContainer else { return }
        
        // Get glyph range for the highlight
        let glyphRange = layoutManager.glyphRange(forCharacterRange: highlight.range, actualCharacterRange: nil)
        
        // Get bounding rect for the glyph range
        let boundingRect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
        
        // Create highlight view
        let highlightView = NSView(frame: boundingRect)
        highlightView.wantsLayer = true
        highlightView.layer?.backgroundColor = NSColor(named: highlight.type.color)?.withAlphaComponent(highlight.type.opacity).cgColor
        highlightView.layer?.cornerRadius = 3
        
        // Add to text view
        addSubview(highlightView, positioned: .below, relativeTo: nil)
        highlightViews.append(highlightView)
    }
    
    override func mouseMoved(with event: NSEvent) {
        super.mouseMoved(with: event)
        
        let locationInView = convert(event.locationInWindow, from: nil)
        let characterIndex = characterIndexForInsertion(at: locationInView)
        
        // Find highlight at current position
        let hoveredHighlight = highlights.first { highlight in
            NSLocationInRange(characterIndex, highlight.range)
        }
        
        // Notify delegate about hover
        if let coordinator = delegate as? EnhancedTextEditor.Coordinator {
            coordinator.onHighlightHover(hoveredHighlight)
        }
        
        // Update cursor
        if hoveredHighlight != nil {
            NSCursor.pointingHand.set()
        } else {
            NSCursor.iBeam.set()
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        
        // Clear hover state
        if let coordinator = delegate as? EnhancedTextEditor.Coordinator {
            coordinator.onHighlightHover(nil)
        }
        
        NSCursor.iBeam.set()
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // Ensure highlights are properly positioned
        redrawHighlights()
    }
}