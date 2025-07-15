//
//  WritingAnalysisError.swift
//  FoundationWriting
//
//  Created by Hans Axelsson on 7/13/25.
//
import Foundation

public enum WritingAnalysisError: Error, LocalizedError {
    case emptyInput
    case tokenLimitExceeded
    case networkError(Error)
    case modelUnavailable
    case invalidResponse(String)
    case responseParsingFailure(String)
    case other(String)
    
    public var errorDescription: String? {
        switch self {
        case .emptyInput:
            return "No text provided for analysis"
        case .tokenLimitExceeded:
            return "Text exceeds maximum token limit"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .modelUnavailable:
            return "Analysis model is currently unavailable"
        case .invalidResponse(let details):
            return "Invalid response received: \(details)"
        case .responseParsingFailure(let details):
            return "Failed to parse response: \(details)"
        case .other(let message):
            return message
        }
    }
}
