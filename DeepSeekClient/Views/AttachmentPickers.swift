// Designed by TiantianYe
import SwiftUI
import PhotosUI
import UIKit
import UniformTypeIdentifiers

/// 相册选择器（系统原生 PHPicker，iOS 14+）
struct PhotoLibraryPicker: UIViewControllerRepresentable {
    let completion: (Data) -> Void
    @Environment(\.presentationMode) private var presentationMode

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(completion: completion, dismiss: { presentationMode.wrappedValue.dismiss() })
    }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let completion: (Data) -> Void
        let dismiss: () -> Void

        init(completion: @escaping (Data) -> Void, dismiss: @escaping () -> Void) {
            self.completion = completion
            self.dismiss = dismiss
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            dismiss()
            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else { return }
            provider.loadObject(ofClass: UIImage.self) { image, _ in
                guard let uiImage = image as? UIImage else { return }
                let data = uiImage.jpegData(compressionQuality: 0.8) ?? Data()
                DispatchQueue.main.async { self.completion(data) }
            }
        }
    }
}

/// 相机拍照选择器（系统原生 UIImagePickerController）
struct CameraPicker: UIViewControllerRepresentable {
    let completion: (Data) -> Void
    @Environment(\.presentationMode) private var presentationMode

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(completion: completion, dismiss: { presentationMode.wrappedValue.dismiss() })
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let completion: (Data) -> Void
        let dismiss: () -> Void

        init(completion: @escaping (Data) -> Void, dismiss: @escaping () -> Void) {
            self.completion = completion
            self.dismiss = dismiss
        }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            dismiss()
            guard let image = info[.originalImage] as? UIImage else { return }
            completion(image.jpegData(compressionQuality: 0.8) ?? Data())
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            dismiss()
        }
    }
}

/// 文件选择器（系统原生 UIDocumentPickerViewController，读取文本类文件）
struct DocumentPicker: UIViewControllerRepresentable {
    let completion: (String, String) -> Void
    @Environment(\.presentationMode) private var presentationMode

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let types: [UTType] = [.text, .plainText, .utf8PlainText, .json, .sourceCode, .pdf]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types, asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(completion: completion, dismiss: { presentationMode.wrappedValue.dismiss() })
    }

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let completion: (String, String) -> Void
        let dismiss: () -> Void

        init(completion: @escaping (String, String) -> Void, dismiss: @escaping () -> Void) {
            self.completion = completion
            self.dismiss = dismiss
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            dismiss()
            guard let url = urls.first else { return }
            let name = url.lastPathComponent
            if let text = try? String(contentsOf: url, encoding: .utf8) {
                completion(name, String(text.prefix(8000)))
            } else {
                completion(name, "（文件内容无法解析为文本）")
            }
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            dismiss()
        }
    }
}
