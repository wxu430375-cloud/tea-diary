import AppKit

private final class UpdateDownload: NSObject, URLSessionDownloadDelegate {
    let destination: URL
    let expectedSize: Int64
    let progress: (Int64, Int64) -> Void
    let completion: (Result<URL, Error>) -> Void
    var session: URLSession!
    var task: URLSessionDownloadTask?
    var result: Result<URL, Error>?
    init(url: URL, destination: URL, expectedSize: Int64, progress: @escaping (Int64, Int64) -> Void, completion: @escaping (Result<URL, Error>) -> Void) {
        self.destination = destination; self.expectedSize = expectedSize; self.progress = progress; self.completion = completion
        super.init()
        let config = URLSessionConfiguration.ephemeral; config.timeoutIntervalForRequest = 30; config.timeoutIntervalForResource = 900
        session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        task = session.downloadTask(with: url); task?.resume()
    }
    func cancel() { task?.cancel() }
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        if totalBytesWritten > expectedSize || (totalBytesExpectedToWrite > 0 && totalBytesExpectedToWrite != expectedSize) {
            result = .failure(UpdateFailure("更新包大小不正确，已停止下载。")); downloadTask.cancel()
        }
        DispatchQueue.main.async { self.progress(totalBytesWritten, self.expectedSize) }
    }
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        do {
            guard (downloadTask.response as? HTTPURLResponse)?.statusCode == 200 else { throw UpdateFailure("暂时无法下载新版，请稍后重试。") }
            try FileManager.default.moveItem(at: location, to: destination); result = .success(destination)
        } catch { result = .failure(error) }
    }
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let final = result ?? .failure(error ?? UpdateFailure("下载没有完成。"))
        DispatchQueue.main.async { self.completion(final) }
        session.finishTasksAndInvalidate()
    }
}

