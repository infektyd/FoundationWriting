//
//  PDFReportGenerator.swift
//  FoundationWriting
//
//  Created by Hans Axelsson on 7/15/25.
//
import Foundation
import AppKit
import PDFKit
import CoreGraphics

/// Generates professional PDF reports for writing analysis
class PDFReportGenerator {
    private let data: ExportData
    private let pageSize = CGSize(width: 612, height: 792) // US Letter
    private let margin: CGFloat = 72 // 1 inch margins
    
    // Typography
    private let titleFont = NSFont.systemFont(ofSize: 24, weight: .bold)
    private let headingFont = NSFont.systemFont(ofSize: 18, weight: .semibold)
    private let subheadingFont = NSFont.systemFont(ofSize: 14, weight: .medium)
    private let bodyFont = NSFont.systemFont(ofSize: 12, weight: .regular)
    private let captionFont = NSFont.systemFont(ofSize: 10, weight: .regular)
    
    // Colors
    private let primaryColor = NSColor.systemBlue
    private let secondaryColor = NSColor.secondaryLabelColor
    private let accentColor = NSColor.systemGreen
    
    init(data: ExportData) {
        self.data = data
    }
    
    func generateReport() async throws -> PDFDocument {
        let pdfDocument = PDFDocument()
        var currentPage = 1
        
        // Page 1: Cover page and summary
        let coverPage = try await generateCoverPage()
        pdfDocument.insert(coverPage, at: currentPage - 1)
        currentPage += 1
        
        // Page 2: Detailed analysis
        let analysisPage = try await generateAnalysisPage()
        pdfDocument.insert(analysisPage, at: currentPage - 1)
        currentPage += 1
        
        // Page 3: Improvement suggestions
        if !data.analysis.improvementSuggestions.isEmpty {
            let suggestionsPage = try await generateSuggestionsPage()
            pdfDocument.insert(suggestionsPage, at: currentPage - 1)
            currentPage += 1
        }
        
        // Page 4: Learning roadmap (if available)
        if let roadmap = data.roadmap {
            let roadmapPage = try await generateRoadmapPage(roadmap)
            pdfDocument.insert(roadmapPage, at: currentPage - 1)
            currentPage += 1
        }
        
        // Page 5: Original text (if included)
        if data.settings.includeOriginalText && !data.originalText.isEmpty {
            let textPage = try await generateOriginalTextPage()
            pdfDocument.insert(textPage, at: currentPage - 1)
        }
        
        return pdfDocument
    }
    
    // MARK: - Page Generation
    
    private func generateCoverPage() async throws -> PDFPage {
        let page = PDFPage()
        
        let context = createPDFContext()
        
        var yPosition = pageSize.height - margin - 100
        
        // Title
        let titleRect = CGRect(x: margin, y: yPosition, width: pageSize.width - 2 * margin, height: 60)
        drawText("Writing Analysis Report", in: titleRect, font: titleFont, color: primaryColor, context: context)
        yPosition -= 80
        
        // Subtitle with date
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        
        let subtitleText = "Generated on \(dateFormatter.string(from: data.generatedAt))"
        let subtitleRect = CGRect(x: margin, y: yPosition, width: pageSize.width - 2 * margin, height: 30)
        drawText(subtitleText, in: subtitleRect, font: subheadingFont, color: secondaryColor, context: context)
        yPosition -= 100
        
        // Summary box
        let summaryBoxRect = CGRect(x: margin, y: yPosition - 200, width: pageSize.width - 2 * margin, height: 200)
        drawRoundedRect(summaryBoxRect, cornerRadius: 12, fillColor: NSColor.controlBackgroundColor, context: context)
        
        // Summary content
        var summaryY = yPosition - 40
        
        drawText("Analysis Summary", in: CGRect(x: margin + 20, y: summaryY, width: pageSize.width - 2 * margin - 40, height: 30), font: headingFont, color: primaryColor, context: context)
        summaryY -= 40
        
        // Key metrics
        let metrics = data.analysis.metrics
        let metricsText = """
        Readability Level: \(metrics.fleschKincaidLabel) (Grade \(String(format: "%.1f", metrics.fleschKincaidGrade)))
        Average Sentence Length: \(String(format: "%.1f", metrics.averageSentenceLength)) words
        Vocabulary Diversity: \(String(format: "%.0f%%", metrics.vocabularyDiversity * 100))
        Improvement Areas: \(data.analysis.improvementSuggestions.count) suggestions
        """
        
        let metricsRect = CGRect(x: margin + 20, y: summaryY - 100, width: pageSize.width - 2 * margin - 40, height: 100)
        drawText(metricsText, in: metricsRect, font: bodyFont, color: .labelColor, context: context)
        
        // Footer
        let footerText = "Writing Coach App • Enhanced by Foundation Models"
        let footerRect = CGRect(x: margin, y: 50, width: pageSize.width - 2 * margin, height: 20)
        drawText(footerText, in: footerRect, font: captionFont, color: secondaryColor, context: context, alignment: .center)
        
        context.endPDFPage()
        
        if let data = context.closePDF() {
            page.setValue(data, forAnnotationKey: .contents)
        }
        
        return page
    }
    
