import Foundation
import Vision
import AppKit
if CommandLine.arguments.count != 2 { fputs("Usage: tea-ocr image-path\n", stderr); exit(1) }
do {
 let url = URL(fileURLWithPath: CommandLine.arguments[1])
 let request = VNRecognizeTextRequest(); request.recognitionLevel = .accurate
 request.recognitionLanguages = ["zh-Hans", "zh-Hant", "en-US"]; request.usesLanguageCorrection = true
 try VNImageRequestHandler(url: url).perform([request])
 let text = (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
 let data = try JSONSerialization.data(withJSONObject: ["text": text]); print(String(data: data, encoding: .utf8)!)
} catch { fputs(error.localizedDescription, stderr); exit(1) }