@MainActor final class AppUpdater: NSObject {
    weak var window: NSWindow?
    var canRestart: (@escaping (Bool) -> Void) -> Void = { $0(true) }
    private var busy = false
    private var handedOff = false
    private var workspace: URL?
    private var staged: URL?
    private var network: Task<Void, Never>?
    private var download: UpdateDownload?
    private var progressAlert: NSAlert?
    private var progressBar: NSProgressIndicator?
    private var progressLabel: NSTextField?
    private let automaticKey = "automaticallyCheckForUpdates"
    var automatic: Bool { UserDefaults.standard.bool(forKey: automaticKey) }
    func setAutomatic(_ value: Bool) { UserDefaults.standard.set(value, forKey: automaticKey) }
    func checkAutomatically() {
        guard automatic else { return }
        let last = UserDefaults.standard.double(forKey: "lastUpdateCheck")
        guard Date().timeIntervalSince1970 - last > 86400 else { return }
        check(manual: false)
    }
    private func show(_ title: String, _ text: String) {
        guard let window, window.attachedSheet == nil else { return }
        let alert = NSAlert(); alert.messageText = title; alert.informativeText = text
        alert.beginSheetModal(for: window)
    }
    private func progress(_ title: String) {
        guard let window else { return }
        let alert = NSAlert(); alert.messageText = title; alert.informativeText = "正在连接更新服务…"; alert.addButton(withTitle: "取消")
        let box = NSView(frame: NSRect(x: 0, y: 0, width: 320, height: 48))
        let label = NSTextField(labelWithString: ""); label.frame = NSRect(x: 0, y: 26, width: 320, height: 20)
        let bar = NSProgressIndicator(frame: NSRect(x: 0, y: 4, width: 320, height: 14)); bar.style = .bar; bar.isIndeterminate = true; bar.startAnimation(nil)
        box.addSubview(label); box.addSubview(bar); alert.accessoryView = box
        progressAlert = alert; progressBar = bar; progressLabel = label
        alert.beginSheetModal(for: window) { response in
            if response == .alertFirstButtonReturn { self.network?.cancel(); self.download?.cancel() }
        }
    }
    private func endProgress() {
        if let sheet = progressAlert?.window { window?.endSheet(sheet, returnCode: .stop) }
        progressAlert = nil; progressBar = nil; progressLabel = nil
    }
    func check(manual: Bool = true) {
        guard !busy, let window, window.attachedSheet == nil else { return }
        busy = true
        if manual { progress("看看有没有新的小快乐") }
        network = Task { @MainActor in
            do {
                let config = URLSessionConfiguration.ephemeral; config.timeoutIntervalForRequest = 20
                let session = URLSession(configuration: config); defer { session.invalidateAndCancel() }
                var request = URLRequest(url: UpdateCore.feed); request.cachePolicy = .reloadIgnoringLocalCacheData
                let (data, response) = try await session.data(for: request)
                try Task.checkCancellation()
                guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw UpdateFailure("暂时连不上更新服务，请检查网络后重试。") }
                let release = try UpdateCore.verifiedRelease(data)
                UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "lastUpdateCheck")
                self.endProgress(); self.busy = false
                let current = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
                guard try UpdateCore.isNewer(release.version, than: current) else {
                    if manual { self.show("已经是最新版啦 ♡", "当前版本 v\(current)。") }; return
                }
                let os = ProcessInfo.processInfo.operatingSystemVersion
                guard try !UpdateCore.isNewer(release.minimumSystem, than: "\(os.majorVersion).\(os.minorVersion).\(os.patchVersion)") else {
                    if manual { self.show("新版需要更新的 macOS", "v\(release.version) 需要 macOS \(release.minimumSystem) 或更新系统，当前版本可继续使用。") }; return
                }
                guard window.attachedSheet == nil else { return }
                let alert = NSAlert(); alert.messageText = "新的小快乐到了 · v\(release.version)"
                alert.informativeText = release.notes + "\n\n当前 v\(current) · 下载约 \(Int(ceil(Double(release.size) / 1048576))) MB\n更新后会重新打开 App，原有打卡和照片会保留。"
                alert.addButton(withTitle: "下载更新并重启"); alert.addButton(withTitle: "下次再说")
                alert.beginSheetModal(for: window) { response in
                    if response == .alertFirstButtonReturn {
                        self.canRestart { allowed in
                            if allowed { self.install(release) }
                            else { self.show("先收好正在编辑的这一杯", "请先保存或关闭当前编辑窗口，再检查更新。") }
                        }
                    }
                }
            } catch {
                self.endProgress(); self.busy = false
                if manual && !Task.isCancelled { self.show("暂时没能检查更新", error.localizedDescription) }
            }
        }
    }
    private func install(_ release: UpdateRelease) {
        guard !busy else { return }; busy = true
        let target = Bundle.main.bundleURL
        do {
            try UpdateCore.requireWritableInstallation(target)
            let folder = FileManager.default.temporaryDirectory.appendingPathComponent("TeaDiary-download-" + UUID().uuidString)
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700]); workspace = folder
            progress("正在把新版装进手账")
            network = Task { @MainActor in
                do {
                    let archive = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URL, Error>) in
                        self.download = UpdateDownload(url: URL(string: release.url)!, destination: folder.appendingPathComponent("update.zip"), expectedSize: release.size, progress: { received, total in
                            self.progressBar?.isIndeterminate = false; self.progressBar?.maxValue = Double(total); self.progressBar?.doubleValue = Double(received)
                            self.progressLabel?.stringValue = "已下载 \(received / 1048576) / \(total / 1048576) MB"
                        }, completion: { continuation.resume(with: $0) })
                    }
                    self.download = nil
                    try Task.checkCancellation()
                    self.progressAlert?.informativeText = "正在校验并准备安装…"
                    self.progressBar?.isIndeterminate = true; self.progressBar?.startAnimation(nil)
                    // Filesystem and signature checks run off the UI thread.
                    let prepared = try await Task.detached(priority: .userInitiated) {
                        try UpdateCore.verifyArchive(archive, release: release)
                        let unpacked = folder.appendingPathComponent("unpacked")
                        try FileManager.default.createDirectory(at: unpacked, withIntermediateDirectories: false)
                        try UpdateCore.run("/usr/bin/ditto", ["-x", "-k", archive.path, unpacked.path])
                        let apps = try FileManager.default.contentsOfDirectory(at: unpacked, includingPropertiesForKeys: nil)
                        guard apps.count == 1, let candidate = apps.first, candidate.pathExtension == "app" else { throw UpdateFailure("更新包目录不正确。") }
                        try UpdateCore.validateBundle(candidate, version: release.version)
                        return try UpdateCore.prepare(candidate, target: target, version: release.version)
                    }.value
                    self.staged = prepared
                    try Task.checkCancellation()
                    let helper = folder.appendingPathComponent("TeaDiaryUpdater")
                    try FileManager.default.copyItem(at: prepared.appendingPathComponent("Contents/Helpers/TeaDiaryUpdater"), to: helper)
                    let job: [String: Any] = ["parentPID": getpid(), "target": target.path, "staged": prepared.path, "version": release.version, "workspace": folder.path]
                    let jobFile = folder.appendingPathComponent("install.json")
                    try JSONSerialization.data(withJSONObject: job).write(to: jobFile, options: .atomic)
                    let installer = Process(); installer.executableURL = helper; installer.arguments = [jobFile.path]; try installer.run()
                    let ready = folder.appendingPathComponent("ready")
                    for _ in 0..<100 {
                        if FileManager.default.fileExists(atPath: ready.path) { break }
                        try await Task.sleep(nanoseconds: 100_000_000)
                    }
                    guard installer.isRunning, FileManager.default.fileExists(atPath: ready.path) else { throw UpdateFailure("更新助手未能启动，已保留当前版本。") }
                    try Task.checkCancellation()
                    self.handedOff = true
                    self.endProgress()
                    NSApplication.shared.terminate(nil)
                } catch {
                    self.endProgress(); self.cleanup(); self.busy = false
                    if !Task.isCancelled { self.show("这次更新没有完成", error.localizedDescription + "\n当前版本和手账数据已保留，可以稍后重试。") }
                }
            }
        } catch { cleanup(); busy = false; show("暂时无法安装更新", error.localizedDescription) }
    }
    func cleanup() {
        guard !handedOff else { return }
        if let staged { try? FileManager.default.removeItem(at: staged.deletingLastPathComponent()) }; staged = nil
        if let workspace { try? FileManager.default.removeItem(at: workspace) }; workspace = nil
    }
    func requestQuit() -> Bool {
        if handedOff { return true }
        if busy { network?.cancel(); download?.cancel(); return false }
        cleanup(); return true
    }
}
