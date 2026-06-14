import SwiftUI
import UIKit

/// Wrapper de UIActivityViewController para compartilhar um arquivo exportado.
struct ShareSheet: UIViewControllerRepresentable {
    let data: Data
    let filename: String
    let mimeType: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let tempURL = FileManager.default
            .temporaryDirectory
            .appendingPathComponent(filename)

        // Sobrescreve silenciosamente se já existir
        try? data.write(to: tempURL, options: .atomic)

        return UIActivityViewController(
            activityItems: [tempURL],
            applicationActivities: nil
        )
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
