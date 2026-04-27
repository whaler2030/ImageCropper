import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

/// 图片读写服务
class ImageService {

    /// 加载图片并返回 CGImage 和原始格式
    static func loadImage(from url: URL) -> (CGImage?, UTType?) {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            return (nil, nil)
        }

        // 获取原始格式
        let typeIdentifier = CGImageSourceGetType(source) as String?
        let fileType = typeIdentifier != nil ? UTType(typeIdentifier!) : nil

        return (image, fileType)
    }

    /// 获取图片尺寸
    static func getImageSize(image: CGImage) -> CGSize {
        return CGSize(width: image.width, height: image.height)
    }

    /// 裁切图片
    static func cropImage(image: CGImage, fromY: Int, height: Int) -> CGImage? {
        let width = image.width
        let rect = CGRect(x: 0, y: fromY, width: width, height: height)
        return image.cropping(to: rect)
    }

    /// 保存图片到文件
    static func saveImage(image: CGImage, to url: URL, type: UTType) -> Bool {
        let typeIdentifier = type.identifier as CFString
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, typeIdentifier, 1, nil) else {
            return false
        }

        CGImageDestinationAddImage(destination, image, nil)
        CGImageDestinationFinalize(destination)

        return true
    }

    /// 生成裁切后的文件名
    static func generateOutputFilename(originalURL: URL, index: Int) -> URL {
        let directory = originalURL.deletingLastPathComponent()
        let originalName = originalURL.deletingPathExtension().lastPathComponent
        let fileExtension = originalURL.pathExtension
        let newName = "\(originalName)_\(index).\(fileExtension)"
        return directory.appendingPathComponent(newName)
    }
}