import AppKit
import WebKit
import Vision
import UniformTypeIdentifiers

@MainActor final class AppDelegate: NSObject, NSApplicationDelegate, WKScriptMessageHandler, WKUIDelegate, WKNavigationDelegate {
    var window: NSWindow!
    var web: WKWebView!
    let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("TeaDiary", isDirectory: true)
    var dataFile: URL { directory.appendingPathComponent("journal.json") }
    var storageReadable = true
    let updater = AppUpdater()
    func applicationDidFinishLaunching(_ notification: Notification) {
        let menu = NSMenu()
        let appMenuItem = NSMenuItem(); menu.addItem(appMenuItem)
        let appMenu = NSMenu(); appMenuItem.submenu = appMenu
        appMenu.addItem(withTitle: "关于茶茶手账", action: #selector(about), keyEquivalent: "")
        appMenu.addItem(withTitle: "检查更新…", action: #selector(checkForUpdates), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "显示本地数据文件夹", action: #selector(showData), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "退出茶茶手账", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        let editItem = NSMenuItem(); menu.addItem(editItem)
        let edit = NSMenu(title: "编辑"); editItem.submenu = edit
        for (title, action, key) in [("撤销", "undo:", "z"), ("剪切", "cut:", "x"), ("复制", "copy:", "c"), ("粘贴", "paste:", "v"), ("全选", "selectAll:", "a")] { edit.addItem(withTitle: title, action: Selector(action), keyEquivalent: key) }
        NSApplication.shared.mainMenu = menu
        let config = WKWebViewConfiguration()
        config.userContentController.add(self, name: "tea")
        web = WKWebView(frame: .zero, configuration: config)
        web.uiDelegate = self; web.navigationDelegate = self
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1320, height: 900), styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
        window.title = "茶茶手账 · 把快乐装进日历"
        window.minSize = NSSize(width: 780, height: 650)
        window.contentView = web; window.center(); window.makeKeyAndOrderFront(nil)
        updater.window = window
        updater.canRestart = { [weak self] completion in
            self?.web.evaluateJavaScript("!document.querySelector('#entry-form, #custom-form') && !Array.from(pending.values()).length") { value, error in
                completion(error == nil && value as? Bool == true)
            }
        }
        let resources = Bundle.main.resourceURL!.appendingPathComponent("web")
        web.loadFileURL(resources.appendingPathComponent("index.html"), allowingReadAccessTo: resources)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    @objc func about() { NSApplication.shared.orderFrontStandardAboutPanel(nil) }
    @objc func checkForUpdates() { updater.check() }
    @objc func showData() { try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true); NSWorkspace.shared.open(directory) }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply { updater.requestQuit() ? .terminateNow : .terminateCancel }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) { updater.checkAutomatically() }
    nonisolated func reply(_ id: Int, value: Any = NSNull(), error: String? = nil) {
        DispatchQueue.main.async {
            guard let data = try? JSONSerialization.data(withJSONObject: [id, value, error as Any? ?? NSNull()], options: [.fragmentsAllowed]), let json = String(data: data, encoding: .utf8) else { return }
            self.web.evaluateJavaScript("window.nativeReply(...\(json))", completionHandler: nil)
        }
    }
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.frameInfo.isMainFrame, message.frameInfo.request.url?.isFileURL == true,
              let body = message.body as? [String: Any], let id = body["id"] as? Int, let action = body["action"] as? String else { return }
        let payload = body["payload"]
        do {
            switch action {
            case "updateCheck":
                reply(id, value: true)
                DispatchQueue.main.async { self.updater.check() }
            case "updatePreferences":
                if let values = payload as? [String: Any], let enabled = values["automatic"] as? Bool { updater.setAutomatic(enabled) }
                reply(id, value: ["automatic": updater.automatic])
            case "load":
                if FileManager.default.fileExists(atPath: dataFile.path) {
                    do { let data = try Data(contentsOf: dataFile); reply(id, value: try JSONSerialization.jsonObject(with: data)) }
                    catch { storageReadable = false; reply(id, error: "无法读取记录，原文件已保留。请在应用菜单中打开数据文件夹检查 journal.json。") }
                } else { reply(id) }
            case "save":
                guard storageReadable, let object = payload as? [String: Any], object["schema"] as? Int == 1 else { reply(id, error: "数据文件未能安全读取，已停止写入以保护原记录。"); return }
                let data = try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                if FileManager.default.fileExists(atPath: dataFile.path) {
                    let backup = directory.appendingPathComponent("journal.previous.json")
                    let previous = try Data(contentsOf: dataFile)
                    try previous.write(to: backup, options: .atomic)
                }
                try data.write(to: dataFile, options: .atomic)
                reply(id, value: true)
            case "ocr":
                guard let image = payload as? String, image.count < 20_000_000, let base64 = image.split(separator: ",", maxSplits: 1).last, let data = Data(base64Encoded: String(base64)), let nsImage = NSImage(data: data), let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else { reply(id, error: "无法读取图片"); return }
                DispatchQueue.global(qos: .userInitiated).async {
                    do {
                        let request = VNRecognizeTextRequest(); request.recognitionLevel = .accurate
                        request.recognitionLanguages = ["zh-Hans", "zh-Hant", "en-US"]; request.usesLanguageCorrection = true
                        try VNImageRequestHandler(cgImage: cgImage).perform([request])
                        let observations = request.results ?? []
                        let text = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
                        self.reply(id, value: ["text": text])
                    } catch { self.reply(id, error: "识别失败：\(error.localizedDescription)") }
                }
            case "export":
                guard let value = payload as? [String: String], var content = value["content"], let name = value["name"] else { reply(id, error: "导出内容无效"); return }
                if value["type"] == "image/svg+xml" {
                    let pattern = "href=\"(assets/[a-zA-Z0-9-]+\\.(png|svg))\""
                    let regex = try NSRegularExpression(pattern: pattern)
                    let original = content as NSString
                    for match in regex.matches(in: content, range: NSRange(location: 0, length: original.length)).reversed() {
                        let asset = original.substring(with: match.range(at: 1))
                        let url = Bundle.main.resourceURL!.appendingPathComponent("web/" + asset)
                        let bytes = try Data(contentsOf: url)
                        let type = asset.hasSuffix("svg") ? "image/svg+xml" : "image/png"
                        let replacement = "href=\"data:\(type);base64,\(bytes.base64EncodedString())\""
                        content = (content as NSString).replacingCharacters(in: match.range, with: replacement)
                    }
                }
                let exportContent = content
                let panel = NSSavePanel(); panel.nameFieldStringValue = name; panel.canCreateDirectories = true
                panel.beginSheetModal(for: window) { response in
                    guard response == .OK, let url = panel.url else { self.reply(id, value: false); return }
                    do { try exportContent.write(to: url, atomically: true, encoding: .utf8); self.reply(id, value: true) }
                    catch { self.reply(id, error: error.localizedDescription) }
                }
            default: reply(id, error: "不支持的操作")
            }
        } catch { reply(id, error: error.localizedDescription) }
    }
    func webView(_ webView: WKWebView, runOpenPanelWith parameters: WKOpenPanelParameters, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping ([URL]?) -> Void) {
        let panel = NSOpenPanel(); panel.allowsMultipleSelection = false; panel.canChooseDirectories = false
        panel.beginSheetModal(for: window) { response in completionHandler(response == .OK ? panel.urls : nil) }
    }
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url, !url.isFileURL && url.scheme != "about" {
            if url.scheme == "https" { NSWorkspace.shared.open(url) }
            decisionHandler(.cancel)
        } else { decisionHandler(.allow) }
    }
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let url = navigationAction.request.url, url.scheme == "https" { NSWorkspace.shared.open(url) }; return nil
    }
}
@main enum TeaDiaryMain {
    @MainActor static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.setActivationPolicy(.regular)
        app.delegate = delegate
        app.run()
    }
}
