import AppKit

struct InstallJob: Codable {
    let parentPID: Int32
    let target: String
    let staged: String
    let version: String
    let workspace: String
}

@main enum UpdateInstaller {
    static func launch(_ url: URL) throws {
        var finished = false
        var failure: Error?
        var launched: NSRunningApplication?
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.createsNewApplicationInstance = true
        NSWorkspace.shared.openApplication(at: url, configuration: configuration) { app, error in
            launched = app; failure = error; finished = true
        }
        let deadline = Date().addingTimeInterval(20)
        while !finished && Date() < deadline { RunLoop.current.run(until: Date().addingTimeInterval(0.05)) }
        guard finished, failure == nil, let app = launched else { throw UpdateFailure("新版未能打开，已恢复原版本。") }
        let healthDeadline = Date().addingTimeInterval(2)
        while Date() < healthDeadline { RunLoop.current.run(until: Date().addingTimeInterval(0.05)) }
        guard !app.isTerminated else { throw UpdateFailure("新版启动失败，已恢复原版本。") }
    }
    static func main() {
        let fm = FileManager.default
        guard CommandLine.arguments.count == 2 else { return }
        let jobFile = URL(fileURLWithPath: CommandLine.arguments[1])
        var job: InstallJob?
        var didQuit = false
        do {
            let decoded = try JSONDecoder().decode(InstallJob.self, from: Data(contentsOf: jobFile)); job = decoded
            let target = URL(fileURLWithPath: decoded.target), staged = URL(fileURLWithPath: decoded.staged)
            guard decoded.parentPID > 1, decoded.parentPID != getpid(),
                  staged.deletingLastPathComponent().lastPathComponent.hasPrefix(".TeaDiary-update-"),
                  staged.deletingLastPathComponent().deletingLastPathComponent() == target.deletingLastPathComponent(),
                  staged.lastPathComponent == target.lastPathComponent,
                  jobFile.deletingLastPathComponent().path == decoded.workspace else { throw UpdateFailure("更新任务无效。") }
            try UpdateCore.requireWritableInstallation(target)
            try UpdateCore.validateBundle(staged, version: decoded.version)
            try Data("ready".utf8).write(to: jobFile.deletingLastPathComponent().appendingPathComponent("ready"), options: .atomic)
            let deadline = Date().addingTimeInterval(60)
            while kill(decoded.parentPID, 0) == 0 && Date() < deadline {
                if !fm.fileExists(atPath: jobFile.path) { return }
                Thread.sleep(forTimeInterval: 0.1)
            }
            guard kill(decoded.parentPID, 0) != 0 else { throw UpdateFailure("应用尚未退出，已取消更新。请稍后重试。") }
            didQuit = true
            try UpdateCore.replace(staged, target: target, version: decoded.version, launch: launch)
        } catch {
            if didQuit, let job { try? launch(URL(fileURLWithPath: job.target)) }
            NSApplication.shared.setActivationPolicy(.accessory)
            NSApplication.shared.activate(ignoringOtherApps: true)
            let alert = NSAlert(); alert.messageText = "这次更新没有完成"; alert.informativeText = error.localizedDescription + "\n你的手账和照片仍保存在原来的数据文件夹。"; alert.runModal()
        }
        if let job {
            let stage = URL(fileURLWithPath: job.staged).deletingLastPathComponent()
            if stage.lastPathComponent.hasPrefix(".TeaDiary-update-") { try? fm.removeItem(at: stage) }
            // Only remove our own random temporary workspace.
            let workspace = URL(fileURLWithPath: job.workspace)
            if workspace.lastPathComponent.hasPrefix("TeaDiary-download-") { try? fm.removeItem(at: workspace) }
        }
    }
}
