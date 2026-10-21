import Foundation
import CryptoKit

struct UpdateFailure: LocalizedError {
    let message: String
    init(_ message: String) { self.message = message }
    var errorDescription: String? { message }
}

struct UpdateRelease: Codable {
    let version: String
    let notes: String
    let url: String
    let sha256: String
    let size: Int64
    let minimumSystem: String
    let architecture: String
}

enum UpdateCore {
    static let feed = URL(string: "https://raw.githubusercontent.com/wxu430375-cloud/tea-diary/main/updates/stable.json")!
    static let bundleID = "studio.teacha.diary"
    static func versionParts(_ value: String) throws -> [Int] {
        let parts = value.split(separator: ".", omittingEmptySubsequences: false)
        guard (2...3).contains(parts.count), parts.allSatisfy({ !$0.isEmpty && $0.utf8.allSatisfy { (48...57).contains($0) } }),
              parts.allSatisfy({ Int($0) != nil && $0.count <= 6 }) else { throw UpdateFailure("更新版本号无效。") }
        return parts.map { Int($0)! } + Array(repeating: 0, count: 3 - parts.count)
    }
    static func isNewer(_ candidate: String, than current: String) throws -> Bool {
        let a = try versionParts(candidate), b = try versionParts(current)
        return b.lexicographicallyPrecedes(a)
    }
    static func verifiedRelease(_ envelope: Data, publicKey: Data = UpdateTrust.publicKey) throws -> UpdateRelease {
        struct Envelope: Decodable { let payload: String; let signature: String }
        guard envelope.count <= 65536 else { throw UpdateFailure("更新说明过大。") }
        let signed = try JSONDecoder().decode(Envelope.self, from: envelope)
        guard let payload = Data(base64Encoded: signed.payload), let signature = Data(base64Encoded: signed.signature),
              try Curve25519.Signing.PublicKey(rawRepresentation: publicKey).isValidSignature(signature, for: payload) else {
            throw UpdateFailure("更新签名不正确，已停止更新。")
        }
        let release = try JSONDecoder().decode(UpdateRelease.self, from: payload)
        _ = try versionParts(release.version)
        _ = try versionParts(release.minimumSystem)
        guard release.architecture == "arm64", release.size > 0, release.size <= 180 * 1024 * 1024,
              release.notes.count <= 8000, release.sha256.range(of: "^[a-f0-9]{64}$", options: .regularExpression) != nil,
              let url = URL(string: release.url), url.scheme == "https", url.host == "raw.githubusercontent.com",
              url.user == nil, url.password == nil, url.port == nil, url.query == nil, url.fragment == nil,
              url.path == "/wxu430375-cloud/tea-diary/main/updates/TeaDiary-\(release.version)-macos-arm64.zip" else {
            throw UpdateFailure("更新包信息无效，已停止更新。")
        }
        return release
    }
    static func verifyArchive(_ file: URL, release: UpdateRelease) throws {
        let size = try file.resourceValues(forKeys: [.fileSizeKey]).fileSize
        guard Int64(size ?? -1) == release.size else { throw UpdateFailure("更新包下载不完整，请重新检查更新。") }
        let handle = try FileHandle(forReadingFrom: file)
        defer { try? handle.close() }
        var hash = SHA256()
        while let bytes = try handle.read(upToCount: 1024 * 1024), !bytes.isEmpty { hash.update(data: bytes) }
        guard hash.finalize().map({ String(format: "%02x", $0) }).joined() == release.sha256 else {
            throw UpdateFailure("更新包校验失败，已保留当前版本。")
        }
    }
    @discardableResult static func run(_ executable: String, _ arguments: [String]) throws -> String {
        let process = Process(); process.executableURL = URL(fileURLWithPath: executable); process.arguments = arguments
        let output = Pipe(); process.standardOutput = output; process.standardError = output
        try process.run()
        let data = output.fileHandleForReading.readDataToEndOfFile(); process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            NSLog("TeaDiary updater: %@ failed: %@", executable, String(data: data, encoding: .utf8) ?? "")
            throw UpdateFailure("更新文件处理失败，当前版本已保留。")
        }
        return String(data: data, encoding: .utf8) ?? ""
    }
    static func validateBundle(_ app: URL, version: String) throws {
        let fm = FileManager.default
        guard let info = NSDictionary(contentsOf: app.appendingPathComponent("Contents/Info.plist")),
              info["CFBundleIdentifier"] as? String == bundleID,
              info["CFBundleShortVersionString"] as? String == version,
              info["CFBundleExecutable"] as? String == "TeaDiary",
              fm.isExecutableFile(atPath: app.appendingPathComponent("Contents/MacOS/TeaDiary").path),
              fm.isExecutableFile(atPath: app.appendingPathComponent("Contents/Helpers/TeaDiaryUpdater").path) else {
            throw UpdateFailure("更新包不是正确的茶茶手账版本。")
        }
        guard let files = fm.enumerator(at: app, includingPropertiesForKeys: [.isSymbolicLinkKey]) else { throw UpdateFailure("无法检查更新文件。") }
        for case let file as URL in files {
            if try file.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink == true { throw UpdateFailure("更新包包含无效的文件链接。") }
        }
        try run("/usr/bin/codesign", ["--verify", "--deep", "--strict", app.path])
    }
    static func requireWritableInstallation(_ target: URL) throws {
        let fm = FileManager.default
        let resolved = target.resolvingSymlinksInPath().standardizedFileURL
        guard resolved.path == target.standardizedFileURL.path, target.pathExtension == "app",
              !target.path.contains("/AppTranslocation/"),
              try target.resourceValues(forKeys: [.volumeIsReadOnlyKey]).volumeIsReadOnly != true,
              fm.isWritableFile(atPath: target.deletingLastPathComponent().path), fm.isWritableFile(atPath: target.path) else {
            throw UpdateFailure("请先退出 App，把它从安装磁盘拖到「应用程序」文件夹，再打开检查更新。")
        }
    }
    // Stage on the same volume before quitting, so permission/copy errors cannot remove the running app.
    static func prepare(_ candidate: URL, target: URL, version: String) throws -> URL {
        try requireWritableInstallation(target)
        let stage = target.deletingLastPathComponent().appendingPathComponent(".TeaDiary-update-" + UUID().uuidString, isDirectory: true)
        let staged = stage.appendingPathComponent(target.lastPathComponent)
        try FileManager.default.createDirectory(at: stage, withIntermediateDirectories: false)
        do {
            try run("/usr/bin/ditto", ["--norsrc", "--noextattr", candidate.path, staged.path])
            try run("/usr/bin/xattr", ["-cr", staged.path])
            try validateBundle(staged, version: version)
            return staged
        } catch { try? FileManager.default.removeItem(at: stage); throw error }
    }
    // The old app stays beside the replacement until the new process has launched.
    static func replace(_ staged: URL, target: URL, version: String, launch: (URL) throws -> Void) throws {
        let fm = FileManager.default
        try requireWritableInstallation(target)
        try validateBundle(staged, version: version)
        let backup = target.deletingLastPathComponent().appendingPathComponent(".TeaDiary-previous-" + UUID().uuidString + ".app")
        try fm.moveItem(at: target, to: backup)
        do {
            try fm.moveItem(at: staged, to: target)
            try validateBundle(target, version: version)
            try launch(target)
        } catch {
            try? fm.removeItem(at: target)
            do { try fm.moveItem(at: backup, to: target) }
            catch { throw UpdateFailure("无法恢复原应用。原版本仍在：\(backup.path)。手账数据未更改。") }
            throw error
        }
        try? fm.removeItem(at: backup)
    }
}
