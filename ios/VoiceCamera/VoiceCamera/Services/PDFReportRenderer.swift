import PDFKit
import UIKit

@MainActor
enum PDFReportRenderer {
    static func render(session: JobSession, store: SessionStore) -> URL? {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let url = store.documentsURL.appendingPathComponent("VoiceCameraReport.pdf")
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        do {
            try renderer.writePDF(to: url) { context in
                context.beginPage()
                var y: CGFloat = 36
                y = draw(session.report.title.isEmpty ? session.title : session.report.title, at: y, font: .boldSystemFont(ofSize: 22), pageRect: pageRect)
                y = draw(session.report.template.rawValue, at: y + 8, font: .systemFont(ofSize: 13), pageRect: pageRect)
                y = draw("Client: \(session.clientName.isEmpty ? "Not set" : session.clientName)", at: y + 16, font: .systemFont(ofSize: 12), pageRect: pageRect)
                y = draw("Address: \(session.address.isEmpty ? "Not set" : session.address)", at: y + 4, font: .systemFont(ofSize: 12), pageRect: pageRect)
                y = draw(session.report.summary.isEmpty ? store.generatedSummary() : session.report.summary, at: y + 18, font: .systemFont(ofSize: 12), pageRect: pageRect)

                for (index, photo) in session.photos.filter(\.includedInReport).enumerated() {
                    if y > 610 {
                        context.beginPage()
                        y = 36
                    }

                    if let image = UIImage(contentsOfFile: store.mediaURL(for: photo.thumbnailFilename).path) {
                        image.draw(in: CGRect(x: 36, y: y + 12, width: 140, height: 105))
                    }
                    y = draw("Photo \(index + 1)", at: y + 12, x: 196, font: .boldSystemFont(ofSize: 13), pageRect: pageRect)
                    y = draw(photo.caption.isEmpty ? "No caption" : photo.caption, at: y + 4, x: 196, font: .systemFont(ofSize: 12), pageRect: pageRect)
                    y += 80
                }
            }
            return url
        } catch {
            return nil
        }
    }

    private static func draw(_ text: String, at y: CGFloat, x: CGFloat = 36, font: UIFont, pageRect: CGRect) -> CGFloat {
        let width = pageRect.width - x - 36
        let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: UIColor.black]
        let rect = NSString(string: text).boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes,
            context: nil
        )
        NSString(string: text).draw(in: CGRect(x: x, y: y, width: width, height: rect.height), withAttributes: attributes)
        return y + rect.height
    }
}
