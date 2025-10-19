//
//  View+UIViewController.swift
//  PhyDocOA
//
//  Created by Batyr Tolkynbayev on 12.12.2024.
//

import UIKit
import SwiftUI
import CryptoKit

extension View {
    var wrapped: UIHostingController<Self> {
        UIHostingController(rootView: self)
    }
}

extension Decimal {
    func kzt() -> String {
        let n = NSDecimalNumber(decimal: self).doubleValue
        let f = NumberFormatter(); f.locale = .init(identifier: "ru_RU")
        f.numberStyle = .decimal; f.maximumFractionDigits = 2; f.minimumFractionDigits = 0
        return (f.string(from: NSNumber(value: n)) ?? "\(n)") + "₸"
    }
}

extension Date {
    var isToday: Bool { Calendar.current.isDateInToday(self) }
    var dayHeader: String { let f = DateFormatter(); f.dateFormat = "d MMMM"; return f.string(from: self) }
}


struct CachedAsyncImage<Placeholder: View>: View {
    let url: URL?
    let placeholder: () -> Placeholder

    @State private var uiImage: UIImage?

    var body: some View {
        Group {
            if let img = uiImage {
                Image(uiImage: img).resizable()
            } else {
                placeholder()
                    .task { await load() }
            }
        }
    }

    private func load() async {
        guard let url else { return }
        if let data = try? Data(contentsOf: cacheURL(for: url)),
           let img = UIImage(data: data) {
            await MainActor.run { self.uiImage = img }
            return
        }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let img = UIImage(data: data) {
                try? data.write(to: cacheURL(for: url), options: .atomic)
                await MainActor.run { self.uiImage = img }
            }
        } catch { /* ignore */ }
    }

    private func cacheURL(for url: URL) -> URL {
        let name = SHA256.hash(data: Data(url.absoluteString.utf8)).compactMap { String(format: "%02x", $0) }.joined()
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("imgcache_\(name).dat")
    }
}


extension String {
    func nilIfBlank() -> String? {
        let t = trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
}