    private func generateAnalysisPage() async throws -> PDFPage {
        let page = PDFPage()
        let context = createPDFContext()
        
        var yPosition = pageSize.height - margin - 40
        
        // Page title
        let titleRect = CGRect(x: margin, y: yPosition, width: pageSize.width - 2 * margin, height: 40)
        drawText("Detailed Analysis", in: titleRect, font: headingFont, color: primaryColor, context: context)
        yPosition -= 60
        
        // Overall assessment
        let assessmentTitleRect = CGRect(x: margin, y: yPosition, width: pageSize.width - 2 * margin, height: 25)
        drawText("Overall Assessment", in: assessmentTitleRect, font: subheadingFont, color: .labelColor, context: context)
        yPosition -= 35
        
        let assessmentRect = CGRect(x: margin, y: yPosition - 80, width: pageSize.width - 2 * margin, height: 80)
        drawRoundedRect(assessmentRect, cornerRadius: 8, fillColor: NSColor.controlBackgroundColor, context: context)
        
        let assessmentTextRect = CGRect(x: margin + 15, y: yPosition - 70, width: pageSize.width - 2 * margin - 30, height: 60)
        drawText(data.analysis.assessment, in: assessmentTextRect, font: bodyFont, color: .labelColor, context: context)
        yPosition -= 120
        
        // Readability metrics
        let metricsTitleRect = CGRect(x: margin, y: yPosition, width: pageSize.width - 2 * margin, height: 25)
        drawText("Readability Metrics", in: metricsTitleRect, font: subheadingFont, color: .labelColor, context: context)
        yPosition -= 35
        
        let metricsBoxRect = CGRect(x: margin, y: yPosition - 120, width: pageSize.width - 2 * margin, height: 120)
        drawRoundedRect(metricsBoxRect, cornerRadius: 8, fillColor: NSColor.controlBackgroundColor, context: context)
        
        // Draw metrics in columns
        drawMetricsTable(in: metricsBoxRect, context: context)
        yPosition -= 160
        
        // Methodology
        let methodologyTitleRect = CGRect(x: margin, y: yPosition, width: pageSize.width - 2 * margin, height: 25)
        drawText("Analysis Methodology", in: methodologyTitleRect, font: subheadingFont, color: .labelColor, context: context)
        yPosition -= 35
        
        let methodologyRect = CGRect(x: margin, y: yPosition - 60, width: pageSize.width - 2 * margin, height: 60)
        drawRoundedRect(methodologyRect, cornerRadius: 8, fillColor: NSColor.controlBackgroundColor, context: context)
        
        let methodologyTextRect = CGRect(x: margin + 15, y: yPosition - 50, width: pageSize.width - 2 * margin - 30, height: 40)
        drawText(data.analysis.methodology, in: methodologyTextRect, font: bodyFont, color: .labelColor, context: context)
        
        // Page number
        drawPageNumber(1, context: context)
        
        context.endPDFPage()
        
        if let data = context.closePDF() {
            page.setValue(data, forAnnotationKey: .contents)
        }
        
        return page
    }
    
