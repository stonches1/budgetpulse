//
//  ImageStorageManager.swift
//  BudgetPulse
//

import Foundation
import UIKit

final class ImageStorageManager {
    static let shared = ImageStorageManager()

    private let receiptsFolder = "Receipts"
    private let fileManager = FileManager.default

    private var receiptsDirectory: URL? {
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return documentsDirectory.appendingPathComponent(receiptsFolder)
    }

    private init() {
        createReceiptsDirectoryIfNeeded()
    }

    private func createReceiptsDirectoryIfNeeded() {
        guard let receiptsDirectory = receiptsDirectory else { return }

        if !fileManager.fileExists(atPath: receiptsDirectory.path) {
            try? fileManager.createDirectory(at: receiptsDirectory, withIntermediateDirectories: true)
        }
    }

    // MARK: - Save Image

    func saveImage(_ image: UIImage, for expenseId: UUID) -> String? {
        createReceiptsDirectoryIfNeeded()

        guard let receiptsDirectory = receiptsDirectory else {
            print("[ImageStorage] Error: receiptsDirectory is nil")
            return nil
        }

        let filename = "\(expenseId.uuidString).jpg"
        let fileURL = receiptsDirectory.appendingPathComponent(filename)

        // Compress and save as JPEG
        guard let data = image.jpegData(compressionQuality: 0.7) else {
            print("[ImageStorage] Error: Failed to convert image to JPEG data")
            return nil
        }

        do {
            try data.write(to: fileURL)
            print("[ImageStorage] Saved image to: \(fileURL.path)")
            return filename
        } catch {
            print("[ImageStorage] Error saving receipt image: \(error)")
            return nil
        }
    }

    // MARK: - Load Image

    func loadImage(filename: String) -> UIImage? {
        guard let receiptsDirectory = receiptsDirectory else {
            print("[ImageStorage] Error: receiptsDirectory is nil during load")
            return nil
        }

        let fileURL = receiptsDirectory.appendingPathComponent(filename)
        print("[ImageStorage] Attempting to load from: \(fileURL.path)")

        guard fileManager.fileExists(atPath: fileURL.path) else {
            print("[ImageStorage] Error: File does not exist at path")
            return nil
        }

        let image = UIImage(contentsOfFile: fileURL.path)
        print("[ImageStorage] Load result: \(image != nil ? "success" : "failed")")
        return image
    }

    // MARK: - Delete Image

    func deleteImage(filename: String) {
        guard let receiptsDirectory = receiptsDirectory else { return }

        let fileURL = receiptsDirectory.appendingPathComponent(filename)

        try? fileManager.removeItem(at: fileURL)
    }

    // MARK: - Check Image Exists

    func imageExists(filename: String) -> Bool {
        guard let receiptsDirectory = receiptsDirectory else { return false }

        let fileURL = receiptsDirectory.appendingPathComponent(filename)
        return fileManager.fileExists(atPath: fileURL.path)
    }

    // MARK: - Get Image URL

    func imageURL(for filename: String) -> URL? {
        guard let receiptsDirectory = receiptsDirectory else { return nil }
        return receiptsDirectory.appendingPathComponent(filename)
    }

    // MARK: - Cleanup

    func deleteAllImages() {
        guard let receiptsDirectory = receiptsDirectory else { return }

        try? fileManager.removeItem(at: receiptsDirectory)
        createReceiptsDirectoryIfNeeded()
    }

    func cleanupOrphanedImages(validExpenseIds: Set<UUID>) {
        guard let receiptsDirectory = receiptsDirectory else { return }

        do {
            let files = try fileManager.contentsOfDirectory(at: receiptsDirectory, includingPropertiesForKeys: nil)

            for fileURL in files {
                let filename = fileURL.deletingPathExtension().lastPathComponent
                if let uuid = UUID(uuidString: filename), !validExpenseIds.contains(uuid) {
                    try? fileManager.removeItem(at: fileURL)
                }
            }
        } catch {
            print("Error cleaning up orphaned images: \(error)")
        }
    }

    // MARK: - Storage Info

    var totalStorageUsed: Int64 {
        guard let receiptsDirectory = receiptsDirectory else { return 0 }

        do {
            let files = try fileManager.contentsOfDirectory(at: receiptsDirectory, includingPropertiesForKeys: [.fileSizeKey])
            var totalSize: Int64 = 0

            for fileURL in files {
                let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey])
                totalSize += Int64(resourceValues.fileSize ?? 0)
            }

            return totalSize
        } catch {
            return 0
        }
    }

    var formattedStorageUsed: String {
        let bytes = totalStorageUsed
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
