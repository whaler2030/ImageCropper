import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var viewModel = ImageCropperViewModel()
    @State private var isDropTargeted = false
    @State private var showFileImporter = false

    private let supportedTypes: [UTType] = [.png, .jpeg]

    var body: some View {
        VStack(spacing: 20) {
            // 拖拽区
            dropZone

            Divider()

            // 控制区
            controlZone

            // 结果提示
            resultMessage
        }
        .padding(30)
        .frame(width: 500, height: 400)
    }

    // MARK: - 拖拽区

    private var dropZone: some View {
        VStack(spacing: 12) {
            if viewModel.loadedImage == nil {
                // 未导入图片时的提示
                Image(systemName: "photo.badge.plus")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)

                Text("拖拽图片到此处")
                    .font(.headline)
                    .foregroundColor(.secondary)

                Text("或点击选择文件")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Button("选择文件") {
                    showFileImporter = true
                }
                .buttonStyle(.bordered)
            } else {
                // 已导入图片后的信息
                Image(systemName: "photo.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.accentColor)

                if let url = viewModel.imageURL {
                    Text("已导入: \(url.lastPathComponent)")
                        .font(.headline)
                }

                Text("原图尺寸: \(Int(viewModel.imageSize.width)) × \(Int(viewModel.imageSize.height)) 像素")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if viewModel.estimatedCount > 0 {
                    Text("预计裁切: \(viewModel.estimatedCount) 张")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Button("重新选择") {
                    viewModel.clearAll()
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isDropTargeted ? Color.accentColor.opacity(0.1) : Color.gray.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isDropTargeted ? Color.accentColor : Color.gray.opacity(0.2), lineWidth: 2)
                )
        )
        .onDrop(of: supportedTypes, isTargeted: $isDropTargeted) { providers in
            handleDrop(providers: providers)
            return true
        }
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: supportedTypes) { result in
            handleFileImport(result: result)
        }
    }

    // MARK: - 控制区

    private var controlZone: some View {
        HStack(spacing: 16) {
            Text("裁切高度:")
                .font(.headline)

            TextField("像素", text: $viewModel.cropHeight)
                .textFieldStyle(.roundedBorder)
                .frame(width: 100)

            Text("像素")
                .foregroundColor(.secondary)

            Button("裁切") {
                viewModel.crop()
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.canCrop || viewModel.isProcessing)
        }
    }

    // MARK: - 结果提示

    @ViewBuilder
    private var resultMessage: some View {
        if let message = viewModel.successMessage {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text(message)
                    .foregroundColor(.green)
            }
        } else if let message = viewModel.errorMessage {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                Text(message)
                    .foregroundColor(.red)
            }
        }
    }

    // MARK: - 事件处理

    private func handleDrop(providers: [NSItemProvider]) {
        guard let provider = providers.first else { return }

        provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { item, error in
            if let data = item as? Data,
               let url = URL(dataRepresentation: data, relativeTo: nil) {
                DispatchQueue.main.async {
                    viewModel.importImage(from: url)
                }
            } else if let url = item as? URL {
                DispatchQueue.main.async {
                    viewModel.importImage(from: url)
                }
            }
        }
    }

    private func handleFileImport(result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            viewModel.importImage(from: url)
        case .failure(let error):
            viewModel.errorMessage = "无法导入文件: \(error.localizedDescription)"
        }
    }
}

#Preview {
    ContentView()
}