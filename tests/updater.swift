import Foundation
import CryptoKit

@main enum UpdaterTests {
    static var checks = 0
    static func expect(_ condition: @autoclosure () throws -> Bool, _ message: String) throws {
        guard try condition() else { fatalError(message) }; checks += 1
    }
    static func rejects(_ message: String, _ action: () throws -> Void) {
        do { try action(); fatalError("Accepted: " + message) } catch { checks += 1 }
    }
    static func envelope(_ release: UpdateRelease, key: Curve25519.Signing.PrivateKey) throws -> Data {
        let payload = try JSONEncoder().encode(release)
        return try JSONSerialization.data(withJSONObject: ["payload": payload.base64EncodedString(), "signature": key.signature(for: payload).base64EncodedString()])
    }
    static func main() throws {
        try expect(UpdateCore.isNewer("1.10.0", than: "1.9.9"), "numeric ordering")
        try expect(!UpdateCore.isNewer("1.3.0", than: "1.3"), "equal normalization")
        try expect(!UpdateCore.isNewer("1.2.0", than: "1.3.0"), "no downgrade")
        for value in ["", "1", "1..0", "-1.3.0", "1.3.0-beta", "1.3.0.1", "9999999.1", "../1.0"] {
            rejects("invalid version") { _ = try UpdateCore.versionParts(value) }
        }
        let key = Curve25519.Signing.PrivateKey()
        let bytes = Data("trusted archive".utf8)
        let digest = SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined()
        let release = UpdateRelease(version: "1.3.0", notes: "A real update", url: "https://raw.githubusercontent.com/wxu430375-cloud/tea-diary/main/updates/TeaDiary-1.3.0-macos-arm64.zip", sha256: digest, size: Int64(bytes.count), minimumSystem: "13.0", architecture: "arm64")
        let signed = try envelope(release, key: key)
        try expect(UpdateCore.verifiedRelease(signed, publicKey: key.publicKey.rawRepresentation).version == "1.3.0", "valid signature")
        rejects("wrong trust root") { _ = try UpdateCore.verifiedRelease(signed) }
        var tampered = try JSONSerialization.jsonObject(with: signed) as! [String: String]
        tampered["payload"] = Data("tampered".utf8).base64EncodedString()
        rejects("tampered manifest") { _ = try UpdateCore.verifiedRelease(JSONSerialization.data(withJSONObject: tampered), publicKey: key.publicKey.rawRepresentation) }
        for url in ["http://raw.githubusercontent.com/wxu430375-cloud/tea-diary/main/updates/TeaDiary-1.3.0-macos-arm64.zip", "https://example.com/update.zip", release.url + "?redirect=evil", release.url.replacingOccurrences(of: "1.3.0", with: "1.4.0")] {
            let bad = UpdateRelease(version: release.version, notes: release.notes, url: url, sha256: digest, size: release.size, minimumSystem: "13.0", architecture: "arm64")
            rejects("untrusted download URL") { _ = try UpdateCore.verifiedRelease(envelope(bad, key: key), publicKey: key.publicKey.rawRepresentation) }
        }
        let fm = FileManager.default
        let root = fm.temporaryDirectory.appendingPathComponent("TeaDiary-updater-test-" + UUID().uuidString)
        try fm.createDirectory(at: root, withIntermediateDirectories: false)
        defer { try? fm.removeItem(at: root) }
        let archive = root.appendingPathComponent("update.zip"); try bytes.write(to: archive)
        try UpdateCore.verifyArchive(archive, release: release); checks += 1
        try Data("changed archive".utf8).write(to: archive)
        rejects("changed archive checksum/length") { try UpdateCore.verifyArchive(archive, release: release) }
        try Data(repeating: 65, count: bytes.count).write(to: archive)
        rejects("same-length checksum tamper") { try UpdateCore.verifyArchive(archive, release: release) }
        let source = URL(fileURLWithPath: "dist/茶茶手账.app", isDirectory: true)
        let target = root.appendingPathComponent("茶茶手账.app")
        try UpdateCore.run("/usr/bin/ditto", ["--norsrc", "--noextattr", source.path, target.path])
        try UpdateCore.run("/usr/bin/xattr", ["-cr", target.path])
        try UpdateCore.validateBundle(target, version: "1.3.0"); checks += 1
        // A stand-in for the separate journal directory: replacement must never touch it.
        let data = root.appendingPathComponent("Application Support/TeaDiary/journal.json")
        try fm.createDirectory(at: data.deletingLastPathComponent(), withIntermediateDirectories: true)
        let journal = Data("{\"photo\":\"keep this photo\",\"entries\":[1,2]}".utf8); try journal.write(to: data)
        let marker = target.appendingPathComponent("Contents/Resources/old-version-marker"); try Data("old".utf8).write(to: marker)
        // Sign this test copy again so its extra marker is part of its sealed resources.
        try UpdateCore.run("/usr/bin/codesign", ["--force", "--deep", "--sign", "-", target.path])
        let staged = try UpdateCore.prepare(source, target: target, version: "1.3.0")
        defer { try? fm.removeItem(at: staged.deletingLastPathComponent()) }
        rejects("launch failure rolls back") {
            try UpdateCore.replace(staged, target: target, version: "1.3.0") { _ in throw UpdateFailure("simulated launch failure") }
        }
        try expect(fm.fileExists(atPath: marker.path), "old application restored")
        try expect(Data(contentsOf: data) == journal, "journal preserved after rollback")
        let next = try UpdateCore.prepare(source, target: target, version: "1.3.0")
        defer { try? fm.removeItem(at: next.deletingLastPathComponent()) }
        var launched = false
        try UpdateCore.replace(next, target: target, version: "1.3.0") { _ in launched = true }
        try expect(launched && !fm.fileExists(atPath: marker.path), "replacement launches new application")
        try expect(Data(contentsOf: data) == journal, "journal preserved after success")
        let invalid = root.appendingPathComponent("broken.app"); try fm.createDirectory(at: invalid, withIntermediateDirectories: false)
        rejects("invalid app is rejected before replacement") { _ = try UpdateCore.prepare(invalid, target: target, version: "1.3.0") }
        try UpdateCore.validateBundle(target, version: "1.3.0"); checks += 1
        try expect(!fm.contentsOfDirectory(atPath: root.path).contains(where: { $0.hasPrefix(".TeaDiary-previous-") }), "no old-app copy left after success")
        if fm.fileExists(atPath: "updates/stable.json") {
            let published = try UpdateCore.verifiedRelease(Data(contentsOf: URL(fileURLWithPath: "updates/stable.json")))
            try expect(published.version == "1.3.0", "actual signed release matches packaged version")
            try UpdateCore.verifyArchive(URL(fileURLWithPath: "updates/TeaDiary-\(published.version)-macos-arm64.zip"), release: published); checks += 1
        }
        print("Updater: \(checks) checks passed (signature, version, checksum, replacement, rollback, data preservation).")
    }
}