    private func generateSuggestionsPage() async throws -> PDFPage {
        let page = PDFPage()
        let context = createPDFContext()
        
        var yPosition = pageSize.height - margin - 40
        
        // Page title
        let titleRect = CGRect(x: margin, y: yPosition, width: pageSize.width - 2 * margin, height: 40)
        drawText("Improvement Suggestions", in: titleRect, font: headingFont, color: primaryColor, context: context)
        yPosition -= 60
        
        // Suggestions
        for (index, suggestion) in data.analysis.improvementSuggestions.enumerated() {
            let suggestionHeight = drawSuggestion(suggestion, index: index + 1, at: yPosition, context: context)
            yPosition -= suggestionHeight + 20
            
            if yPosition < 150 { // Not enough space for another suggestion
                break
            }
        }
        
        // Page number
        drawPageNumber(2, context: context)
        
        context.endPDFPage()
        
        if let data = context.closePDF() {
            page.setValue(data, forAnnotationKey: .contents)
        }
        
        return page
    }
    
    private func generateRoadmapPage(_ roadmap: PersonalizedLearningRoadmap) async throws -> PDFPage {
        let page = PDFPage()
        let context = createPDFContext()
        
        var yPosition = pageSize.height - margin - 40
        
        // Page title
        let titleRect = CGRect(x: margin, y: yPosition, width: pageSize.width - 2 * margin, height: 40)
        drawText("Personalized Learning Roadmap", in: titleRect, font: headingFont, color: primaryColor, context: context)
        yPosition -= 60
        
        // Roadmap overview
        let overviewText = "Duration: \(formatDuration(roadmap.totalDuration)) • \(roadmap.modules.count) Learning Modules"
        let overviewRect = CGRect(x: margin, y: yPosition, width: pageSize.width - 2 * margin, height: 25)
        drawText(overviewText, in: overviewRect, font: subheadingFont, color: secondaryColor, context: context)
        yPosition -= 45
        
        // Learning modules
        for (index, module) in roadmap.modules.enumerated() {
            let moduleHeight = drawLearningModule(module, index: index + 1, at: yPosition, context: context)
            yPosition -= moduleHeight + 15
            
            if yPosition < 100 {
                break
            }
        }
        
        // Page number
        drawPageNumber(3, context: context)
        
        context.endPDFPage()
        
        if let data = context.closePDF() {
            page.setValue(data, forAnnotationKey: .contents)
        }
        
        return page
    }
    
    private func generateOriginalTextPage() async throws -> PDFPage {
        let page = PDFPage()
        let context = createPDFContext()
        
        var yPosition = pageSize.height - margin - 40
        
        // Page title
        let titleRect = CGRect(x: margin, y: yPosition, width: pageSize.width - 2 * margin, height: 40)
        drawText("Original Text", in: titleRect, font: headingFont, color: primaryColor, context: context)
        yPosition -= 60
        
        // Original text in a box
        let textBoxRect = CGRect(x: margin, y: 100, width: pageSize.width - 2 * margin, height: yPosition - 100)
        drawRoundedRect(textBoxRect, cornerRadius: 8, fillColor: NSColor.controlBackgroundColor, context: context)
        
        let textRect = CGRect(x: margin + 15, y: 115, width: pageSize.width - 2 * margin - 30, height: yPosition - 130)
        drawText(data.originalText, in: textRect, font: bodyFont, color: .labelColor, context: context)
        
        // Page number
        drawPageNumber(4, context: context)
        
        context.endPDFPage()
        
        if let data = context.closePDF() {
            page.setValue(data, forAnnotationKey: .contents)
        }
        
        return page
    }
    
    // MARK: - Drawing Helpers
    
