import Foundation
import CryptoKit

// The private key is local-only. Never include it in source archives or installers.
let args = CommandLine.arguments
let keyURL = URL(fileURLWithPath: ".local/update-ed25519.key")
let fm = FileManager.default
if args.count == 2 && args[1] == "init" {
    guard !fm.fileExists(atPath: keyURL.path) else { fatalError("Signing key already exists; keep the existing trust root.") }
    try fm.createDirectory(at: keyURL.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
    let key = Curve25519.Signing.PrivateKey()
    try key.rawRepresentation.write(to: keyURL, options: .atomic)
    try fm.setAttributes([.posixPermissions: 0o600], ofItemAtPath: keyURL.path)
    let source = "import Foundation\nenum UpdateTrust {\n    static let publicKey = Data(base64Encoded: \"\(key.publicKey.rawRepresentation.base64EncodedString())\")!\n}\n"
    try source.write(toFile: "native/UpdateTrust.swift", atomically: true, encoding: .utf8)
    print("Created local signing key and public trust root.")
} else if args.count == 3 {
    let key = try Curve25519.Signing.PrivateKey(rawRepresentation: Data(contentsOf: keyURL))
    let trust = try String(contentsOfFile: "native/UpdateTrust.swift", encoding: .utf8)
    guard trust.contains(key.publicKey.rawRepresentation.base64EncodedString()) else { fatalError("Signing key does not match the bundled public key.") }
    let payload = try Data(contentsOf: URL(fileURLWithPath: args[1]))
    let envelope = ["payload": payload.base64EncodedString(), "signature": try key.signature(for: payload).base64EncodedString()]
    try JSONSerialization.data(withJSONObject: envelope, options: [.sortedKeys, .prettyPrinted]).write(to: URL(fileURLWithPath: args[2]), options: .atomic)
    print("Signed update manifest.")
} else { fatalError("Usage: sign-update init | sign-update payload.json stable.json") }
