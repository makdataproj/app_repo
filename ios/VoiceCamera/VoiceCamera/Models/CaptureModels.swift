import Foundation

struct JobSession: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String = "New Session"
    var clientName: String = ""
    var clientEmail: String = ""
    var clientPhone: String = ""
    var address: String = ""
    var notes: String = ""
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var estimateMode: Bool = false
    var transcript: String = ""
    var photos: [CapturedPhoto] = []
    var recordings: [VoiceRecording] = []
    var report: ReportDraft = ReportDraft()
    var estimate: EstimateDraft = EstimateDraft()

    static func fresh() -> JobSession {
        var session = JobSession()
        session.title = "Session \(Self.titleFormatter.string(from: Date()))"
        return session
    }

    private static let titleFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

struct CapturedPhoto: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var imageFilename: String
    var thumbnailFilename: String
    var capturedAt: Date = Date()
    var recordingID: UUID?
    var recordingOffset: TimeInterval?
    var caption: String = ""
    var includedInReport: Bool = true
}

struct VoiceRecording: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var audioFilename: String
    var startedAt: Date
    var endedAt: Date
    var transcript: String = ""
    var transcriptionStatus: TranscriptionStatus = .notStarted

    var duration: TimeInterval {
        endedAt.timeIntervalSince(startedAt)
    }
}

enum TranscriptionStatus: String, Codable, Equatable {
    case notStarted = "Not started"
    case transcribing = "Transcribing"
    case completed = "Completed"
    case unavailable = "Unavailable"
    case failed = "Failed"
}

struct ReportDraft: Codable, Equatable {
    var template: ReportTemplate = .siteDocumentation
    var title: String = ""
    var summary: String = ""
}

enum ReportTemplate: String, CaseIterable, Identifiable, Codable {
    case siteDocumentation = "Site documentation"
    case estimateSupport = "Estimate support"
    case beforeAfter = "Before-and-after summary"
    case clientUpdate = "Client update"

    var id: String { rawValue }
}

struct EstimateDraft: Codable, Equatable {
    var assumptions: String = "Draft estimate only. Pricing and scope require user review before sending."
    var lineItems: [EstimateLineItem] = [
        EstimateLineItem(description: "Review documented work", quantity: 1, unit: "each", unitCost: 0)
    ]

    var total: Decimal {
        lineItems.reduce(Decimal(0)) { $0 + $1.total }
    }
}

struct EstimateLineItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var description: String
    var quantity: Decimal
    var unit: String
    var unitCost: Decimal

    var total: Decimal {
        quantity * unitCost
    }
}