    private func createPDFContext() -> CGContext {
        let pdfData = NSMutableData()
        let pdfConsumer = CGDataConsumer(data: pdfData)!
        let context = CGContext(consumer: pdfConsumer, mediaBox: nil, nil)!
        
        let mediaBox = CGRect(origin: .zero, size: pageSize)
        context.beginPDFPage(nil)
        
        return context
    }
    
    private func drawText(_ text: String, in rect: CGRect, font: NSFont, color: NSColor, context: CGContext, alignment: NSTextAlignment = .left) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment
        paragraphStyle.lineBreakMode = .byWordWrapping
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraphStyle
        ]
        
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        let frameSetter = CTFramesetterCreateWithAttributedString(attributedString)
        let path = CGPath(rect: rect, transform: nil)
        let frame = CTFramesetterCreateFrame(frameSetter, CFRangeMake(0, 0), path, nil)
        
        context.textMatrix = .identity
        context.translateBy(x: 0, y: pageSize.height)
        context.scaleBy(x: 1, y: -1)
        
        CTFrameDraw(frame, context)
        
        context.scaleBy(x: 1, y: -1)
        context.translateBy(x: 0, y: -pageSize.height)
    }
    
    private func drawRoundedRect(_ rect: CGRect, cornerRadius: CGFloat, fillColor: NSColor, context: CGContext) {
        let path = CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
        context.setFillColor(fillColor.cgColor)
        context.addPath(path)
        context.fillPath()
    }
    
    private func drawMetricsTable(in rect: CGRect, context: CGContext) {
        let metrics = data.analysis.metrics
        let leftColumnX = rect.minX + 20
        let rightColumnX = rect.minX + rect.width / 2 + 10
        let rowHeight: CGFloat = 25
        
        var currentY = rect.maxY - 30
        
        // First row
        drawText("Flesch-Kincaid Grade:", in: CGRect(x: leftColumnX, y: currentY, width: 150, height: rowHeight), font: bodyFont, color: .labelColor, context: context)
        drawText(String(format: "%.1f", metrics.fleschKincaidGrade), in: CGRect(x: leftColumnX + 150, y: currentY, width: 100, height: rowHeight), font: bodyFont, color: .labelColor, context: context)
        
        drawText("Reading Level:", in: CGRect(x: rightColumnX, y: currentY, width: 120, height: rowHeight), font: bodyFont, color: .labelColor, context: context)
        drawText(metrics.fleschKincaidLabel, in: CGRect(x: rightColumnX + 120, y: currentY, width: 100, height: rowHeight), font: bodyFont, color: .labelColor, context: context)
        
        currentY -= rowHeight
        
        // Second row
        drawText("Avg. Sentence Length:", in: CGRect(x: leftColumnX, y: currentY, width: 150, height: rowHeight), font: bodyFont, color: .labelColor, context: context)
        drawText(String(format: "%.1f words", metrics.averageSentenceLength), in: CGRect(x: leftColumnX + 150, y: currentY, width: 100, height: rowHeight), font: bodyFont, color: .labelColor, context: context)
        
        drawText("Vocabulary Diversity:", in: CGRect(x: rightColumnX, y: currentY, width: 120, height: rowHeight), font: bodyFont, color: .labelColor, context: context)
        drawText(String(format: "%.0f%%", metrics.vocabularyDiversity * 100), in: CGRect(x: rightColumnX + 120, y: currentY, width: 100, height: rowHeight), font: bodyFont, color: .labelColor, context: context)
    }
    
    private func drawSuggestion(_ suggestion: EnhancedWritingAnalysis.ImprovementSuggestion, index: Int, at yPosition: CGFloat, context: CGContext) -> CGFloat {
        let suggestionHeight: CGFloat = 120
        let suggestionRect = CGRect(x: margin, y: yPosition - suggestionHeight, width: pageSize.width - 2 * margin, height: suggestionHeight)
        
        drawRoundedRect(suggestionRect, cornerRadius: 8, fillColor: NSColor.controlBackgroundColor, context: context)
        
        // Suggestion number and title
        let titleText = "\(index). \(suggestion.title)"
        let titleRect = CGRect(x: margin + 15, y: yPosition - 25, width: pageSize.width - 2 * margin - 30, height: 20)
        drawText(titleText, in: titleRect, font: subheadingFont, color: primaryColor, context: context)
        
        // Description
        let descRect = CGRect(x: margin + 15, y: yPosition - 50, width: pageSize.width - 2 * margin - 30, height: 20)
        drawText(suggestion.description, in: descRect, font: bodyFont, color: .labelColor, context: context)
        
        // Before/After examples
        let beforeRect = CGRect(x: margin + 15, y: yPosition - 80, width: (pageSize.width - 2 * margin - 30) / 2 - 10, height: 25)
        drawText("Before: \(suggestion.beforeExample)", in: beforeRect, font: captionFont, color: NSColor.systemRed, context: context)
        
        let afterRect = CGRect(x: margin + 15 + (pageSize.width - 2 * margin - 30) / 2, y: yPosition - 80, width: (pageSize.width - 2 * margin - 30) / 2, height: 25)
        drawText("After: \(suggestion.afterExample)", in: afterRect, font: captionFont, color: accentColor, context: context)
        
        // Priority indicator
        let priorityText = "Priority: \(Int(suggestion.priority * 100))%"
        let priorityRect = CGRect(x: margin + 15, y: yPosition - 110, width: 150, height: 20)
        drawText(priorityText, in: priorityRect, font: captionFont, color: secondaryColor, context: context)
        
        return suggestionHeight
    }
    
    private func drawLearningModule(_ module: PersonalizedLearningRoadmap.LearningModule, index: Int, at yPosition: CGFloat, context: CGContext) -> CGFloat {
        let moduleHeight: CGFloat = 80
        let moduleRect = CGRect(x: margin, y: yPosition - moduleHeight, width: pageSize.width - 2 * margin, height: moduleHeight)
        
        drawRoundedRect(moduleRect, cornerRadius: 8, fillColor: NSColor.controlBackgroundColor, context: context)
        
        // Module title
        let titleText = "\(index). \(module.title)"
        let titleRect = CGRect(x: margin + 15, y: yPosition - 25, width: pageSize.width - 2 * margin - 30, height: 20)
        drawText(titleText, in: titleRect, font: subheadingFont, color: primaryColor, context: context)
        
        // Duration and difficulty
        let detailsText = "Duration: \(formatTime(module.estimatedTime)) • Difficulty: \(formatDifficulty(module.difficulty))"
        let detailsRect = CGRect(x: margin + 15, y: yPosition - 45, width: pageSize.width - 2 * margin - 30, height: 15)
        drawText(detailsText, in: detailsRect, font: captionFont, color: secondaryColor, context: context)
        
        // Objectives
        let objectivesText = module.objectives.prefix(2).joined(separator: " • ")
        let objectivesRect = CGRect(x: margin + 15, y: yPosition - 70, width: pageSize.width - 2 * margin - 30, height: 20)
        drawText(objectivesText, in: objectivesRect, font: captionFont, color: .labelColor, context: context)
        
        return moduleHeight
    }
    
    private func drawPageNumber(_ pageNumber: Int, context: CGContext) {
        let pageText = "Page \(pageNumber)"
        let pageRect = CGRect(x: pageSize.width - margin - 50, y: 30, width: 50, height: 15)
        drawText(pageText, in: pageRect, font: captionFont, color: secondaryColor, context: context, alignment: .right)
    }
    
    // MARK: - Formatting Helpers
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let weeks = Int(duration / (7 * 24 * 3600))
        if weeks > 0 {
            return "\(weeks) week\(weeks == 1 ? "" : "s")"
        } else {
            let days = Int(duration / (24 * 3600))
            return "\(days) day\(days == 1 ? "" : "s")"
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time / 3600)
        let minutes = Int((time.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func formatDifficulty(_ difficulty: Double) -> String {
        switch difficulty {
        case 0..<0.3: return "Easy"
        case 0.3..<0.7: return "Medium"
        default: return "Hard"
        }
    }
}