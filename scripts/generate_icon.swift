import AppKit
import Foundation

let size = 1024
guard let context = CGContext(data:nil,width:size,height:size,bitsPerComponent:8,bytesPerRow:size*4,
                              space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGImageAlphaInfo.noneSkipLast.rawValue)
else { fatalError("Icon context unavailable") }
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(cgContext:context,flipped:false)
let bounds = CGRect(x:0,y:0,width:CGFloat(size),height:CGFloat(size))
NSColor(red:0.027,green:0.043,blue:0.071,alpha:1).setFill();NSBezierPath(rect:bounds).fill()
let gradient = NSGradient(starting:NSColor(red:0.11,green:0.23,blue:0.29,alpha:1),ending:NSColor(red:0.027,green:0.043,blue:0.071,alpha:1))!
gradient.draw(in:NSBezierPath(ovalIn:CGRect(x:60,y:60,width:904,height:904)),relativeCenterPosition:NSPoint(x:0.2,y:0.4))
let cyan = NSColor(red:0.55,green:0.91,blue:0.92,alpha:1)
let circle = NSBezierPath(ovalIn:CGRect(x:194,y:194,width:636,height:636));circle.lineWidth=3
cyan.withAlphaComponent(0.35).setStroke();circle.stroke()
NSGraphicsContext.saveGraphicsState()
let transform = NSAffineTransform();transform.translateX(by:512,yBy:512);transform.rotate(byDegrees:-30);transform.concat()
let orbit = NSBezierPath(ovalIn:CGRect(x:-402,y:-154,width:804,height:308));orbit.lineWidth=5
cyan.withAlphaComponent(0.9).setStroke();orbit.stroke()
NSGraphicsContext.restoreGraphicsState()
let line = NSBezierPath();line.move(to:NSPoint(x:333,y:421));line.line(to:NSPoint(x:430,y:520));line.line(to:NSPoint(x:501,y:481));line.line(to:NSPoint(x:655,y:634));line.lineWidth=17;line.lineCapStyle = .round;line.lineJoinStyle = .round
cyan.setStroke();line.stroke()
cyan.setFill();NSBezierPath(ovalIn:CGRect(x:814,y:657,width:30,height:30)).fill()
NSGraphicsContext.restoreGraphicsState()
guard let image=context.makeImage(),let png=NSBitmapImageRep(cgImage:image).representation(using:.png,properties:[:]) else {fatalError("Icon rendering failed")}
let target=URL(fileURLWithPath:"Resources/Assets.xcassets/AppIcon.appiconset",isDirectory:true)
try FileManager.default.createDirectory(at:target,withIntermediateDirectories:true)
try png.write(to:target.appendingPathComponent("AppIcon.png"))
let content = #"{"images":[{"filename":"AppIcon.png","idiom":"universal","platform":"ios","size":"1024x1024"}],"info":{"author":"xcode","version":1}}"#
try Data(content.utf8).write(to:target.appendingPathComponent("Contents.json"))
try Data(#"{"info":{"author":"xcode","version":1}}"#.utf8).write(to:target.deletingLastPathComponent().appendingPathComponent("Contents.json"))
print("Opaque 1024px AppIcon generated")
