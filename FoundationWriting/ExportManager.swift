//
//  ExportManager.swift
//  FoundationWriting
//
//  Created by Hans Axelsson on 7/15/25.
//
import Foundation
import AppKit
import PDFKit
import SwiftUI

/// Manages export functionality for writing analysis reports
@MainActor
class ExportManager: ObservableObject {
    @Published var isExporting = false
    @Published var exportProgress: Double = 0.0
    @Published var lastExportedURL: URL?
    
    private let configManager: ConfigurationManager
    
    init(configManager: ConfigurationManager) {
        self.configManager = configManager
    }
    
    /// Exports analysis results in the specified format
    func exportAnalysis(
        _ analysis: EnhancedWritingAnalysis,
        originalText: String,
        roadmap: PersonalizedLearningRoadmap?,
        format: ExportSettings.ExportFormat,
        to url: URL? = nil
    ) async throws -> URL {
        
        isExporting = true
        exportProgress = 0.0
        
        defer {
            isExporting = false
            exportProgress = 0.0
        }
        
        let exportData = ExportData(
            analysis: analysis,
            originalText: originalText,
            roadmap: roadmap,
            settings: configManager.currentConfig.exportSettings,
            generatedAt: Date()
        )
        
        exportProgress = 0.2
        
        let exportURL: URL
        if let url = url {
            exportURL = url
        } else {
            exportURL = try await showSavePanel(for: format)
        }
        
        exportProgress = 0.4
        
        switch format {
        case .pdf:
            try await generatePDFReport(exportData, to: exportURL)
        case .markdown:
            try await generateMarkdownReport(exportData, to: exportURL)
        case .html:
            try await generateHTMLReport(exportData, to: exportURL)
        case .text:
            try await generateTextReport(exportData, to: exportURL)
        }
        
        exportProgress = 1.0
        lastExportedURL = exportURL
        
        return exportURL
    }
    
    /// Generates a comprehensive PDF report
    private func generatePDFReport(_ data: ExportData, to url: URL) async throws {
        let pdfGenerator = PDFReportGenerator(data: data)
        let pdfDocument = try await pdfGenerator.generateReport()
        
        exportProgress = 0.8
        
        guard pdfDocument.write(to: url) else {
            throw ExportError.failedToWriteFile
        }
    }
    
    /// Generates a markdown report
    private func generateMarkdownReport(_ data: ExportData, to url: URL) async throws {
        let markdownGenerator = MarkdownReportGenerator(data: data)
        let markdown = try await markdownGenerator.generateReport()
        
        exportProgress = 0.8
        
        try markdown.write(to: url, atomically: true, encoding: .utf8)
    }
    
    /// Generates an HTML report
    private func generateHTMLReport(_ data: ExportData, to url: URL) async throws {
        let htmlGenerator = HTMLReportGenerator(data: data)
        let html = try await htmlGenerator.generateReport()
        
        exportProgress = 0.8
        
        try html.write(to: url, atomically: true, encoding: .utf8)
    }
    
    /// Generates a plain text report
    private func generateTextReport(_ data: ExportData, to url: URL) async throws {
        let textGenerator = TextReportGenerator(data: data)
        let text = try await textGenerator.generateReport()
        
        exportProgress = 0.8
        
        try text.write(to: url, atomically: true, encoding: .utf8)
    }
    
    /// Shows save panel for file selection
    private func showSavePanel(for format: ExportSettings.ExportFormat) async throws -> URL {
        return try await withCheckedThrowingContinuation { continuation in
            let savePanel = NSSavePanel()
            savePanel.title = "Export Writing Analysis"
            savePanel.nameFieldStringValue = "Writing Analysis Report"
            savePanel.allowedContentTypes = [format.contentType]
            savePanel.canCreateDirectories = true
            
            savePanel.begin { response in
                if response == .OK, let url = savePanel.url {
                    continuation.resume(returning: url)
                } else {
                    continuation.resume(throwing: ExportError.userCancelled)
                }
            }
        }
    }
    
    /// Quick export with default settings
    func quickExport(
        _ analysis: EnhancedWritingAnalysis,
        originalText: String,
        roadmap: PersonalizedLearningRoadmap?
    ) async throws -> URL {
        let format = configManager.currentConfig.exportSettings.defaultFormat
        return try await exportAnalysis(analysis, originalText: originalText, roadmap: roadmap, format: format)
    }
    
    /// Share analysis via system share sheet
    func shareAnalysis(
        _ analysis: EnhancedWritingAnalysis,
        originalText: String,
        roadmap: PersonalizedLearningRoadmap?
    ) async throws {
        // Create temporary file for sharing
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("Writing_Analysis_\(Date().timeIntervalSince1970)")
            .appendingPathExtension("pdf")
        
        let exportURL = try await exportAnalysis(
            analysis,
            originalText: originalText,
            roadmap: roadmap,
            format: .pdf,
            to: tempURL
        )
        
        // Show share sheet
        let sharingService = NSSharingService(named: .sendViaAirDrop)
        sharingService?.perform(withItems: [exportURL])
    }
}

// MARK: - Export Data Structure

struct ExportData {
    let analysis: EnhancedWritingAnalysis
    let originalText: String
    let roadmap: PersonalizedLearningRoadmap?
    let settings: ExportSettings
    let generatedAt: Date
}

// MARK: - Export Errors

enum ExportError: LocalizedError {
    case userCancelled
    case failedToWriteFile
    case invalidFormat
    case missingData
    
    var errorDescription: String? {
        switch self {
        case .userCancelled:
            return "Export was cancelled by user"
        case .failedToWriteFile:
            return "Failed to write export file"
        case .invalidFormat:
            return "Invalid export format"
        case .missingData:
            return "Missing required data for export"
        }
    }
}

// MARK: - Content Type Extensions

extension ExportSettings.ExportFormat {
    var contentType: UTType {
        switch self {
        case .pdf: return .pdf
        case .markdown: return UTType(filenameExtension: "md") ?? .plainText
        case .html: return .html
        case .text: return .plainText
        }
    }
    
    var fileExtension: String {
        switch self {
        case .pdf: return "pdf"
        case .markdown: return "md"
        case .html: return "html"
        case .text: return "txt"
        }
    }
}