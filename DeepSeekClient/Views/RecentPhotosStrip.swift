// Designed by TiantianYe
import SwiftUI
import Photos

/// 最近照片横条：读取系统相册最近的照片，点击即选为附件（真实可用，非占位）
struct RecentPhotosStrip: View {
    let onSelect: (Data) -> Void
    @State private var images: [UIImage] = []

    var body: some View {
        Group {
            if images.isEmpty {
                EmptyView()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(images.enumerated()), id: \.offset) { _, image in
                            Button {
                                if let data = image.jpegData(compressionQuality: 0.8) {
                                    onSelect(data)
                                }
                            } label: {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 66, height: 66)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("选择最近照片")
                        }
                    }
                }
                .frame(height: 66)
            }
        }
        .task {
            await loadRecentPhotos()
        }
    }

    @MainActor
    private func loadRecentPhotos() {
        guard images.isEmpty else { return }
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .authorized, .limited:
            fetchPhotos()
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
                if newStatus == .authorized || newStatus == .limited {
                    DispatchQueue.main.async { self.fetchPhotos() }
                }
            }
        default:
            break
        }
    }

    private func fetchPhotos() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = 8
        let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast

        var loaded: [UIImage] = []
        let group = DispatchGroup()
        assets.enumerateObjects { asset, _, _ in
            group.enter()
            manager.requestImage(
                for: asset,
                targetSize: CGSize(width: 132, height: 132),
                contentMode: .aspectFill,
                options: options
            ) { image, _ in
                if let image = image { loaded.append(image) }
                group.leave()
            }
        }
        group.notify(queue: .main) {
            self.images = Array(loaded.prefix(8))
        }
    }
}
