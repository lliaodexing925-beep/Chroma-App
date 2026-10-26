import Foundation
import UIKit

/// 照片统一存到 App 沙盒 Documents/MomentPhotos 下，文件名 <UUID>.jpg。
/// 数据库里只存文件名数组，删除时刻时一并清理磁盘文件。
enum PhotoStore {
    static var directory: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("MomentPhotos", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    @discardableResult
    static func save(data: Data) -> String? {
        guard let image = UIImage(data: data) else { return nil }
        let name = UUID().uuidString + ".jpg"
        let url = directory.appendingPathComponent(name)
        let scaled = image.scaledToFit(maxDimension: 2048)
        guard let jpeg = scaled.jpegData(compressionQuality: 0.82) else { return nil }
        do {
            try jpeg.write(to: url, options: .atomic)
            return name
        } catch {
            return nil
        }
    }

    static func url(for name: String) -> URL {
        directory.appendingPathComponent(name)
    }

    static func image(named name: String) -> UIImage? {
        UIImage(contentsOfFile: url(for: name).path)
    }

    static func delete(names: [String]) {
        for name in names {
            try? FileManager.default.removeItem(at: url(for: name))
        }
    }
}

extension UIImage {
    func scaledToFit(maxDimension: CGFloat) -> UIImage {
        let longest = max(size.width, size.height)
        guard longest > maxDimension, longest > 0 else { return self }
        let scale = maxDimension / longest
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
