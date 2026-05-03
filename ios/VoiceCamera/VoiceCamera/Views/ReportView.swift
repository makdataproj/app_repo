import SwiftUI

struct ReportView: View {
    @EnvironmentObject private var store: SessionStore
    @State private var pdfURL: URL?

    var body: some View {
        NavigationStack {
            Form {
                Section("Draft") {
                    Picker("Template", selection: $store.session.report.template) {
                        ForEach(ReportTemplate.allCases) { template in
                            Text(template.rawValue).tag(template)
                        }
                    }

                    TextField("Report title", text: $store.session.report.title)
                    TextField("Summary", text: $store.session.report.summary, axis: .vertical)
                        .lineLimit(4...10)
                }

                Section("Preview") {
                    Text(store.reportText())
                        .font(.body.monospaced())
                        .textSelection(.enabled)
                }

                Section("Share") {
                    ShareLink(item: store.reportText()) {
                        Label("Share text", systemImage: "square.and.arrow.up")
                    }

                    Button {
                        pdfURL = PDFReportRenderer.render(session: store.session, store: store)
                    } label: {
                        Label("Generate PDF", systemImage: "doc.richtext")
                    }

                    if let pdfURL {
                        ShareLink(item: pdfURL) {
                            Label("Share PDF", systemImage: "paperplane")
                        }
                    }

                    if let emailURL {
                        Link(destination: emailURL) {
                            Label("Email draft", systemImage: "envelope")
                        }
                    }

                    if let smsURL {
                        Link(destination: smsURL) {
                            Label("SMS summary", systemImage: "message")
                        }
                    }
                }
            }
            .navigationTitle("Report")
        }
    }

    private var emailURL: URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = store.session.clientEmail
        components.queryItems = [
            URLQueryItem(name: "subject", value: store.session.report.title.isEmpty ? store.session.title : store.session.report.title),
            URLQueryItem(name: "body", value: store.reportText())
        ]
        return components.url
    }

    private var smsURL: URL? {
        var components = URLComponents()
        components.scheme = "sms"
        components.path = store.session.clientPhone
        components.queryItems = [
            URLQueryItem(name: "body", value: store.smsSummary())
        ]
        return components.url
    }
}
