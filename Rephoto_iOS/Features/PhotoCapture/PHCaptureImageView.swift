import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import ImageIO

struct PHCaptureImageView: UIViewControllerRepresentable {
    @Binding var photos: [PhotoMetadata]

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())
        configuration.filter = .any(of: [.images])
        configuration.selectionLimit = 0 // 여러 장 선택 가능

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        private let parent: PHCaptureImageView

        init(_ parent: PHCaptureImageView) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            parent.photos.removeAll()

            for result in results {
                if result.itemProvider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                    result.itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.image.identifier) { url, error in
                        guard let url = url else { return }

                        let fileName = url.lastPathComponent

                        guard let data = try? Data(contentsOf: url),
                              let cgImageSource = CGImageSourceCreateWithData(data as CFData, nil),
                              let properties = CGImageSourceCopyPropertiesAtIndex(cgImageSource, 0, nil) as? [String: Any]
                        else { return }

                        // EXIF & GPS
                        let exif = properties["{Exif}"] as? [String: Any]
                        let gps = properties[kCGImagePropertyGPSDictionary as String] as? [String: Any]

                        // 촬영 시간 → 서버 포맷 yyyy-MM-dd'T'HH:mm:ss
                        var createdAt = Date()
                        if let dateTimeOriginal = exif?["DateTimeOriginal"] as? String {
                            let formatter = DateFormatter()
                            formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
                            formatter.locale = Locale(identifier: "en_US_POSIX")
                            if let date = formatter.date(from: dateTimeOriginal) {
                                createdAt = date
                            }
                        }
                        let serverFormatter = DateFormatter()
                        serverFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                        serverFormatter.locale = Locale(identifier: "en_US_POSIX")
                        serverFormatter.timeZone = TimeZone(secondsFromGMT: 0)
                        let isoDate = serverFormatter.string(from: createdAt)

                        // 위도, 경도
                        let latitude = gps?["Latitude"] as? Double ?? 0.0
                        let longitude = gps?["Longitude"] as? Double ?? 0.0

                        // 로컬 임시 경로 URL → 문자열로 저장
                        let destURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                        try? FileManager.default.copyItem(at: url, to: destURL)

                        let photoDTO = PhotoMetadata(
                            latitude: latitude,
                            longitude: longitude,
                            imageUrl: destURL.absoluteString,
                            createdAt: isoDate,   // ✅ 서버 요구 포맷
                            fileName: fileName
                        )

                        DispatchQueue.main.async {
                            self.parent.photos.append(photoDTO)
                        }
                    }
                }
            }
        }
    }
}
