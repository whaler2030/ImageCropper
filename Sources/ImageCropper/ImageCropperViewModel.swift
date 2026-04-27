import Foundation
import CoreGraphics
import SwiftUI
import UniformTypeIdentifiers

/// 图片裁切应用的业务逻辑
@MainActor
class ImageCropperViewModel: ObservableObject {

    // MARK: - 状态

    /// 已导入的图片 URL
    @Published var imageURL: URL?

    /// 已导入的图片
    @Published var loadedImage: CGImage?

    /// 图片原始格式
    @Published var imageType: UTType?

    /// 图片尺寸
    @Published var imageSize: CGSize = .zero

    /// 用户输入的裁切高度
    @Published var cropHeight: String = ""

    /// 错误提示
    @Published var errorMessage: String?

    /// 成功提示
    @Published var successMessage: String?

    /// 是否正在处理
    @Published var isProcessing: Bool = false

    // MARK: - 计算属性

    /// 预计裁切数量
    var estimatedCount: Int {
        guard let image = loadedImage, let height = Int(cropHeight), height > 0 else {
            return 0
        }
        return Int(ceil(Double(image.height) / Double(height)))
    }

    /// 是否可以裁切
    var canCrop: Bool {
        guard loadedImage != nil,
              let height = Int(cropHeight),
              height > 0,
              height <= loadedImage!.height else {
            return false
        }
        return true
    }

    // MARK: - 方法

    /// 导入图片
    func importImage(from url: URL) {
        clearMessages()

        let (image, type) = ImageService.loadImage(from: url)

        guard let image = image, let type = type else {
            errorMessage = "无法加载图片"
            return
        }

        imageURL = url
        loadedImage = image
        imageType = type
        imageSize = ImageService.getImageSize(image: image)
    }

    /// 执行裁切
    func crop() {
        clearMessages()

        guard let image = loadedImage,
              let type = imageType,
              let url = imageURL,
              let height = Int(cropHeight),
              height > 0 else {
            errorMessage = "请输入有效的裁切高度"
            return
        }

        if height > image.height {
            errorMessage = "裁切高度超过图片高度，请减小"
            return
        }

        isProcessing = true

        let totalHeight = image.height
        var currentIndex = 1
        var successCount = 0

        // 计算裁切次数
        let count = Int(ceil(Double(totalHeight) / Double(height)))

        for i in 0..<count {
            let fromY = i * height
            let remainingHeight = totalHeight - fromY
            let actualHeight = min(height, remainingHeight)

            guard let croppedImage = ImageService.cropImage(image: image, fromY: fromY, height: actualHeight) else {
                continue
            }

            let outputURL = ImageService.generateOutputFilename(originalURL: url, index: currentIndex)

            if ImageService.saveImage(image: croppedImage, to: outputURL, type: type) {
                successCount += 1
            }

            currentIndex += 1
        }

        isProcessing = false

        if successCount == count {
            successMessage = "成功裁切 \(successCount) 张图片"
        } else {
            errorMessage = "裁切完成，但仅成功保存 \(successCount)/\(count) 张图片"
        }
    }

    /// 清除提示消息
    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }

    /// 清除所有状态
    func clearAll() {
        imageURL = nil
        loadedImage = nil
        imageType = nil
        imageSize = .zero
        cropHeight = ""
        clearMessages()
    }
}