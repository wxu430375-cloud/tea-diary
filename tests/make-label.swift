import AppKit
let size=NSSize(width:900,height:700)
let image=NSImage(size:size)
image.lockFocus()
NSColor.white.setFill(); NSRect(origin:.zero,size:size).fill()
let style=NSMutableParagraphStyle();style.lineSpacing=28
let attributes: [NSAttributedString.Key:Any]=[.font:NSFont.systemFont(ofSize:48,weight:.medium),.foregroundColor:NSColor.black,.paragraphStyle:style]
("1点点\n苹果茉莉绿\n大杯 三分糖 少冰\n取餐号 A086\n2026-10-20 14:30" as NSString).draw(in:NSRect(x:60,y:40,width:780,height:600),withAttributes:attributes)
image.unlockFocus()
let rep=NSBitmapImageRep(data:image.tiffRepresentation!)!
try rep.representation(using:.png,properties:[:])!.write(to:URL(fileURLWithPath:CommandLine.arguments[1]))
